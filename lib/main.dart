import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'animations/lenis_scroll.dart';
import 'animations/page_transitions.dart';
import 'providers/auth_provider.dart';
import 'config/ai_config.dart';
import 'services/ai_service.dart';
import 'services/cookie_consent_service.dart';
import 'services/demo_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'widgets/ai_intelligence_section.dart';
import 'widgets/cookie_consent_banner.dart';
import 'widgets/cta_form_section.dart';
import 'widgets/features_section.dart';
import 'widgets/footer_section.dart';
import 'widgets/header_nav.dart';
import 'widgets/hero_section.dart';
import 'widgets/logo_cloud.dart';
import 'widgets/product_preview_section.dart';
import 'widgets/shape_grid_background.dart';
import 'widgets/steps_section.dart';
import 'screens/main_dashboard_wrapper.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 100);

  // Catch asynchronous platform & background auth exceptions gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('AuthException') ||
        details.exceptionAsString().contains('AuthApiException') ||
        details.exceptionAsString().contains('flow_state_expired')) {
      debugPrint('Handled background Supabase auth status.');
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (error.toString().contains('AuthException') ||
        error.toString().contains('AuthApiException') ||
        error.toString().contains('flow_state_expired')) {
      debugPrint('Handled async Supabase Auth error: $error');
      return true;
    }
    return false;
  };

  await Future.wait([
    SupabaseService.initialize(),
    ThemeService.instance.init(),
    CookieConsentService.instance.init(),
  ]);
  AIService.instance.initialize(
    geminiKey: AIConfig.geminiApiKey,
    openAiKey: AIConfig.openAiApiKey,
    cerebrasKey: AIConfig.cerebrasApiKey,
    mistralKey: AIConfig.mistralApiKey,
    xAiKey: AIConfig.xAiApiKey,
    groqKey: AIConfig.groqApiKey,
    nvidiaKey: AIConfig.nvidiaApiKey,
  );
  runApp(const JobwinkApp());
}

class JobwinkApp extends StatefulWidget {
  const JobwinkApp({super.key});

  @override
  State<JobwinkApp> createState() => _JobwinkAppState();
}

class _JobwinkAppState extends State<JobwinkApp> {
  /// Single [AuthProvider] instance owned by the root widget.
  final AuthProvider _authProvider = AuthProvider();

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authProvider,
      builder: (context, _) => AuthProviderScope(
        authProvider: _authProvider,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.instance.themeModeNotifier,
          builder: (context, mode, child) {
            return MaterialApp(
              title: 'Jobwink - Build a Job Winning Resume with AI',
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              initialRoute: '/',
              onGenerateRoute: AppRouteTransitions.generateRoute,
              builder: (context, child) =>
                  CookieConsentWrapper(child: child ?? const SizedBox.shrink()),
            );
          },
        ),
      ),
    );
  }
}

