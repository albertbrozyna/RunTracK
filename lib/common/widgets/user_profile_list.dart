import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/theme/ui_constants.dart';

class UserProfileTile extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String profilePhotoUrl;
  final double radiusOfAvatar;
  final double fontSize;
  final int height;
  BoxBorder? containerBorder;
  UserProfileTile({
    super.key,
    required this.firstName,
    required this.lastName,
    this.profilePhotoUrl = "",
    this.radiusOfAvatar = 18,
    this.fontSize = 16,
    this.height = 50,
    this.containerBorder
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(color: Colors.transparent,
          border: containerBorder ?? Border.all(color: Colors.white, width: 1,),
          borderRadius: AppUiConstants.borderRadiusTextFields
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile photo
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: CircleAvatar(
                  radius: radiusOfAvatar,
                  backgroundImage: profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : AssetImage('assets/DefaultProfilePhoto.png') as ImageProvider,
                ),
              ),
              SizedBox(width: 10),
              // First name and date
              Text(
                "${firstName.capitalize()} ${lastName.capitalize()}",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
