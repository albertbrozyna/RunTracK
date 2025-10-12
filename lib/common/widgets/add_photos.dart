import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_track/theme/ui_constants.dart';

class AddPhotos extends StatefulWidget {
  final bool showSelectedPhotos;
  final Function(List<XFile>)? onImagesSelected;
  final bool active;
  final bool onlyShow;  // Only show photos
  @override
  _AddPhotosState createState() => _AddPhotosState();

  const AddPhotos({
    super.key,
    required this.showSelectedPhotos,
    required this.onImagesSelected,
    required this.onlyShow,
    this.active = true,
  });
}

class _AddPhotosState extends State<AddPhotos> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  Future<void> pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();

    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
      // Notify parent widget
      widget.onImagesSelected?.call(_images);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(widget.onlyShow) // If only show hide add photos button
          SizedBox(
            width: double.infinity,
            height: 50,
            // Add photos button
            child: ElevatedButton(
              onPressed: widget.active ? pickImages : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.borderRadiusButtons,
                  ),
                ),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.active ? Color(0xFF833AB4) : Colors.grey,
                      widget.active ? Color(0xFFF77737) : Colors.grey,
                      widget.active ? Color(0xFFE1306C) : Colors.grey,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "Add Photos",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.showSelectedPhotos && _images.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _images.map((img) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(img.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
