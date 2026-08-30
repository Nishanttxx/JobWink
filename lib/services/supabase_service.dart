import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/app_user.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  static bool _isInitialized = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    final url = SupabaseConfig.url;
    final key = SupabaseConfig.anonKey;

    debugPrint('============================================================');
    debugPrint('[SUPABASE CONFIG DIAGNOSTICS]');
    debugPrint('SUPABASE_URL_FROM_DART = ${url.isNotEmpty ? "YES" : "NO"}');
    debugPrint('SUPABASE_ANON_KEY_FROM_DART = ${key.isNotEmpty ? "YES" : "NO"}');
    if (url.isNotEmpty) {
      debugPrint('SUPABASE_URL = $url');
    }
    debugPrint('============================================================');

    if (!SupabaseConfig.isConfigured) {
      debugPrint('SUPABASE_INITIALIZATION_STARTED = NO');
      debugPrint('SUPABASE_INITIALIZATION_COMPLETED = NO');
      debugPrint('[SUPABASE] Initialization skipped: SUPABASE_URL or SUPABASE_ANON_KEY is missing or invalid.');
      return;
    }

    debugPrint('SUPABASE_INITIALIZATION_STARTED = YES');
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('SUPABASE_INITIALIZATION_COMPLETED = YES');
      debugPrint('[SUPABASE] Initialized successfully with: $url');
    } on AuthException catch (e) {
      debugPrint('SUPABASE_INITIALIZATION_COMPLETED = NO');
      debugPrint('[SUPABASE] AuthException caught: ${e.message}');
    } catch (e) {
      debugPrint('SUPABASE_INITIALIZATION_COMPLETED = NO');
      debugPrint('[SUPABASE] Initialization note: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Core Getters
  // ---------------------------------------------------------------------------

  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  User? get currentUser => _isInitialized ? client?.auth.currentUser : null;

  Session? get currentSession =>
      _isInitialized ? client?.auth.currentSession : null;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get onAuthStateChange =>
      _isInitialized
          ? Supabase.instance.client.auth.onAuthStateChange
          : const Stream.empty();


  // Email / Password Authentication
  // ---------------------------------------------------------------------------

  /// Sign Up with email, password, and optional full name.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    final response = await c.auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.isNotEmpty
          ? {'full_name': fullName}
          : null,
    );
    return response;
  }

  /// Sign In with email & password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    final response = await c.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sends a password-reset email to [email].
  Future<void> forgotPassword({required String email}) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    await c.auth.resetPasswordForEmail(
      email,
      // On web the origin is used automatically; on mobile configure deep-link.
      redirectTo: kIsWeb ? '${Uri.base.origin}/#/reset-password' : null,
    );
  }

  /// Updates the current user's password to [newPassword].
  /// Call this after the user follows the reset link and the session is active.
  Future<void> resetPassword({required String newPassword}) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    await c.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ---------------------------------------------------------------------------
  // Social OAuth
  // ---------------------------------------------------------------------------

  /// Dynamically determines the OAuth redirect URL based on the current browser origin.
  ///
  /// Works across all environments without hardcoding ports:
  /// - Localhost with any dynamic port: `http://localhost:<port>/`
  /// - Production on Cloudflare Pages: `https://jobwink.pages.dev/`
  /// - Preview deployments: `https://<preview>.jobwink.pages.dev/`
  static String resolveOAuthRedirectUrl({String? customOrigin}) {
    final origin = customOrigin ?? (kIsWeb ? Uri.base.origin : '');
    if (origin.isNotEmpty && !origin.startsWith('null') && origin != 'null') {
      return origin.endsWith('/') ? origin : '$origin/';
    }
    return 'https://jobwink.pages.dev/';
  }

  /// Sign In with a social OAuth provider (Google, GitHub, …).
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final providerTitle = provider == OAuthProvider.google
        ? 'Google'
        : (provider == OAuthProvider.github ? 'GitHub' : provider.name);
    debugPrint('[OAUTH DEBUG] $providerTitle login clicked');
    debugPrint('[OAUTH DEBUG] Starting Supabase OAuth');

    final c = client;
    if (c == null) {
      debugPrint('[OAUTH DEBUG] Redirect URL: null (Supabase not initialized)');
      debugPrint('[OAUTH DEBUG] signInWithOAuth returned: false');
      debugPrint(
          '[OAUTH DEBUG] error: Supabase is not initialized. Check SUPABASE_URL and SUPABASE_ANON_KEY build settings.');
      return false;
    }

    final redirectTo = resolveOAuthRedirectUrl();
    debugPrint('[OAUTH DEBUG] Redirect URL: $redirectTo');

    try {
      final success = await c.auth.signInWithOAuth(
        provider,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.platformDefault,
        queryParams: provider == OAuthProvider.google
            ? {'access_type': 'offline', 'prompt': 'consent'}
            : null,
      );
      debugPrint('[OAUTH DEBUG] signInWithOAuth returned: $success');
      debugPrint('[OAUTH DEBUG] error: none');
      return success;
    } on AuthException catch (e) {
      debugPrint('[OAUTH DEBUG] signInWithOAuth returned: false');
      debugPrint('[OAUTH DEBUG] error: ${e.message} (code: ${e.statusCode})');
      rethrow;
    } catch (e) {
      debugPrint('[OAUTH DEBUG] signInWithOAuth returned: false');
      debugPrint('[OAUTH DEBUG] error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Session Management
  // ---------------------------------------------------------------------------

  /// Sign out the current user session.
  Future<void> signOut() async {
    await client?.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Profile (public.profiles)
  // ---------------------------------------------------------------------------

  /// Fetches the profile row for [userId] from `public.profiles`.
  /// Returns `null` if the row does not exist yet.
  Future<AppUser?> getProfile(String userId) async {
    final c = client;
    if (c == null) return null;
    try {
      final data = await c
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return AppUser.fromMap(data);
    } on PostgrestException catch (pe) {
      debugPrint('getProfile PostgrestException: code=${pe.code}, message=${pe.message}');
      if (pe.code == 'PGRST303' || pe.code == '401' || pe.message.contains('JWT issued at future')) {
        try {
          debugPrint('Refreshing Supabase auth session to resolve JWT clock skew...');
          await c.auth.refreshSession();
          final retryData = await c
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (retryData != null) return AppUser.fromMap(retryData);
        } catch (refreshErr) {
          debugPrint('Session refresh retry error: $refreshErr');
        }
      }
      return null;
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  /// Upserts the profile row for the current user.
  ///
  /// Safely merges with any existing data so partial updates work fine.
  Future<AppUser?> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? githubUrl,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');

    final authEmail = c.auth.currentUser?.email;
    final payload = <String, dynamic>{
      'id': userId,
      if (authEmail != null && authEmail.isNotEmpty) 'email': authEmail,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'location': location,
      'linkedin_url': linkedinUrl,
      'github_url': githubUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }..removeWhere((_, v) => v == null);

    final data = await c
        .from('profiles')
        .upsert(payload, onConflict: 'id')
        .select()
        .single();

    if (fullName != null || avatarUrl != null) {
      try {
        final metaData = <String, dynamic>{
          if (fullName != null) 'full_name': fullName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        };
        await c.auth.updateUser(UserAttributes(data: metaData));
      } catch (_) {}
    }

    return AppUser.fromMap(data);
  }

  /// Resends the email verification email to the current user.
  Future<void> resendVerificationEmail({required String email}) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    await c.auth.resend(type: OtpType.signup, email: email);
  }

  /// Uploads avatar photo to storage bucket 'avatars' and updates profile.
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    await c.storage.from('avatars').uploadBinary(
      fileName,
      fileBytes,
      fileOptions: FileOptions(contentType: 'image/$fileExtension', upsert: true),
    );
    final publicUrl = c.storage.from('avatars').getPublicUrl(fileName);
    await updateProfile(userId: userId, avatarUrl: publicUrl);
    return publicUrl;
  }

  /// Safely mirrors external Google avatar to user's Supabase Storage bucket ('avatars')
  /// to avoid rate limits (HTTP 429) from external avatar URLs.
  Future<String?> syncGoogleAvatarToSupabase({
    required String userId,
    required String googleUrl,
  }) async {
    if (!googleUrl.contains('googleusercontent.com')) return null;
    try {
      debugPrint('[SupabaseService] Mirroring external avatar to Supabase storage for user: $userId');
      final res = await http.get(Uri.parse(googleUrl)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        final publicUrl = await uploadAvatar(
          userId: userId,
          fileBytes: res.bodyBytes,
          fileExtension: 'png',
        );
        debugPrint('[SupabaseService] Mirrored avatar saved to Supabase: $publicUrl');
        return publicUrl;
      }
    } catch (e) {
      debugPrint('[SupabaseService] External avatar mirror skipped: $e');
    }
    return null;
  }
}

