import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../theme/app_colors.dart';


class SettingsTile extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String description;
  final VoidCallback action;
  final Color backgroundColor;

  const SettingsTile({super.key, this.leadingIcon, required this.title, required this.description,required this.action,this.backgroundColor = Colors.transparent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: InkWell(
          onTap: action,
          child: Row(
            children: [
              Padding(
                padding: leadingIcon == null ? EdgeInsets.zero : const EdgeInsets.all(12.0),
                child: Icon(
                  leadingIcon,
                  color: AppColors.white,
                  size: 25,
                ),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(
                      height: AppUiConstants.verticalSpacingButtons,
                    ),
                    Text(
                      description,
                      textAlign: TextAlign.left,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 14,
                          color: Colors.white
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}