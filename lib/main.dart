import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
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

// Global key for navigator to use in error handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Catch Flutter errors and log them
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Here you could add custom error logging
  };
  
  // Catch async errors that aren't caught by Flutter's error zone
  runZonedGuarded(() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style for a more immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    // Initialize services in parallel for faster startup
    await Future.wait([
      FirebaseService.initialize(),
      dotenv.load(fileName: ".env"),
      // Add other async initialization tasks here
    ]);

    // Configure dependency injection
    await configureDependencies();

    // Get theme provider and initialize it
    final themeProvider = getIt<ThemeProvider>();
    themeProvider.initialize(); // Initialize with default values
    await themeProvider.loadPreferences();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          // Add more providers here
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stackTrace) {
    // Handle any errors not caught by Flutter's error zone
    debugPrint('Uncaught error: $error');
    debugPrint(stackTrace.toString());
    // Here you could add custom error reporting
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'CAIPO Assistant',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getThemeData(false),
      darkTheme: themeProvider.getThemeData(true),
      themeMode: themeProvider.themeMode,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/record': (context) => const RecordingScreen(),
        '/transcription': (context) => const TranscriptionScreen(audioFilePath: ""),
      },
      builder: (context, child) {
        // Apply font scaling for accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3)),
          ),
          child: child!,
        );
      },
    );
  }
} 