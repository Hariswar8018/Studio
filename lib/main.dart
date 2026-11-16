import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/app_info_onboarding_screen.dart';
import 'screens/onboarding/jlpt_level_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool useFirebase = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    useFirebase = true;
    debugPrint('🔥 [Firebase] Initialized successfully');
  } catch (e) {
    debugPrint('⚠️ [Firebase] Initialization failed: $e. Running in local/offline mode.');
  }

  final themeService = ThemeService();
  await themeService.init();

  final ttsService = TtsService();
  await ttsService.init();

  final databaseService = DatabaseService(useFirebase: useFirebase);
  await databaseService.init();

  final authService = AuthService(
    useFirebase: useFirebase,
    databaseService: databaseService,
  );

  final adService = AdService(useFirebase: useFirebase);
  final iapService = IapService(
    useFirebase: useFirebase,
    authService: authService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: ttsService),
        ChangeNotifierProvider.value(value: databaseService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: adService),
        ChangeNotifierProvider.value(value: iapService),
      ],
      child: const GrammarApp(),
    ),
  );
}

class GrammarApp extends StatelessWidget {
  const GrammarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6366F1),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.fredokaTextTheme(ThemeData.light().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6366F1),
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      textTheme: GoogleFonts.fredokaTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'LangNova Japanese Language',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeService.themeMode,
      home: const SplashScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }

    // Show beautiful onboarding for first-time entry or after logout
    if (!db.isOnboardingCompleted) {
      return const AppInfoOnboardingScreen();
    }

    if (auth.currentUser != null) {
      if (!db.hasSelectedLevel) {
        return const JlptLevelSelectionScreen();
      }
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
