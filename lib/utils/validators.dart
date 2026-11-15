/// Field validators for the app's forms. Each returns `null` when the value is
/// valid, or a short message shown in red under the field.
class AppValidators {
  AppValidators._();

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );

  /// Minimum length for new passwords (Supabase requires at least 6).
  static const int minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address';
    if (v.length > 254 || !_email.hasMatch(v)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// For logging in: only checks it's present (existing accounts may have
  /// older, shorter passwords, so don't enforce the new-password rules).
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password';
    return null;
  }

  /// For creating or changing a password.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please create a password';
    if (v.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use at least one letter and one number';
    }
    if (v.trim() != v) return "Password can't start or end with a space";
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Please confirm your password';
      if (value != original()) return "Passwords don't match";
      return null;
    };
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 60) return 'Name is too long (max 60 characters)';
    if (!RegExp(r"[A-Za-zÀ-ɏ]").hasMatch(v)) {
      return 'Please enter a valid name';
    }
    return null;
  }

  /// Optional phone number: blank is fine; otherwise 7–15 digits, optional +.
  static String? optionalPhone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (v.isEmpty) return null;
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(v)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Optional free text with a length cap.
  static String? Function(String?) optionalMax(
    int max, {
    String label = 'This',
  }) {
    return (value) {
      if ((value ?? '').trim().length > max) {
        return '$label is too long (max $max characters)';
      }
      return null;
    };
  }

  /// Required text with min/max length, e.g. report titles.
  static String? Function(String?) requiredText({
    required String label,
    int min = 1,
    int? max,
  }) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return 'Please enter $label';
      if (v.length < min)
        return '${_cap(label)} is too short (min $min characters)';
      if (max != null && v.length > max) {
        return '${_cap(label)} is too long (max $max characters)';
      }
      return null;
    };
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
