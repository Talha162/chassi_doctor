import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/models/app_user.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/widget/common_image_view_widget.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _service = SupabaseService.instance;

  AppUser? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _dobC = TextEditingController();
  final _locationC = TextEditingController();
  final _phoneC = TextEditingController();

  XFile? _pickedImage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final profile = await _service.getUserById(userId);
      if (profile == null) {
        setState(() => _isLoading = false);
        return;
      }

      _user = profile;
      _nameC.text = profile.fullName ?? '';
      _emailC.text = profile.email ?? '';

      // These extra fields assume you’ve added them to AppUser and DB
      _locationC.text = profile.location ?? '';
      _phoneC.text = profile.phone ?? '';
      if (profile.dateOfBirth != null) {
        final d = profile.dateOfBirth!;
        _dobC.text =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      _avatarUrl = profile.avatarUrl;
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show bottom sheet with camera / gallery / remove options
  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPrimaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: kTertiaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              MyText(
                text: 'Update profile photo',
                size: 16,
                weight: FontWeight.w600,
                paddingBottom: 8,
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                title: const Text(
                  'Take photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined, color: Colors.white),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImage != null || _avatarUrl != null) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImage = null;
                      _avatarUrl = null;
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _pickedImage = result;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }


  /// Show DatePicker for DOB, fill _dobC
  Future<void> _pickDob() async {
    DateTime initialDate = DateTime(1990, 1, 1);
    if (_dobC.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_dobC.text.trim());
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      builder: (ctx, child) {
        // Optional theming
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: kSecondaryColor,
              surface: kPrimaryColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dobC.text = formatted;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    try {
      setState(() => _isSaving = true);

      String? avatarUrl = _avatarUrl;

      // upload avatar if changed
      if (_pickedImage != null) {
        final file = File(_pickedImage!.path);
        avatarUrl = await _service.uploadProfileImage(
          userId: _user!.id,
          file: file,
        );
      }

      DateTime? dob;
      if (_dobC.text.trim().isNotEmpty) {
        dob = DateTime.tryParse(_dobC.text.trim());
      }

      final updated = await _service.updateUserProfile(
        userId: _user!.id,
        fullName: _nameC.text.trim(),
        email: _emailC.text.trim(),
        phone: _phoneC.text.trim(),
        location: _locationC.text.trim(),
        dateOfBirth: dob,
        avatarUrl: avatarUrl,
      );

      _user = updated;
      _avatarUrl = updated.avatarUrl;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.pop(context, updated); // return to Settings with updated user
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _dobC.dispose();
    _locationC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Profile & Settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Account Information',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text: 'Manage your personal details and account settings',
            size: 12,
            paddingBottom: 30,
          ),
          Center(
            child: GestureDetector(
              onTap: _showImageSourceSheet, // 👈 open options
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: kSecondaryColor,
                    width: 4,
                  ),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: _pickedImage != null
                        ? Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                    )
                        : CommonImageView(
                      height: 120,
                      width: 120,
                      radius: 100,
                      url: _avatarUrl ?? dummyImg,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MyText(
            text: _nameC.text.isEmpty ? 'Your name' : _nameC.text,
            size: 18,
            weight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          MyText(
            text: _emailC.text,
            size: 14,
            textAlign: TextAlign.center,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 50,
          ),
          _EditProfileTile(
            title: 'Full name',
            controller: _nameC,
          ),
          _EditProfileTile(
            title: 'Email',
            controller: _emailC,
          ),
          _EditProfileTile(
            title: 'Date of birth',
            controller: _dobC,
            hint: 'YYYY-MM-DD',
            readOnly: true,          // 👈 no manual typing
            onTap: _pickDob,         // 👈 open date picker
          ),
          _EditProfileTile(
            title: 'Location',
            controller: _locationC,
          ),
          _EditProfileTile(
            title: 'Phone',
            controller: _phoneC,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: kPrimaryColor,
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: MyButton(
            buttonText: _isSaving ? 'Saving...' : 'Save Configuration',
            onTap: _isSaving ? null : () => _saveProfile(),
          ),
        ),
      ),
    );
  }
}

class _EditProfileTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String? hint;
  final bool readOnly;
  final VoidCallback? onTap;

  const _EditProfileTile({
    Key? key,
    required this.title,
    required this.controller,
    this.hint,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MyText(text: title, size: 12),
            const Spacer(),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                onTap: onTap,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  color: kTertiaryColor,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: kTertiaryColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                cursorColor: kSecondaryColor,
              ),
            ),
          ],
        ),
        Container(
          height: 1,
          color: kQuaternaryColor,
          margin: const EdgeInsets.only(top: 10, bottom: 20),
        ),
      ],
    );
  }
}
