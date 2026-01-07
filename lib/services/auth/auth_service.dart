import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
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



    var resp = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    await _supabase.from("users").insert({

      "full_name": fullName,
      "email": email,

    });
    return resp;
  }

  // --- OTP VERIFICATION ---
  Future<AuthResponse> verifyOtp({required String email, required String token}) async {
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

  // --- UTILS ---
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // --- SOCIAL (Reused) ---
  Future<AuthResponse> signInWithGoogle() async {
    const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
    const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS ? iosClientId : null,
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    if (googleAuth == null) throw const AuthException('Google Sign-In failed.');

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
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
