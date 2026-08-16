import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps [AuthException] codes and raw messages to friendly, readable strings
/// suitable for display in the UI.
class AuthErrorHandler {
  AuthErrorHandler._();

  /// Returns a user-friendly message from a Supabase [AuthException].
  static String fromAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.code?.toLowerCase() ?? '';

    // Invalid credentials / wrong password
    if (code == 'invalid_credentials' ||
        msg.contains('invalid login credentials') ||
        msg.contains('invalid password') ||
        msg.contains('wrong password')) {
      return 'The email or password you entered is incorrect.';
    }

    // Email already registered
    if (code == 'user_already_exists' ||
        msg.contains('user already registered') ||
        msg.contains('already been registered') ||
        msg.contains('email already in use')) {
      return 'This email address is already registered. Try signing in instead.';
    }

    // Weak password
    if (code == 'weak_password' || msg.contains('password should be')) {
      return 'Your password is too weak. Use at least 6 characters.';
    }

    // Email not confirmed
    if (code == 'email_not_confirmed' ||
        msg.contains('email not confirmed') ||
        msg.contains('confirm your email')) {
      return 'Please verify your email address before signing in.';
    }

    // Too many requests / rate limiting
    if (code == 'over_email_send_rate_limit' ||
        msg.contains('for security purposes') ||
        msg.contains('rate limit') ||
        msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    // Session expired / not found
    if (code == 'session_not_found' ||
        msg.contains('session expired') ||
        msg.contains('jwt expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    // Invalid email format
    if (msg.contains('invalid email') || msg.contains('valid email')) {
      return 'Please enter a valid email address.';
    }

    // OAuth / provider errors
    if (msg.contains('oauth') || msg.contains('provider')) {
      return 'Social sign-in failed. Please try again or use email.';
    }

    // Network / server unavailable
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('socket')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Generic fallback — still better than showing the raw Supabase message
    return e.message.isNotEmpty ? e.message : 'An unknown error occurred.';
  }

  /// Returns a user-friendly message from any generic [Exception].
  static String fromException(Object e) {
    if (e is AuthException) return fromAuthException(e);
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
