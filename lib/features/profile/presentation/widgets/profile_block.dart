import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_images.dart';

import '../../../../core/models/user.dart';

class ProfileBlock extends StatelessWidget {
  final User? user;
  const ProfileBlock({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              ClipOval(
                child: Image.asset(
                 AppImages.defaultProfilePhoto,),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user?.firstName ?? "User"} ${user?.lastName ?? "Unknown"}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
