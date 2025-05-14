import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'di/injection.dart';
import 'data/services/firebase_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/settings/settings_page.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/welcome/welcome_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/support/onboarding_screen.dart';
import 'presentation/screens/home/recording_screen.dart';
import 'presentation/screens/ai/transcription_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

// Global navigator key for error handling and navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Catch all Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // You can add custom logging here
  };

  // Guarded zone for uncaught async errors
  runZonedGuarded(() async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Load environment variables
    await dotenv.load(fileName: '.env');

    // 2. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Initialize your FirebaseService wrappers (should not re-call initializeApp)
    await FirebaseService.initialize();

    // 4. Configure dependency injection
    await configureDependencies();

    // 5. Prepare theme provider
    final themeProvider = getIt<ThemeProvider>();
    await themeProvider.loadPreferences();

    // 6. Set device orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 7. Set system UI for immersive look
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    // 8. Run the app with providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          // Add other providers here
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // Handle uncaught asynchronous errors
    debugPrint('Uncaught async error: $error');
    debugPrint(stack.toString());
    // Add custom error reporting if needed
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'CAIPO Assistant',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: themeProvider.getThemeData(false),
      darkTheme: themeProvider.getThemeData(true),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/record': (_) => const RecordingScreen(),
        '/transcription': (_) => const TranscriptionScreen(audioFilePath: ''),
      },
      builder: (context, child) {
        // Clamp text scaling for accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}