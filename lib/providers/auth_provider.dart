/// Presentation-layer auth barrel.
///
/// `AuthProvider` is now a type alias for [AuthController]. All existing
/// `AuthProviderScope.of(context)` and `AuthProviderScope.read(context)`
/// calls continue to work because [AuthProviderScope] is defined here and
/// returns an [AuthController] (= [AuthProvider]).
///
/// Import this file anywhere you need to access the auth state or scope.
library;

import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

// Re-export everything screens need from a single import.
export '../controllers/auth_controller.dart' show AuthController, AuthStatus;
export '../repositories/auth_result.dart' show AuthResult, AuthSuccess, AuthFailure;

// ---------------------------------------------------------------------------
// AuthProvider typedef
// ---------------------------------------------------------------------------

/// Drop-in alias for [AuthController].
///
/// Every existing reference to `AuthProvider` continues to compile without
/// modification — it resolves to [AuthController] at compile time.
typedef AuthProvider = AuthController;

// ---------------------------------------------------------------------------
// AuthProviderScope  —  InheritedWidget that vends AuthController
// ---------------------------------------------------------------------------

/// Provides an [AuthController] (= [AuthProvider]) to the widget tree.
///
/// Wrap the root of your app with this widget and pass the single
/// [AuthController] instance owned by the root [StatefulWidget].
///
/// ```dart
/// AuthProviderScope(
///   authProvider: _authController,
///   child: MaterialApp(...),
/// )
/// ```
///
/// Widgets read the controller with:
/// ```dart
/// // Subscribes to rebuilds (use in build()):
/// final auth = AuthProviderScope.of(context);
///
/// // One-time read (use in callbacks):
/// final auth = AuthProviderScope.read(context);
/// ```
class AuthProviderScope extends InheritedWidget {
  final AuthController authProvider;

  const AuthProviderScope({
    super.key,
    required this.authProvider,
    required super.child,
  });

  @override
  bool updateShouldNotify(AuthProviderScope oldWidget) =>
      oldWidget.authProvider != authProvider;

  /// Access the nearest [AuthController] and subscribe to changes.
  ///
  /// The calling widget rebuilds whenever [AuthController] notifies.
  /// Call inside [State.build] or [StatelessWidget.build].
  static AuthController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AuthProviderScope>();
    assert(scope != null,
        'AuthProviderScope not found. Make sure it wraps your MaterialApp.');
    return scope!.authProvider;
  }

  /// Read-only access to [AuthController] without subscribing to rebuilds.
  ///
  /// Use inside event handlers, callbacks, and [initState] — anywhere you
  /// need the current value once but do not need automatic rebuilds.
  static AuthController read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AuthProviderScope>();
    assert(scope != null,
        'AuthProviderScope not found. Make sure it wraps your MaterialApp.');
    return scope!.authProvider;
  }
}
