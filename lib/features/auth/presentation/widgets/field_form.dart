import 'package:flutter/cupertino.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';

class FieldFormContainer extends StatelessWidget {
  final Widget child;

  const FieldFormContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textFieldsBackground,
        borderRadius: AppUiConstants.borderRadiusForm,
        boxShadow: AppUiConstants.boxShadowForm,
      ),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }
}
