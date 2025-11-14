import 'package:flutter/material.dart';

class ListInfoTile extends StatelessWidget {
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final double suffixIconsSize;
  final String title;
  final bool endDivider;

  const ListInfoTile({
    super.key,
    required this.prefixIcon,
    required this.title,
    this.endDivider = true,
    this.suffixIcon,
    this.suffixIconsSize = 26
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(prefixIcon, color: Colors.white, size: 26),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              if (suffixIcon != null)
                Icon(suffixIcon, color: Colors.white, size: suffixIconsSize)
              else
                Icon(prefixIcon, color: Colors.transparent, size: 26),
            ],
          ),
        ),
        if (endDivider) Divider(color: Colors.white60, thickness: 1, height: 1),
      ],
    );
  }
}
