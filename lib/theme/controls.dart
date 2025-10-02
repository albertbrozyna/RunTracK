import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final Color? fillColor;
  final bool filled;
  final int maxLines;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.labelText = "",
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.labelStyle,
    this.fillColor,
    this.filled = true,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: textAlign,
      style: textStyle ??
          TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w200,
            letterSpacing: 1,
          ),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: labelStyle ?? TextStyle(color: Colors.white),
        filled: filled,
        fillColor: fillColor ?? Colors.black.withOpacity(1),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
