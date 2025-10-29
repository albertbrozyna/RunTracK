import 'package:flutter/cupertino.dart';

import '../../theme/colors.dart';
import '../../theme/ui_constants.dart';

class FormContainer extends StatelessWidget {
  final Widget? child;

  const FormContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textFieldsBackground,
        borderRadius: AppUiConstants.borderRadiusForm,
        boxShadow: AppUiConstants.boxShadowForm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
