import 'package:flutter/material.dart';
import 'package:vrooom/core/configs/theme/app_spacing.dart';
import 'package:vrooom/presentation/admin/admin_settings/widgets/settings_section.dart';
import 'package:vrooom/presentation/admin/admin_settings/widgets/settings_tile.dart';
import 'package:vrooom/presentation/admin/widgets/admin_app_bar.dart';
import 'package:vrooom/presentation/admin/widgets/admin_drawer.dart';

import '../../../../../../core/common/widgets/app_svg.dart';
import '../../../../../../core/configs/assets/app_vectors.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final ScrollController _scrollController = ScrollController();
  List<SettingsTile> accountInformation = [
    const SettingsTile(
      title: "Admin Name",
      description: "Your full name as registered in the system",
      leadingIcon: AppSvg(asset: AppVectors.person),
    ),
    const SettingsTile(
      title: "Change password",
      description: "Update your account password regularly for security reasons",
      leadingIcon: AppSvg(asset: AppVectors.key),
    ),
  ];

  List<SettingsTile> generalPreferences = [
    const SettingsTile(
      title: "Settings",
      description: "Settings description",
      leadingIcon: AppSvg(asset: AppVectors.person),
    ),
    const SettingsTile(
      title: "Settings",
      description: "Settings description",
      leadingIcon: AppSvg(asset: AppVectors.person),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: "Admin Settings"),
      drawer: const AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSection(
                    sectionTitle: "Account Information",
                    sectionDescription: "Manage your administrator profile details.",
                    settings: accountInformation),
                const SizedBox(
                  height: AppSpacing.md,
                ),
                SettingsSection(
                    sectionTitle: "General preferences",
                    sectionDescription: "Adjust basic application settings and display option",
                    settings: generalPreferences)
              ],
            ),
          ),
        ),
      ),
    );
  }
}