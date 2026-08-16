import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../services/auth_error_handler.dart';
import '../services/supabase_service.dart';
import 'auth_result.dart';

/// Domain-layer gateway for all authentication operations.
///
/// Sits between [SupabaseService] (raw SDK calls) and [AuthController]
/// (presentation state). Responsible for:
/// - Delegating to [SupabaseService]
/// - Catching [AuthException] and generic errors
/// - Returning typed [AuthResult<T>] so callers never deal with raw exceptions
///
/// All public methods are safe to call without try/catch.
class AuthRepository {
  AuthRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  final SupabaseService _service;

  // ── Passthrough getters ──────────────────────────────────────────────────

  /// The currently authenticated Supabase [User], or `null`.
  User? get currentUser => _service.currentUser;

  /// The active [Session], or `null` if no user is signed in.
  Session? get currentSession => _service.currentSession;

  /// Stream of Supabase [AuthState] events (sign-in, sign-out, etc.).
  Stream<AuthState> get onAuthStateChange => _service.onAuthStateChange;

  /// Whether Supabase has been initialised successfully.
  bool get isInitialized => _service.isInitialized;

  // ── Sign Up ──────────────────────────────────────────────────────────────

  /// Creates a new user account.
  ///
  /// Returns [AuthSuccess] with the [AuthResponse] on success.
  /// Returns [AuthFailure] with a readable message on any error.
  Future<AuthResult<AuthResponse>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _run(() => _service.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName,
        ));
  }

  // ── Sign In ──────────────────────────────────────────────────────────────

  /// Signs in an existing user with email and password.
  Future<AuthResult<AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    return _run(() => _service.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  // ── Google OAuth ─────────────────────────────────────────────────────────

  /// Initiates Google OAuth sign-in (opens browser; result fires via stream).
  Future<AuthResult<bool>> signInWithGoogle() async {
    return _run(() => _service.signInWithOAuth(OAuthProvider.google));
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────

  /// Signs out the current session.
  Future<AuthResult<void>> signOut() async {
    return _run(() => _service.signOut());
  }

  // ── Password Reset ───────────────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  Future<AuthResult<void>> forgotPassword({required String email}) async {
    return _run(() => _service.forgotPassword(email: email));
  }

  /// Updates the signed-in user's password to [newPassword].
  ///
  /// Call only after the user has followed the reset link (session active).
  Future<AuthResult<void>> resetPassword({required String newPassword}) async {
    return _run(() => _service.resetPassword(newPassword: newPassword));
  }

  // ── Email Verification ───────────────────────────────────────────────────

  /// Resends the email verification / OTP for [email].
  Future<AuthResult<void>> resendVerification({required String email}) async {
    return _run(() => _service.resendVerificationEmail(email: email));
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  /// Fetches the `public.profiles` row for [userId].
  ///
  /// Returns `null` inside [AuthSuccess] if no row exists yet.
  Future<AuthResult<AppUser?>> getProfile(String userId) async {
    return _run(() => _service.getProfile(userId));
  }

  /// Upserts the `public.profiles` row for [userId] with the provided fields.
  Future<AuthResult<AppUser?>> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? githubUrl,
  }) async {
    return _run(() => _service.updateProfile(
          userId: userId,
          fullName: fullName,
          avatarUrl: avatarUrl,
          phone: phone,
          location: location,
          linkedinUrl: linkedinUrl,
          githubUrl: githubUrl,
        ));
  }

  /// Uploads user avatar photo and updates public profile.
  Future<AuthResult<String?>> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    return _run(() => _service.uploadAvatar(
          userId: userId,
          fileBytes: fileBytes,
          fileExtension: fileExtension,
        ));
  }


  // ── Private helpers ──────────────────────────────────────────────────────

  /// Executes [call], wrapping the result in [AuthSuccess] or mapping any
  /// exception to [AuthFailure] with a human-readable message.
  Future<AuthResult<T>> _run<T>(Future<T> Function() call) async {
    try {
      final value = await call();
      return AuthSuccess(value);
    } on AuthException catch (e) {
      debugPrint('[AuthRepository] AuthException: ${e.code} — ${e.message}');
      return AuthFailure(
        AuthErrorHandler.fromAuthException(e),
        code: e.code,
      );
    } catch (e, st) {
      debugPrint('[AuthRepository] Exception: $e\n$st');
      return AuthFailure(AuthErrorHandler.fromException(e));
    }
  }
}
