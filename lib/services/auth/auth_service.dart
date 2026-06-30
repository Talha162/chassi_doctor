import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../notification_service.dart';

class AuthService {
  static const String _mobileGoogleRedirectUrl =
      'com.chassisdoctor.app://login-callback/';
  static const String _deleteAccountEndpoint =
      'https://us-central1-chassis-doctor.cloudfunctions.net/deleteAccountSelfService';

  final SupabaseClient _supabase = Supabase.instance.client;

  // --- EMAIL LOGIN (Standard) ---
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Supabase uses signInWithPassword for email/password login
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // --- EMAIL SIGN UP (Updated) ---
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // --- OTP VERIFICATION ---
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      token: token,
      email: email,
    );
  }

  // --- RESEND OTP ---
  Future<void> resendOtp({required String email}) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: _mobileGoogleRedirectUrl,
    );
  }

  Future<void> updatePassword({required String newPassword}) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // --- UTILS ---
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signOut() async {
    await NotificationService.instance.clearCurrentDeviceToken();
    await _supabase.auth.signOut();
  }

  Future<void> deleteCurrentAccount() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const AuthException('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse(_deleteAccountEndpoint),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        'Failed to delete account (${response.statusCode}).',
      );
    }

    await NotificationService.instance.clearCurrentDeviceToken();
    await _supabase.auth.signOut();
  }

  Future<void> ensurePublicUserProfile(User user) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName =
        metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        user.email?.split('@').first;
    final providerAvatarUrl =
        metadata['avatar_url'] as String? ??
        metadata['picture'] as String? ??
        metadata['photo_url'] as String?;

    final existingProfile =
        await _supabase.from('users').select('avatar_url').eq('id', user.id).maybeSingle();
    final existingAvatarUrl =
        existingProfile != null ? existingProfile['avatar_url'] as String? : null;

    await _supabase.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'full_name': fullName,
      'avatar_url': existingAvatarUrl ?? providerAvatarUrl,
      'last_login_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  // --- SOCIAL (Reused) ---
  Future<void> signInWithGoogle() async {
    final launched = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _mobileGoogleRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const AuthException('Unable to launch Google Sign-In.');
    }
  }

  // --- SIGN IN WITH APPLE (native, via Supabase id-token flow) ---
  Future<AuthResponse> signInWithApple() async {
    // A random string used to prevent replay attacks. The hashed value is sent
    // to Apple; the raw value is sent to Supabase to verify the returned token.
    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Could not read the credential from Apple.');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Apple only returns the user's name on the FIRST sign-in, so capture it
    // here when present (Supabase won't have it from the id token alone).
    final fullName = [credential.givenName, credential.familyName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ')
        .trim();
    if (fullName.isNotEmpty && response.user != null) {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    }

    return response;
  }

  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
