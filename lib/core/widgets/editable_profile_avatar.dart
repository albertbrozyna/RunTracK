import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_track/app/theme/app_colors.dart';

class EditableProfileAvatar extends StatefulWidget {
  final double radius;
  final String? currentPhotoUrl;
  final Function(File pickedFile)? onImagePicked;

  const EditableProfileAvatar({
    super.key,
    this.radius = 80,
    this.currentPhotoUrl,
    this.onImagePicked,
  });

  @override
  State<EditableProfileAvatar> createState() => _EditableProfileAvatarState();
}

class _EditableProfileAvatarState extends State<EditableProfileAvatar> {
  File? _localImageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _localImageFile = file;
      });
      widget.onImagePicked!(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    // Local file
    if (_localImageFile != null) {
      imageProvider = FileImage(_localImageFile!);
    }
    // Photo from internet
    else if (widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.currentPhotoUrl!);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, size: widget.radius, color: AppColors.white)
                  : null,
            ),
          ),
          if(widget.onImagePicked != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 35,
                  width: 35,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}