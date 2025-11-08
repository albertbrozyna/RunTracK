import 'package:flutter/cupertino.dart';
import 'package:run_track/theme/app_colors.dart';

class NoItemsMsg extends StatelessWidget {
  final String textMessage;

  const NoItemsMsg({super.key, required this.textMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        textMessage,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textPrimaryColor, fontSize: 16.0),
      ),
    );
  }
}
