import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/constants/firestore_data_collections.dart';
import 'package:run_track/core/services/user_service.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/editable_profile_avatar.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/core/utils/extensions.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

class YourPersonalInfoPage extends StatefulWidget {
  const YourPersonalInfoPage({super.key});

  @override
  State<YourPersonalInfoPage> createState() => _YourPersonalInfoPageState();
}

class _YourPersonalInfoPageState extends State<YourPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;

  File? _pickedImageFile;
  String? _currentProfilePhotoUrl;

  Future<String?> _uploadProfilePicture(String uid, File image) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${uid}_$timestamp.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child(FirestoreDataCollections.profilePhotos)
          .child(fileName);

      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    AuthService.instance.checkAppUseState(context);
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final currentUser = AppData.instance.currentUser;
    _firstNameController.text = currentUser?.firstName ?? '';
    _lastNameController.text = currentUser?.lastName ?? '';

    if (currentUser?.dateOfBirth != null) {
      _birthDateController.text = AppUtils.formatDateTime(
        currentUser?.dateOfBirth,
        onlyDate: true,
      );
    }
    _selectedGender = currentUser?.gender?.capitalize();
    _weightController.text = currentUser?.weight?.toString() ?? '';
    _heightController.text = currentUser?.height?.toString() ?? '';

    setState(() {
      _currentProfilePhotoUrl = currentUser?.profilePhotoUrl;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        AppUtils.showMessage(
          context,
          "Please select a gender.",
          messageType: MessageType.error,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try {
        final myUid = AppData.instance.currentUser?.uid ?? '';
        String? newPhotoUrl;

        if (_pickedImageFile != null && myUid.isNotEmpty) {
          newPhotoUrl = await _uploadProfilePicture(myUid, _pickedImageFile!);
          if (newPhotoUrl == null) {
            if (!mounted) return;
            AppUtils.showMessage(context, "Failed to upload image.", messageType: MessageType.error);
            setState(() => _isLoading = false);
            return;
          }
        }

        final newBirthDate = DateTime.tryParse(
          '${_birthDateController.text.trim()} 00:00:00',
        );
        final Map<String, dynamic> fieldsToUpdate = {
          'firstName': _firstNameController.text.trim().toLowerCase().capitalize(),
          'lastName': _lastNameController.text.trim().toLowerCase().capitalize(),
          'dateOfBirth': newBirthDate,
          'gender': _selectedGender!.toLowerCase(),
          'weight': double.tryParse(_weightController.text.trim()),
          'height': int.tryParse(_heightController.text.trim()),
        };

        if (newPhotoUrl != null) {
          fieldsToUpdate['profilePhotoUrl'] = newPhotoUrl;
        }

        final success = await UserService.updateFieldsInTransaction(
          AppData.instance.currentUser?.uid ?? '',
          fieldsToUpdate,
        );
        setState(() {
          _isLoading = false;
        });

        if (success) {
          final user = AppData.instance.currentUser;
          user?.firstName = fieldsToUpdate['firstName'];
          user?.lastName = fieldsToUpdate['lastName'];
          user?.dateOfBirth = fieldsToUpdate['dateOfBirth'];
          user?.gender = fieldsToUpdate['gender'];
          user?.weight = fieldsToUpdate['weight'];
          user?.height = fieldsToUpdate['height'];
          if (newPhotoUrl != null) {
            user?.profilePhotoUrl = newPhotoUrl;
          }

          if (!mounted) return;
          AppUtils.showMessage(
            context,
            "Profile updated successfully.",
            messageType: MessageType.success,
          );
          Navigator.of(context).pop();
        } else {
          if (!mounted) return;
          AppUtils.showMessage(
            context,
            "Failed to update profile. Check your connection.",
            messageType: MessageType.error,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        AppUtils.showMessage(
          context,
          "Failed to update profile. ",
          messageType: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Personal Info")),
      body: PageContainer(
        assetPath: AppImages.appBg5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                EditableProfileAvatar(
                  radius: 80,
                  currentPhotoUrl: _currentProfilePhotoUrl,
                  onImagePicked: (File file) {
                    setState(() {
                      _pickedImageFile = file;
                    });
                  },
                ),

                const SizedBox(height: 30),
                TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: AppColors.white),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => AuthService.instance.validateFields('firstName', value),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                TextFormField(
                  controller: _lastNameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => AuthService.instance.validateFields('lastName', value),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                TextFormField(
                  controller: _birthDateController,
                  style: const TextStyle(color: AppColors.white),
                  readOnly: true,
                  onTap: () async {
                    await AppUtils.pickDate(
                      context,
                      DateTime(1900),
                      DateTime.now(),
                      _birthDateController,
                      true,
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: AppColors.white),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) => AuthService.instance.validateFields('dateOfBirth', value),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                DropdownButtonFormField<String>(
                  dropdownColor: AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline),
                    suffixIconColor: AppColors.white,
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.white),
                  initialValue: _selectedGender,
                  items: AppConstants.genders.map((String genderLabel) {
                    return DropdownMenuItem<String>(
                      value: genderLabel,
                      child: Text(genderLabel),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  validator: (value) => AuthService.instance.validateFields('gender', value),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                TextFormField(
                  controller: _weightController,
                  validator: (value) => AuthService.instance.validateFields('weight', value),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: "Weight",
                    hintText: "Weight in kg",
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                TextFormField(
                  controller: _heightController,
                  validator: (value) => AuthService.instance.validateFields('height', value),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: "Height",
                    hintText: "Height in cm",
                    prefixIcon: Icon(Icons.height, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingButtons),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}