/// Dynamic root gate for the application ('/').
///
/// Resolves authenticated session state BEFORE choosing whether to render
/// the Landing Page, Login Flow, or Dashboard directly without any UI flash.
class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);

    // 1. Session resolution in progress: display clean themed startup state
    if (auth.isInitializing) {
      return Scaffold(
        backgroundColor: AppTheme.getBgColor(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Authenticated user: open dashboard directly (no landing flash)
    if (auth.isAuthenticated) {
      if (DemoService.instance.isDemoMode) {
        DemoService.instance.exitDemoMode();
      }
      return const MainDashboardWrapper(initialIndex: 2);
    }

    // 3. Demo mode user: open dashboard
    if (DemoService.instance.isDemoMode) {
      return const MainDashboardWrapper(initialIndex: 2);
    }

    // 4. Unauthenticated user: show landing page
    return const LandingPage();
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<Offset?> _mousePositionNotifier =
      ValueNotifier<Offset?>(null);

  // Global Keys for smooth section scrolling
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _previewKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _stepsKey = GlobalKey();
  final GlobalKey _aiKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  void _scrollToSection(String sectionKey) {
    GlobalKey? targetKey;
    switch (sectionKey) {
      case 'hero':
        targetKey = _heroKey;
        break;
      case 'preview':
        targetKey = _previewKey;
        break;
      case 'features':
        targetKey = _featuresKey;
        break;
      case 'steps':
        targetKey = _stepsKey;
        break;
      case 'ai':
        targetKey = _aiKey;
        break;
      case 'signup':
      case 'signin':
      case 'login':
      case 'cta':
        targetKey = _ctaKey;
        break;
    }

    if (targetKey != null && targetKey.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _mousePositionNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final bgColor = AppTheme.getBgColor(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: MouseRegion(
        onHover: (event) {
          _mousePositionNotifier.value = event.localPosition;
        },
        onExit: (_) {
          _mousePositionNotifier.value = null;
        },
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 1. Continuous Full-Page Animated Geometric ShapeGrid Canvas
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ShapeGridBackground(
                    speed: 0.35,
                    squareSize: 50.0,
                    direction: ShapeGridDirection.diagonal,
                    shape: ShapeGridShape.square,
                    hoverTrailAmount: 8,
                    mousePositionNotifier: _mousePositionNotifier,
                    borderColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    hoverFillColor: AppTheme.primaryOrange
                        .withValues(alpha: isDark ? 0.22 : 0.15),
                  ),
                ),
              ),
            ),

            // 2. Ambient Floating Radial Glow Orbs across sections
            Positioned(
              top: -100,
              left: screenWidth / 2 - 350,
              child: RepaintBoundary(
                child: Container(
                  width: 700,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryOrange.withAlpha(isDark ? 45 : 25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Main Body Content Layer
            SafeArea(
              top: false,
              child: Column(
                children: [
                  // Sticky Navigation Bar
                  RepaintBoundary(
                    child: HeaderNav(
                      onNavClick: _scrollToSection,
                    ),
                  ),
                  // Main Body with Lenis Smooth Scrolling
                  Expanded(
                    child: LenisSmoothScroll(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // 1. Hero Section
                            RepaintBoundary(
                              child: Container(
                                key: _heroKey,
                                child: HeroSection(
                                  onStartFreeTap: () {
                                    if (SupabaseService.instance.currentUser ==
                                        null) {
                                      debugPrint('[AUTH] Demo mode enabled');
                                      DemoService.instance.enterDemoMode();
                                    }
                                    Navigator.pushNamed(context, '/dashboard');
                                  },
                                  onSeeHowItWorksTap: () =>
                                      _scrollToSection('steps'),
                                ),
                              ),
                            ),

                            // 2. Trust Banner / Logo Cloud
                            const RepaintBoundary(
                              child: LogoCloud(),
                            ),

                            // 3. Product & ATS Showcase Preview Section
                            RepaintBoundary(
                              child: Container(
                                key: _previewKey,
                                child: ProductPreviewSection(
                                  onTryPreview: () => _scrollToSection('cta'),
                                ),
                              ),
                            ),

                            // 4. Core Features Section
                            RepaintBoundary(
                              child: Container(
                                key: _featuresKey,
                                child: const FeaturesSection(),
                              ),
                            ),

                            // 5. How It Works - 4 Step Section
                            RepaintBoundary(
                              child: Container(
                                key: _stepsKey,
                                child: StepsSection(
                                  onGetStartedTap: () =>
                                      _scrollToSection('cta'),
                                ),
                              ),
                            ),

                            // 6. AI Intelligence & GitHub Import Showcase Section
                            RepaintBoundary(
                              child: Container(
                                key: _aiKey,
                                child: AiIntelligenceSection(
                                  onTryTailoring: () => _scrollToSection('cta'),
                                ),
                              ),
                            ),

                            // 7. Final Call to Action & Sign-up Form Section
                            RepaintBoundary(
                              child: Container(
                                key: _ctaKey,
                                child: const CtaFormSection(),
                              ),
                            ),

                            // 8. Footer Section
                            RepaintBoundary(
                              child: FooterSection(
                                onNavClick: _scrollToSection,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
