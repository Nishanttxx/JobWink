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
    if (SupabaseConfig.url.isEmpty ||
        SupabaseConfig.anonKey.isEmpty ||
        SupabaseConfig.anonKey.length < 20) {
      debugPrint('Supabase initialization skipped: No valid API key configured.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException caught: ${e.message}');
    } catch (e) {
      debugPrint('Supabase initialization note: $e');
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

  /// Sign In with a social OAuth provider (Google, GitHub, …).
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final c = client;
    if (c == null) return false;
    final redirectTo = kIsWeb ? Uri.base.origin : null;
    final success = await c.auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
      queryParams: provider == OAuthProvider.google
          ? {'access_type': 'offline', 'prompt': 'consent'}
          : null,
    );
    return success;
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

    final payload = <String, dynamic>{
      'id': userId,
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

