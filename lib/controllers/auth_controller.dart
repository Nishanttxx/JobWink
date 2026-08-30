import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/auth_result.dart';
import '../services/demo_service.dart';
import '../services/supabase_service.dart';
import '../utils/avatar_image_helper.dart';


// ---------------------------------------------------------------------------
// Re-export AuthStatus so existing imports still resolve
// ---------------------------------------------------------------------------

/// All possible authentication states the app can be in.
enum AuthStatus {
  /// App is checking for an existing session (startup).
  initializing,

  /// No active session; user is not signed in.
  unauthenticated,

  /// An async auth operation is in progress.
  loading,

  /// User is signed in and profile is loaded.
  authenticated,

  /// Sign-up succeeded but email confirmation is still pending.
  emailVerificationPending,

  /// An auth error occurred (see [AuthController.errorMessage]).
  error,
}

// ---------------------------------------------------------------------------
// AuthController
// ---------------------------------------------------------------------------

/// Presentation-layer state manager for authentication.
///
/// Delegates all auth operations to [AuthRepository], which delegates to
/// [SupabaseService]. This controller owns only UI-relevant state:
/// [status], [currentUser], [errorMessage], and [pendingVerificationEmail].
///
/// **Public API is identical to the old AuthProvider** so every existing
/// screen compiles without modification. `AuthProvider` is a typedef of this
/// class (see `auth_provider.dart`).
class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
      : _repo = repository ?? AuthRepository() {
    // Eager synchronous session check if Supabase is already initialized
    final initialSession = _repo.currentSession;
    if (initialSession != null) {
      _currentUser = AppUser(
        id: initialSession.user.id,
        email: initialSession.user.email ?? '',
        fullName: initialSession.user.userMetadata?['full_name'] ??
            initialSession.user.userMetadata?['name'],
        avatarUrl: initialSession.user.userMetadata?['avatar_url'] ??
            initialSession.user.userMetadata?['picture'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _status = AuthStatus.authenticated;
    }
    _init();
  }

  final AuthRepository _repo;

  // ── Internal state ────────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _currentUser;
  String? _errorMessage;
  String? _pendingVerificationEmail;

  StreamSubscription<AuthState>? _authSub;

  // ── Public getters ────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isInitializing => _status == AuthStatus.initializing;
  bool get isEmailVerificationPending =>
      _status == AuthStatus.emailVerificationPending;
  bool get isAdmin =>
      _currentUser != null &&
      BackendConfig.adminEmail.isNotEmpty &&
      _currentUser!.email.trim().toLowerCase() ==
          BackendConfig.adminEmail.trim().toLowerCase();


  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _init() async {
    debugPrint('[AUTH] Application started');
    debugPrint('[AUTH] Checking existing session');
    try {
      // Subscribe to Supabase auth events for the lifetime of this controller.
      _authSub = _repo.onAuthStateChange.listen(
        _onAuthStateChange,
        onError: (error) {
          debugPrint('[AuthController] Auth error: $error');
          _set(AuthStatus.unauthenticated, error: error.toString());
        },
      );

      // Restore persisted session on start
      final session = _repo.currentSession;
      if (session != null) {
        debugPrint('[AUTH] Session found: true');
        debugPrint('[AUTH] Session established');
        _currentUser = AppUser(
          id: session.user.id,
          email: session.user.email ?? '',
          fullName: session.user.userMetadata?['full_name'] ??
              session.user.userMetadata?['name'],
          avatarUrl: session.user.userMetadata?['avatar_url'] ??
              session.user.userMetadata?['picture'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _set(AuthStatus.authenticated);
        _logProfileDebug(session.user.id);

        // Fetch full profile details asynchronously in background without blocking UI
        _fetchAndSetProfile(session.user.id);
      } else {
        debugPrint('[AUTH] Session found: false');
        _set(AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('[AuthController] Init error: $e');
      _set(AuthStatus.unauthenticated);
    }
  }

  Future<void> _onAuthStateChange(AuthState state) async {
    try {
      debugPrint(
          '[AuthController] ${state.event} — uid: ${state.session?.user.id}');

      switch (state.event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
          final uid = state.session?.user.id;
          if (uid != null && state.session != null) {
            debugPrint('[OAUTH-DEBUG] OAuth callback received: YES');
            debugPrint('[OAUTH-DEBUG] Session detected: YES');
            debugPrint('[OAUTH-DEBUG] Authenticated user ID: $uid');
            debugPrint('[OAUTH-DEBUG] Final route: /dashboard');
            _currentUser ??= AppUser(
              id: uid,
              email: state.session!.user.email ?? '',
              fullName: state.session!.user.userMetadata?['full_name'] ??
                  state.session!.user.userMetadata?['name'],
              avatarUrl: state.session!.user.userMetadata?['avatar_url'] ??
                  state.session!.user.userMetadata?['picture'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            _set(AuthStatus.authenticated);
            _pendingVerificationEmail = null;
            await _fetchAndSetProfile(uid);
          } else {
            _set(AuthStatus.unauthenticated);
          }

        case AuthChangeEvent.signedOut:
          DemoService.instance.exitDemoMode();
          _currentUser = null;
          _pendingVerificationEmail = null;
          _set(AuthStatus.unauthenticated);

        case AuthChangeEvent.userUpdated:
          final uid = state.session?.user.id;
          if (uid != null) await _fetchAndSetProfile(uid);
          _set(AuthStatus.authenticated);

        case AuthChangeEvent.passwordRecovery:
          // Temporary session active — ResetPasswordScreen completes the flow.
          _set(AuthStatus.authenticated);

        case AuthChangeEvent.tokenRefreshed:
          // Silent refresh — session remains active.
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[OAUTH-DEBUG] Error: $e');
      debugPrint('[AuthController] Auth stream exception caught: $e');
      _set(AuthStatus.unauthenticated, error: e.toString());
    }
  }

  /// Fetches the `public.profiles` row and stores it in [_currentUser].
  Future<void> _fetchAndSetProfile(String userId) async {
    final result = await _repo.getProfile(userId);
    if (result is AuthSuccess<AppUser?>) {
      if (result.value != null) {
        _currentUser = result.value;
        debugPrint('[OAUTH-DEBUG] Profile loaded: YES');
      } else {
        // First login: ensure profile row exists in Supabase profiles table linked to auth.uid()
        final authUser = _repo.currentUser;
        if (authUser != null && authUser.id == userId) {
          final fullName = authUser.userMetadata?['full_name'] as String? ??
              authUser.userMetadata?['name'] as String?;
          final avatarUrl = authUser.userMetadata?['avatar_url'] as String? ??
              authUser.userMetadata?['picture'] as String?;
          final updateRes = await _repo.updateProfile(
            userId: userId,
            fullName: fullName,
            avatarUrl: avatarUrl,
          );
          if (updateRes is AuthSuccess<AppUser?> && updateRes.value != null) {
            _currentUser = updateRes.value;
            debugPrint('[OAUTH-DEBUG] Profile loaded: YES (New profile created)');
          } else {
            _currentUser = AppUser(
              id: userId,
              email: authUser.email ?? '',
              fullName: fullName,
              avatarUrl: avatarUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            debugPrint('[OAUTH-DEBUG] Profile loaded: YES (Fallback profile)');
          }
        }
      }
      _logProfileDebug(userId);
      notifyListeners();

      if (_currentUser?.avatarUrl != null &&
          _currentUser!.avatarUrl!.contains('googleusercontent.com')) {
        final googleUrl = _currentUser!.avatarUrl!;
        if (AvatarImageHelper.isFailed(googleUrl)) {
          return;
        }
        SupabaseService.instance
            .syncGoogleAvatarToSupabase(
          userId: userId,
          googleUrl: googleUrl,
        )
            .then((mirroredUrl) {
          if (mirroredUrl != null &&
              _currentUser != null &&
              _currentUser!.id == userId) {
            _currentUser = _currentUser!.copyWith(avatarUrl: mirroredUrl);
            notifyListeners();
          } else {
            AvatarImageHelper.markFailed(googleUrl);
          }
        });
      }
    }
  }

  void _set(AuthStatus status, {String? error}) {
    _status = status;
    _errorMessage = error;
    if (_status == AuthStatus.authenticated) {
      DemoService.instance.exitDemoMode();
    }
    notifyListeners();
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────

  /// Signs up a new user with email + password.
  ///
  /// Returns `true` on success (either email-verification pending or signed in).
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _set(AuthStatus.loading);
    final result = await _repo.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    return result.when(
      onSuccess: (response) {
        if (response.session != null) {
          // Email confirmation is disabled — user is immediately signed in.
          _currentUser = null; // profile will load via stream event
          _set(AuthStatus.authenticated);
        } else {
          // Email confirmation required.
          _pendingVerificationEmail = email;
          _set(AuthStatus.emailVerificationPending);
        }
        return true;
      },
      onFailure: (msg) {
        _set(AuthStatus.error, error: msg);
        return false;
      },
    );
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  /// Signs in an existing user with email + password.
  ///
  /// Returns `true` if the request was accepted; the auth state stream will
  /// fire [AuthChangeEvent.signedIn] and update [status] to authenticated.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _set(AuthStatus.loading);
    final result = await _repo.signIn(email: email, password: password);
    return result.when(
      onSuccess: (_) => true, // stream event sets status
      onFailure: (msg) {
        _set(AuthStatus.error, error: msg);
        return false;
      },
    );
  }

  // ── Social OAuth ─────────────────────────────────────────────────────────

  /// Launches the OAuth flow for [provider] (Google, GitHub, etc.).
  ///
  /// Returns `true` if the browser was opened; the auth state stream handles the callback.
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    debugPrint('[AUTH] OAuth started: ${provider.name}');
    _set(AuthStatus.loading);
    final result = await _repo.signInWithOAuth(provider);
    return result.when(
      onSuccess: (launched) {
        if (launched) {
          // Browser opened; reset loading — stream will fire on redirect.
          _set(AuthStatus.unauthenticated);
          return true;
        } else {
          final errorMsg = !SupabaseService.instance.isInitialized
              ? 'Supabase is not initialized. Check SUPABASE_URL and SUPABASE_ANON_KEY build settings.'
              : 'Failed to launch ${provider.name} login.';
          _set(AuthStatus.error, error: errorMsg);
          return false;
        }
      },
      onFailure: (msg) {
        _set(AuthStatus.error, error: msg);
        return false;
      },
    );
  }

  /// Launches the Google OAuth flow (opens the browser).
  Future<bool> signInWithGoogle() => signInWithOAuth(OAuthProvider.google);

  /// Launches the GitHub OAuth flow (opens the browser).
  Future<bool> signInWithGithub() => signInWithOAuth(OAuthProvider.github);

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  Future<bool> forgotPassword({required String email}) async {
    _set(AuthStatus.loading);
    final result = await _repo.forgotPassword(email: email);
    return result.when(
      onSuccess: (_) {
        _set(AuthStatus.unauthenticated);
        return true;
      },
      onFailure: (msg) {
        _set(AuthStatus.error, error: msg);
        return false;
      },
    );
  }

  /// Updates the signed-in user's password to [newPassword].
  Future<bool> resetPassword({required String newPassword}) async {
    _set(AuthStatus.loading);
    final result = await _repo.resetPassword(newPassword: newPassword);
    return result.when(
      onSuccess: (_) {
        _set(AuthStatus.authenticated);
        return true;
      },
      onFailure: (msg) {
        _set(AuthStatus.error, error: msg);
        return false;
      },
    );
  }

  // ── Email Verification ────────────────────────────────────────────────────

  /// Resends the verification / OTP email for [email].
  Future<bool> resendVerificationEmail({required String email}) async {
    final result = await _repo.resendVerification(email: email);
    return result.when(
      onSuccess: (_) => true,
      onFailure: (msg) {
        _errorMessage = msg;
        notifyListeners();
        return false;
      },
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  void _logProfileDebug(String userId) {
    debugPrint('[PROFILE] Auth user ID: $userId');
    debugPrint('[PROFILE] Account name loaded: ${_currentUser?.fullName ?? _currentUser?.displayName}');
    debugPrint('[PROFILE] Account email loaded: ${_currentUser?.email}');
    debugPrint('[PROFILE] Profile image loaded: ${_currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty}');
  }

  /// Updates the current user's profile and refreshes [currentUser].
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? githubUrl,
  }) async {
    final uid = _repo.currentUser?.id;
    if (uid == null) return false;

    final result = await _repo.updateProfile(
      userId: uid,
      fullName: fullName,
      phone: phone,
      location: location,
      linkedinUrl: linkedinUrl,
      githubUrl: githubUrl,
    );
    return result.when(
      onSuccess: (user) {
        if (user != null) {
          _currentUser = user;
        }
        _logProfileDebug(uid);
        notifyListeners();
        return true;
      },
      onFailure: (msg) {
        _errorMessage = msg;
        notifyListeners();
        return false;
      },
    );
  }

  /// Uploads avatar photo for current user.
  Future<bool> uploadAvatar({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final uid = _repo.currentUser?.id;
    if (uid == null) return false;

    final result = await _repo.uploadAvatar(
      userId: uid,
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
    return result.when(
      onSuccess: (url) {
        if (_currentUser != null && url != null) {
          AvatarImageHelper.clearFailed(url);
          _currentUser = _currentUser!.copyWith(avatarUrl: url);
        }
        _logProfileDebug(uid);
        notifyListeners();
        return true;
      },
      onFailure: (msg) {
        _errorMessage = msg;
        notifyListeners();
        return false;
      },
    );
  }


  // ── Sign Out ──────────────────────────────────────────────────────────────

  /// Signs out the current user.
  ///
  /// The auth state stream fires [AuthChangeEvent.signedOut] and sets
  /// [status] to [AuthStatus.unauthenticated] automatically.
  Future<void> signOut() async {
    DemoService.instance.exitDemoMode();
    _currentUser = null;
    _pendingVerificationEmail = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    await _repo.signOut();
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  /// Clears a transient error message without changing the auth status.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
