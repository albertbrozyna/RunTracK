
import 'package:flutter/material.dart';
import 'package:run_track/features/settings/widgets/settings_tile.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../theme/app_colors.dart';


class SettingsSection extends StatefulWidget {
  final String sectionTitle;
  final String sectionDescription;
  final List<SettingsTile> settings;

  const SettingsSection(
      {super.key,
        required this.sectionTitle,
        required this.sectionDescription,
        required this.settings});

  @override
  State<StatefulWidget> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              widget.sectionTitle,
              textAlign: TextAlign.center,
              style:
              const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: AppUiConstants.horizontalSpacingTextFields,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.sectionDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            ...widget.settings.map(
                  (tile) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: tile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
