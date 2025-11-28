import 'package:flutter/material.dart';
import 'package:run_track/core/models/user.dart';
import 'package:run_track/core/utils/extensions.dart';
import 'package:run_track/core/widgets/editable_profile_avatar.dart';

import '../../app/config/app_data.dart';
import '../../app/config/app_images.dart';
import '../../app/theme/ui_constants.dart';

class UserProfileTile extends StatelessWidget {
  final User user;
  final double radiusOfAvatar;
  final double fontSize;
  final int height;
  final BoxBorder? containerBorder;

  const UserProfileTile({
    super.key,
    required this.user,
    this.radiusOfAvatar = 18,
    this.fontSize = 16,
    this.height = 50,
    this.containerBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: containerBorder ?? Border.all(color: Colors.white, width: 1),
        borderRadius: AppUiConstants.borderRadiusTextFields,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (user.uid == AppData.instance.currentUser?.uid)
                  Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(Icons.star, color: Colors.amber[700], size: 30),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(Icons.person, color: Colors.transparent, size: 30),
                  ),
                SizedBox(width: 10),
                // Profile photo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                  child:EditableProfileAvatar(
                    radius: radiusOfAvatar,currentPhotoUrl: user.profilePhotoUrl ?? '',
                  )
                ),
                SizedBox(width: 10),
                // First name and date
                Text(
                  "${user.firstName.capitalize()} ${user.lastName.capitalize()}",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
