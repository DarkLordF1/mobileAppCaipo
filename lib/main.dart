// lib/main.dart
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
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/support/onboarding_screen.dart';
import 'presentation/screens/welcome/welcome_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/settings/settings_page.dart';
import 'presentation/screens/home/recording_screen.dart';
import 'presentation/screens/ai/transcription_screen.dart';

// A global Navigator key (if you need it for error handling/navigation)
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 1) Catch Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: send to your logging service
  };

  // 2) Ensure binding is initialized (needed for SystemChrome & async)
  WidgetsFlutterBinding.ensureInitialized();

  // 3) Load environment variables
  await dotenv.load(fileName: '.env');

  // 4) Initialize Firebase with your generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 5) Initialize your own FirebaseService (wrappers, etc.)
  await FirebaseService.initialize();

  // 6) Configure dependency injection
  await configureDependencies();

  // 7) Prepare your ThemeProvider
  final themeProvider = getIt<ThemeProvider>();
  await themeProvider.loadPreferences();

  // 8) Run the app inside a guarded zone to catch any uncaught async errors
  runZonedGuarded(() {
    // Lock orientation & set system UI chrome once at startup
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    // 9) Finally launch the app with your providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          // add other providers here
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // Log any uncaught errors here
    debugPrint('Uncaught async error:\n$error\n$stack');
    // TODO: send to your error reporting service
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
        '/welcome':    (_) => const WelcomeScreen(),
        '/auth':       (_) => const AuthScreen(),
        '/home':       (_) => const HomeScreen(),
        '/settings':   (_) => const SettingsScreen(),
        '/record':     (_) => const RecordingScreen(),
        '/transcribe': (_) => const TranscriptionScreen(audioFilePath: ''),
      },
      builder: (context, child) {
        // Enforce a text‐scale clamp for accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}
