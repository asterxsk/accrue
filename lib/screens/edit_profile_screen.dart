import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../widgets/ui.dart';

/// The full profile page: name, bio and photo, saved in one go.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _photo;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store.profileName)
      ..addListener(_rebuild);
    _bio = TextEditingController(text: widget.store.profileBio);
    _photo = widget.store.profilePhoto;
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the photo picker')),
        );
    }
  }

  void _removePhoto() {
    setState(() => _photo = '');
  }

  void _save() {
    widget.store.setProfile(
      name: _name.text,
      bio: _bio.text,
      photo: _photo,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gutter = Metrics.gutter;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Padding(
        padding: EdgeInsets.only(top: Metrics.topInset(context)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: HeadBar(
                onBack: () => Navigator.of(context).maybePop(),
                center: 'Edit profile',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(gutter, 2, gutter, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Avatar(
                        name: _name.text.trim(),
                        photo: _photo,
                        size: 96,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          IntrinsicWidth(
                            child: AppButton(
                              label: 'Change photo',
                              tone: AppButtonTone.secondary,
                              height: 40,
                              onPressed: _pickPhoto,
                            ),
                          ),
                          if (_photo.isNotEmpty)
                            IntrinsicWidth(
                              child: AppButton(
                                label: 'Remove photo',
                                tone: AppButtonTone.ghost,
                                height: 40,
                                onPressed: _removePhoto,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    LabeledField(
                      label: 'Name',
                      controller: _name,
                      hint: 'Your name',
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'Bio',
                      controller: _bio,
                      hint: 'A line about you',
                      maxLength: 160,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Your name, bio and photo stay on this device.',
                      style: AppType.micro.copyWith(color: colors.faint),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                gutter,
                12,
                gutter,
                Metrics.bottomInset(context) + 4,
              ),
              decoration: BoxDecoration(
                color: colors.bg,
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: AppButton(
                label: 'Save changes',
                expand: true,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
