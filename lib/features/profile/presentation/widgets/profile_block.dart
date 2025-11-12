import 'package:flutter/material.dart';

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
                  "assets/DefaultProfilePhoto.png",),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user?.firstName ?? "Unknown"} ${user?.lastName ?? ""}",
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
