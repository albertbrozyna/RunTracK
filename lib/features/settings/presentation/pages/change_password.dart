import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/core/services/user_service.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../../../app/config/app_images.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/field_form.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _isCurrentPasswordHidden = true;
  bool _isNewPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  bool _hasPasswordProvider = false;

  @override
  void initState() {
    super.initState();
    _checkAuthProvider();
  }

  void _checkAuthProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _hasPasswordProvider = user.providerData.any((userInfo) => userInfo.providerId == 'password');
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      final resultMessage = await UserService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (resultMessage == "Password successfully changed.") {
        AppUtils.showMessage(context, resultMessage, messageType: MessageType.success);

        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        Navigator.of(context).pop();
      } else {
        AppUtils.showMessage(context, resultMessage, messageType: MessageType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: PageContainer(
        darken: false,
        assetPath: AppImages.appBg4,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: AppUiConstants.paddingOutsideForm,
              child: FieldFormContainer(
                child: _hasPasswordProvider
                    ? _buildPasswordForm()
                    : _buildSocialLoginInfo(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 60, color: Colors.white70),
        const SizedBox(height: 20),
        const Text(
          "Account Managed Externally",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "You are logged in via a social provider (e.g., Google). You cannot change your password here as your account is managed by that provider.",
          style: TextStyle(fontSize: 16, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        CustomButton(
          text: "Go Back",
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _isCurrentPasswordHidden,
            style: AppUiConstants.textStyleTextFields,
            decoration: InputDecoration(
              labelText: 'Current Password',
              hintText: "Enter current password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isCurrentPasswordHidden = !_isCurrentPasswordHidden;
                  });
                },
                icon: Icon(_isCurrentPasswordHidden
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your current password';
              }
              return null;
            },
          ),
          SizedBox(height: AppUiConstants.verticalSpacingTextFields),

          TextFormField(
            controller: _newPasswordController,
            obscureText: _isNewPasswordHidden,
            style: AppUiConstants.textStyleTextFields,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: "Enter new password",
              prefixIcon: const Icon(Icons.vpn_key),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isNewPasswordHidden = !_isNewPasswordHidden;
                  });
                },
                icon: Icon(_isNewPasswordHidden
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
            ),
            validator: (value) => AuthService.instance.validateFields('password', value),
          ),
          SizedBox(height: AppUiConstants.verticalSpacingTextFields),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmPasswordHidden,
            style: AppUiConstants.textStyleTextFields,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              hintText: "Repeat new password",
              prefixIcon: const Icon(Icons.check_circle_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                  });
                },
                icon: Icon(_isConfirmPasswordHidden ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) => AuthService.instance.validateFields('repeatPassword', value,passwordController: _newPasswordController),
          ),
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white),)
              : CustomButton(
            text: 'Change Password',
            onPressed: _changePassword,
          ),
        ],
      ),
    );
  }
}