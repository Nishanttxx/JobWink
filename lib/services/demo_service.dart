import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Singleton service managing ephemeral, read-only Demo Mode state.
class DemoService extends ChangeNotifier {
  static final DemoService instance = DemoService._internal();

  DemoService._internal();

  bool _isDemoMode = false;

  /// Whether the app is currently running in unauthenticated Demo Mode.
  /// Always returns false if a valid Supabase user session exists.
  bool get isDemoMode {
    if (SupabaseService.instance.currentUser != null) {
      return false;
    }
    return _isDemoMode;
  }

  /// Enable Demo Mode (in-memory only). Ignored if user is authenticated.
  void enterDemoMode() {
    if (SupabaseService.instance.currentUser != null) {
      if (_isDemoMode) {
        _isDemoMode = false;
        notifyListeners();
      }
      return;
    }

    if (!_isDemoMode) {
      _isDemoMode = true;
      notifyListeners();
    }
  }

  /// Exit Demo Mode (e.g. when user authenticates).
  void exitDemoMode() {
    if (_isDemoMode) {
      _isDemoMode = false;
      notifyListeners();
    }
  }
}

