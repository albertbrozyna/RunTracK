import 'package:flutter/material.dart';

import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/page_container.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  List<SettingsTile> accountInformation = [
    SettingsTile(
      title: "You personal info",
      description: "Update your basic account information",
      leadingIcon: Icons.person,
      action: () {},
    ),
    SettingsTile(
      title: "Change password",
      description: "Update your account password regularly for security reasons",
      leadingIcon: Icons.password,
      action: () {},
    ),
  ];

  List<SettingsTile> generalPreferences = [
    SettingsTile(title: "Settings", description: "Settings description", leadingIcon: Icons.password, action: () {}),
    SettingsTile(title: "Settings", description: "Settings description", leadingIcon: Icons.password, action: () {}),
  ];

  late List<SettingsTile> dangerZone = [
    SettingsTile(
      backgroundColor: AppColors.danger,
      leadingIcon: Icons.delete_forever,
      title: "Delete my account",
      description: "Permanently remove all your data from the app",
      action: () => deleteAccountButtonPressed(context),
    ),
  ];

  /// Delete account action
  void deleteAccountButtonPressed(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.alertDialogColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
          title: const Text("Confirm Delete", textAlign: TextAlign.center),
          content: const Text("Are you sure you want to delete your account? This action cannot be undone.", textAlign: TextAlign.center),
          alignment: Alignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.gray,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel",textAlign: TextAlign.center,),
                  ),
                ),
                SizedBox(width: AppUiConstants.horizontalSpacingButtons),
                // Delete button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop(); // close dialog
                      if (await UserService.deleteUserFromFirestore()) {
                        if (mounted) {
                          AppUtils.showMessage(context, "User account deleted successfully", messageType: MessageType.info);
                        }
                      }
                      UserService.signOutUser();
                    },
                    child: const Text("Delete my account",textAlign: TextAlign.center,),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: PageContainer(
        assetPath: AppImages.appBg5,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppUiConstants.verticalSpacingButtons),
              SettingsSection(
                sectionTitle: "Account Information",
                sectionDescription: "Manage your administrator profile details.",
                settings: accountInformation,
              ),
              const SizedBox(height: AppUiConstants.verticalSpacingButtons),
              SettingsSection(
                sectionTitle: "General preferences",
                sectionDescription: "Adjust basic application settings and display option",
                settings: generalPreferences,
              ),
              const SizedBox(height: AppUiConstants.verticalSpacingButtons),
              SettingsSection(sectionTitle: "Danger zone", sectionDescription: "", settings: dangerZone),
            ],
          ),
        ),
      ),
    );
  }
}
