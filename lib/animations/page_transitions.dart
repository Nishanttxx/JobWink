import 'package:flutter/material.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/email_verify_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/main_dashboard_wrapper.dart';
import '../screens/profile_screen.dart';
import '../screens/reset_password_screen.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';

// ---------------------------------------------------------------------------
// Route Generator
// ---------------------------------------------------------------------------

class AppRouteTransitions {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget targetScreen;

    switch (settings.name) {
      case '/admin':
        targetScreen = const _AuthGate(
          allowDemoMode: false,
          child: AdminDashboardScreen(),
        );
        break;
      case '/dashboard':
      case '/cv-studio':
      case '/national':
      case '/international':
        targetScreen =
            const _AuthGate(child: MainDashboardWrapper(initialIndex: 2));
        break;
      case '/matcher':
        targetScreen =
            const _AuthGate(child: MainDashboardWrapper(initialIndex: 1));
        break;
      case '/job-prediction':
        targetScreen =
            const _AuthGate(child: MainDashboardWrapper(initialIndex: 3));
        break;
      case '/ats-score':
        targetScreen =
            const _AuthGate(child: MainDashboardWrapper(initialIndex: 4));
        break;


      // ── Auth screens ─────────────────────────────────────────────────────
      case '/forgot-password':
        targetScreen = const ForgotPasswordScreen();
        break;
      case '/reset-password':
        targetScreen = const ResetPasswordScreen();
        break;
      case '/verify-email':
        targetScreen = const EmailVerifyScreen();
        break;

      // ── Profile (Strict Auth Only - No Demo) ─────────────────────────────
      case '/profile':
        targetScreen = const _AuthGate(
          allowDemoMode: false,
          child: ProfileScreen(),
        );
        break;

      // ── Landing (default) ────────────────────────────────────────────────
      case '/':
      default:
        targetScreen = const LandingPage();
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  FadeTransition(
                    opacity: CurvedAnimation(
                        parent: animation, curve: Curves.easeOut),
                    child: child,
                  ),
        );
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AuthGate — route-protection widget (Gatekeeper Pattern)
// ---------------------------------------------------------------------------

/// Wraps any protected route. If the user is not authenticated and not in
/// [DemoService] demo mode, it redirects to the landing page and presents
/// the [AuthModal] overlay.
class _AuthGate extends StatefulWidget {
  final Widget child;
  final bool allowDemoMode;

  const _AuthGate({
    required this.child,
    this.allowDemoMode = true,
  });

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    DemoService.instance.addListener(_onDemoModeChanged);
  }

  @override
  void dispose() {
    DemoService.instance.removeListener(_onDemoModeChanged);
    super.dispose();
  }

  void _onDemoModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuth();
  }

  void _checkAuth() {
    if (_redirected) return;

    final auth = AuthProviderScope.of(context);

    // Still initializing — wait for the next rebuild when status settles.
    if (auth.isInitializing) return;

    if (!auth.isAuthenticated) {
      if (widget.allowDemoMode) {
        if (!DemoService.instance.isDemoMode) {
          DemoService.instance.enterDemoMode();
        }
        return;
      }

      if (!_redirected) {
        _redirected = true;

        // Schedule redirect after this frame to avoid build-phase navigation.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // Clear the entire nav stack and go to landing page.
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

          // Show auth modal on top of the landing page.
          AuthModal.show(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);

    // While initializing, show a subtle themed loading indicator (no auth flash).
    if (auth.isInitializing) {
      return Scaffold(
        backgroundColor: AppTheme.getBgColor(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    if (auth.isAuthenticated) {
      if (DemoService.instance.isDemoMode) {
        DemoService.instance.exitDemoMode();
      }
      return widget.child;
    }

    if (widget.allowDemoMode) {
      if (!DemoService.instance.isDemoMode) {
        DemoService.instance.enterDemoMode();
      }
      return widget.child;
    }

    return const SizedBox.shrink();
  }
}

