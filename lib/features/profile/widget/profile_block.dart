import 'package:flutter/material.dart';
import 'package:run_track/models/user.dart' as model;

class ProfileBlock extends StatelessWidget {
  final model.User? user;
  const ProfileBlock({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              ClipOval(
                child: user != null && user!.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                    ? Image.network(
                  user!.profilePhotoUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  "assets/DefaultProfilePhoto.png",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user?.firstName ?? "Unknown"} ${user?.lastName ?? ""}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("Friends: ${user?.friendsUids?.length ?? 0}"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
