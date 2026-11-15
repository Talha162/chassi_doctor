import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any error into one short, friendly sentence for the user.
/// Never shows raw exception text, stack traces or server codes.
String friendlyError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (isNetworkError(error)) {
    return 'No internet connection. Check your connection and try again.';
  }
  if (error is TimeoutException) {
    return 'This is taking too long. Please try again.';
  }
  if (error is AuthException) return _authMessage(error, fallback);
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return "You don't have permission to do that.";
    }
    return fallback;
  }
  if (error is StorageException) {
    final m = error.message.toLowerCase();
    if (m.contains('size') || m.contains('too large')) {
      return 'That file is too large. Please choose a smaller one.';
    }
    return "Couldn't upload the file. Please try again.";
  }
  return fallback;
}

/// True for offline / DNS / connection-reset style failures.
bool isNetworkError(Object error) {
  if (error is SocketException || error is HttpException) return true;
  if (error is AuthRetryableFetchException) return true;
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('network is unreachable') ||
      text.contains('clientexception');
}

/// True when the user simply cancelled a sign-in sheet (no message needed).
bool isUserCancelled(Object error) {
  final text = error.toString().toLowerCase();
  if (error is PlatformException) {
    return error.code.toLowerCase().contains('cancel');
  }
  return text.contains('authorizationerrorcode.canceled') ||
      text.contains('canceled') ||
      text.contains('cancelled');
}

String _authMessage(AuthException e, String fallback) {
  final m = e.message.toLowerCase();
  final code = (e.code ?? '').toLowerCase();

  if (code == 'invalid_credentials' ||
      m.contains('invalid login credentials')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (code == 'email_not_confirmed' || m.contains('email not confirmed')) {
    return 'Please verify your email address before logging in.';
  }
  if (code == 'user_already_exists' ||
      m.contains('already registered') ||
      m.contains('already been registered')) {
    return 'An account with this email already exists. Please log in.';
  }
  if (code == 'weak_password' || m.contains('password should be')) {
    return 'That password is too weak. Use at least 8 characters with letters and numbers.';
  }
  if (code == 'same_password' ||
      m.contains('different from the old password')) {
    return 'Your new password must be different from your current one.';
  }
  if (m.contains('session') &&
      (m.contains('missing') || m.contains('expired'))) {
    return 'Your session has expired. Please log in again.';
  }
  if (code == 'otp_expired' ||
      (m.contains('expired') &&
          (m.contains('token') || m.contains('otp') || m.contains('link')))) {
    return 'That code has expired. Please request a new one.';
  }
  if (m.contains('token') &&
      (m.contains('invalid') || m.contains('not found'))) {
    return "That code isn't right. Please check it and try again.";
  }
  if (code.contains('rate_limit') ||
      m.contains('rate limit') ||
      m.contains('for security purposes') ||
      m.contains('too many')) {
    return 'Too many attempts. Please wait a minute and try again.';
  }
  if (code == 'validation_failed' || m.contains('invalid format')) {
    return 'Please enter a valid email address.';
  }
  if (code == 'user_not_found' || m.contains('user not found')) {
    return "We couldn't find an account with that email.";
  }
  if (code == 'signup_disabled' || m.contains('signups not allowed')) {
    return 'New sign-ups are temporarily unavailable.';
  }
  return fallback;
}
