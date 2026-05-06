import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

    await _supabase.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'full_name': fullName,
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

  Future<AuthResponse> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.success) {
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: result.accessToken!.token,
      );
    }
    throw AuthException('Facebook login failed');
  }
}
