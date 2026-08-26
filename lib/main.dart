import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<Offset?> _mousePositionNotifier =
      ValueNotifier<Offset?>(null);
  StreamSubscription<AuthState>? _authSub;
  bool _navigatedToDashboard = false;

  // Global Keys for smooth section scrolling
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _previewKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _stepsKey = GlobalKey();
  final GlobalKey _aiKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Check if session is already established on startup
    final currentSession = SupabaseService.instance.currentSession;
    if (currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_navigatedToDashboard) {
          _navigatedToDashboard = true;
          DemoService.instance.exitDemoMode();
          debugPrint('[AUTH] Redirecting to dashboard');
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      });
    }

    _authSub = SupabaseService.instance.onAuthStateChange.listen((data) {
      if (mounted &&
          data.session != null &&
          (data.event == AuthChangeEvent.signedIn ||
           data.event == AuthChangeEvent.initialSession)) {
        if (!_navigatedToDashboard) {
          _navigatedToDashboard = true;
          DemoService.instance.exitDemoMode();
          debugPrint('[AUTH] Redirecting to dashboard');
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    });
  }

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
    _authSub?.cancel();
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
      body: MouseRegion(
        onHover: (event) {
          _mousePositionNotifier.value = event.localPosition;
        },
        onExit: (_) {
          _mousePositionNotifier.value = null;
        },
        child: Stack(
          children: [
            // 1. Continuous Full-Page Animated Geometric ShapeGrid Canvas
            Positioned.fill(
              child: IgnorePointer(
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

            // 2. Ambient Floating Radial Glow Orbs across sections
            Positioned(
              top: -100,
              left: screenWidth / 2 - 350,
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

            // 3. Main Body Content Layer
            SafeArea(
              top: false,
              child: Column(
                children: [
                  // Sticky Navigation Bar
                  HeaderNav(
                    onNavClick: _scrollToSection,
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
                            Container(
                              key: _heroKey,
                              child: HeroSection(
                                onStartFreeTap: () {
                                  if (SupabaseService.instance.currentUser ==
                                          null &&
                                      Supabase.instance.client.auth
                                              .currentUser ==
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

                            // 2. Trust Banner / Logo Cloud
                            const LogoCloud(),

                            // 3. Product & ATS Showcase Preview Section
                            Container(
                              key: _previewKey,
                              child: ProductPreviewSection(
                                onTryPreview: () => _scrollToSection('cta'),
                              ),
                            ),

                            // 4. Core Features Section
                            Container(
                              key: _featuresKey,
                              child: FeaturesSection(
                                onFeatureTap: (key) => _scrollToSection('cta'),
                              ),
                            ),

                            // 5. How It Works - 4 Step Section
                            Container(
                              key: _stepsKey,
                              child: StepsSection(
                                onGetStartedTap: () =>
                                    _scrollToSection('cta'),
                              ),
                            ),

                            // 6. AI Intelligence & GitHub Import Showcase Section
                            Container(
                              key: _aiKey,
                              child: AiIntelligenceSection(
                                onTryTailoring: () => _scrollToSection('cta'),
                              ),
                            ),

                            // 7. Final Call to Action & Sign-up Form Section
                            Container(
                              key: _ctaKey,
                              child: const CtaFormSection(),
                            ),

                            // 8. Footer Section
                            FooterSection(
                              onNavClick: _scrollToSection,
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
