import 'package:flutter/material.dart';


import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';

import '../../../../core/enums/visibility.dart' as enums;
import '../../../../core/models/competition.dart';
import '../../../../core/widgets/section.dart';

class BasicInfoSection extends StatefulWidget {
  final bool readOnly;
  final enums.ComVisibility visibility;
  final Competition competition;
  final TextEditingController organizerController;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final void Function(enums.ComVisibility) setVisibility;

  const BasicInfoSection({
    super.key,
    required this.readOnly,
    required this.visibility,
    required this.competition,
    required this.organizerController,
    required this.nameController,
    required this.descriptionController,
    required this.setVisibility,
  });

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  late enums.ComVisibility _visibility;

  @override
  void initState() {
    super.initState();
    _visibility = widget.visibility;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a name';
    }
    if (value.trim().length < 5) {
      return 'Name must be at least 5 characters';
    }
    return null;
  }

  // Description
  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a description';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: "Basic info",
      children: [
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),
        // Organizer
        TextFormField(
          controller: widget.organizerController,
          textAlign: TextAlign.left,
          readOnly: true,
          enabled: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(20),
            border: AppUiConstants.borderTextFields,
            label: Text("Organizer"),
            labelStyle: AppUiConstants.labelStyleTextFields,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: (AppData.instance.currentUser?.profilePhotoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(AppData.instance.currentUser!.profilePhotoUrl!)
                    : AssetImage(AppImages.defaultProfilePhoto),
              ),
            ),
          ),
        ),

        // Name of competition
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),
        TextFormField(
          controller: widget.nameController,
          style: AppUiConstants.textStyleTextFields,
          readOnly: widget.readOnly,
          decoration: InputDecoration(label: Text("Name of competition"), hintText: "Name of competition"),
          validator: validateName,
        ),
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),
        // Description
        TextFormField(
          readOnly: widget.readOnly,
          maxLines: 3,
          controller: widget.descriptionController,
          decoration: InputDecoration(
            hintText: "Describe your competition",
            hintStyle: TextStyle(color: AppColors.textFieldsHints),
            border: AppUiConstants.borderTextFields,
            label: Text("Description"),
          ),
          style: TextStyle(color: Colors.white),
          validator: validateDescription,
        ),
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),
        DropdownMenu(
          initialSelection: widget.visibility,
          enabled: !widget.readOnly,
          maxLines: 1,
          textAlign: TextAlign.left,
          label: Text("Visibility"),
          width: double.infinity,
          onSelected: (enums.ComVisibility? visibility) {
            // Selecting visibility
            setState(() {
              if (visibility != null) {
                _visibility = visibility;
                widget.setVisibility(
                  visibility
                );
              }
            });
          },
          trailingIcon: Icon(color: Colors.white, Icons.arrow_drop_down),
          selectedTrailingIcon: Icon(color: Colors.white, Icons.arrow_drop_up),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.6)),
            alignment: Alignment.center,
          ),
          dropdownMenuEntries: <DropdownMenuEntry<enums.ComVisibility>>[
            DropdownMenuEntry(
              value: enums.ComVisibility.me,
              label: "Only Me",
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
            DropdownMenuEntry(
              value: enums.ComVisibility.friends,
              label: "Friends",
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
            DropdownMenuEntry(
              value: enums.ComVisibility.everyone,
              label: "Everyone",
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
