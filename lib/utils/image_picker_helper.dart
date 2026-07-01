import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorsport/constants/app_colors.dart';

/// Shared helper for picking + circular-cropping avatar/profile images.
///
/// Picks an image from [source], then opens the native full-screen cropper
/// (pan + pinch-zoom + rotate) locked to a 1:1 circular crop so the framing is
/// baked into the saved file. Every image-pick spot should call this so avatars
/// render correctly with `BoxFit.cover` everywhere. Returns the cropped file,
/// or null if the user cancelled either step.
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickAndCropAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 800,
      maxHeight: 800,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: kPrimaryColor,
          toolbarWidgetColor: kWhiteColor,
          backgroundColor: kPrimaryColor,
          activeControlsWidgetColor: kSecondaryColor,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }
}
