import 'package:flutter/material.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/core/widgets/alert_dialog.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
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
  List<SettingsTile> accountInformation = [];


  @override
  void initState() {
    super.initState();

    accountInformation = [
      SettingsTile(
        title: "You personal info",
        description: "Update your basic account information",
        leadingIcon: Icons.person,
        action: handleYourPersonalInfo,
      ),
      SettingsTile(
        title: "Change password",
        description: "Update your account password regularly for security reasons",
        leadingIcon: Icons.password,
        action: handleChangePassword,
      ),
    ];

    locationAndTracking = [
      SettingsTile(title: "Location and tracking settings", description: "Manage your location and tracking settings.", leadingIcon: Icons.gps_fixed,action: (){},)
    ];
  }

  void handleChangePassword(){
    Navigator.of(context).pushNamed("/changePassword");
  }

  void handleYourPersonalInfo(){
    Navigator.of(context).pushNamed("/yourPersonalInfo");
  }


  List<SettingsTile> locationAndTracking = [];

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
  void deleteAccountButtonPressed(BuildContext context) async {
    final deleteConfirmDialog = AppAlertDialog(
      titleText: "Confirm Delete",
      contentText: "Are you sure you want to delete your account? This action cannot be undone.",
      onPressedLeft: () {
        Navigator.of(context).pop();
      },
      onPressedRight: () async {
        final response = await AuthService.instance.deleteUserAccount();
        if (response.message == 'Account deleted successfully') {
          if (!mounted) return;
          AppUtils.showMessage(
            context,
            "User account deleted successfully",
            messageType: MessageType.info,
          );
        }
      },
      textLeft: "Cancel",
      textRight: "Delete my account",
      colorBackgroundButtonRight: AppColors.danger,
      colorButtonForegroundRight: AppColors.white,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return deleteConfirmDialog;
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
                sectionTitle: "Location And Tracking",
                sectionDescription: "Manage your location and tracking settings.",
                settings: locationAndTracking,
              ),
              const SizedBox(height: AppUiConstants.verticalSpacingButtons),
              SettingsSection(
                sectionTitle: "Danger Zone",
                sectionDescription: "",
                settings: dangerZone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
