import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_track/theme/ui_constants.dart';

class AddPhotos extends StatefulWidget {
  final bool showSelectedPhots;
  final Function(List<XFile>)? onImagesSelected;

  _AddPhotosState createState() => _AddPhotosState();

  const AddPhotos({
    Key? key,
    required this.showSelectedPhots,
    required this.onImagesSelected,
  }) : super(key: key);
}

class _AddPhotosState extends State<AddPhotos> {
  final ImagePicker _picker = new ImagePicker();
  List<XFile> _images = [];

  Future<void> pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();

    if (selectedImages != null && selectedImages.isNotEmpty) {
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
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: pickImages,
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF833AB4), // Purple
                    Color(0xFFF77737), // Orange
                    Color(0xFFE1306C), // Pink
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
        if (widget.showSelectedPhots && _images.isNotEmpty)
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
