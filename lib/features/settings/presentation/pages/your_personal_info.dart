import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/services/user_service.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/core/utils/extensions.dart';


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

  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final currentUser = AppData.instance.currentUser;
    if (currentUser != null) {
      _firstNameController.text = currentUser.firstName;
      _lastNameController.text = currentUser.lastName;

      if (currentUser.dateOfBirth != null) {
        _birthDateController.text = AppUtils.formatDateTime(currentUser.dateOfBirth, onlyDate: true);
      }

      _selectedGender = currentUser.gender?.capitalize();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    await AppUtils.pickDate(
      context,
      DateTime(1900),
      DateTime.now(),
      _birthDateController,
      true,
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        AppUtils.showMessage(context, "Please select a gender.", messageType: MessageType.error);
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try{
        final newBirthDate =DateTime.tryParse('${_birthDateController.text.trim()} 00:00:00');
        final Map<String, dynamic> fieldsToUpdate = {
          'firstName': _firstNameController.text.trim().toLowerCase().capitalize(),
          'lastName': _lastNameController.text.trim().toLowerCase().capitalize(),
          'dateOfBirth': newBirthDate,
          'gender': _selectedGender!.toLowerCase(),
        };

        final success = await UserService.updateFieldsInTransaction(
          AppData.instance.currentUser?.uid ?? '',
          fieldsToUpdate,
        );
        setState(() {
          _isLoading = false;
        });

        if (success) {
          AppData.instance.currentUser?.firstName = fieldsToUpdate['firstName'];
          AppData.instance.currentUser?.lastName = fieldsToUpdate['lastName'];
          AppData.instance.currentUser?.dateOfBirth = fieldsToUpdate['dateOfBirth'];
          AppData.instance.currentUser?.gender = fieldsToUpdate['gender'];
          if(!mounted) return;
          AppUtils.showMessage(context, "Profile updated successfully.", messageType: MessageType.success);
          Navigator.of(context).pop();
        } else {
          if(!mounted) return;
          AppUtils.showMessage(context, "Failed to update profile. Check your connection.", messageType: MessageType.error);
        }
      }catch (e){
        AppUtils.showMessage(context, "Failed to update profile. ", messageType: MessageType.error);
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
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your date of birth.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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