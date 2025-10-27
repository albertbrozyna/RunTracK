import 'package:flutter/cupertino.dart';
import 'package:vrooom/core/configs/theme/app_spacing.dart';

import '../../../../core/common/widgets/app_svg.dart';

class SettingsTile extends StatelessWidget {
  final AppSvg? leadingIcon;
  final String title;
  final String description;

  const SettingsTile({super.key, this.leadingIcon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          Padding(
            padding: leadingIcon == null ? EdgeInsets.zero : const EdgeInsets.all(12.0),
            child: leadingIcon,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: AppSpacing.xs,
                ),
                Text(
                  description,
                  textAlign: TextAlign.left,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}