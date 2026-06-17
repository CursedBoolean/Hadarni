import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hadarni/views/auth/additional_info_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/progress_controller.dart';
import 'services/whisper_server_manager.dart';
import 'views/constants/app_colors.dart';
import 'views/auth/welcome_screen.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create the WhisperServerManager and immediately start a health check.
  // This runs in the background — the UI shows a banner if the server is down.
  final whisperManager = WhisperServerManager();
  whisperManager.checkServerHealth(); // fire-and-forget

  runApp(HadarniApp(whisperManager: whisperManager));
}

class HadarniApp extends StatelessWidget {
  final WhisperServerManager whisperManager;

  const HadarniApp({super.key, required this.whisperManager});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
        ChangeNotifierProvider<ProgressController>(
          create: (_) => ProgressController(),
        ),
        // Expose the WhisperServerManager so any screen can react to server status
        ChangeNotifierProvider<WhisperServerManager>.value(
          value: whisperManager,
        ),
      ],
      child: MaterialApp(
        title: 'هدّرني',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.deepNavy,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.harmattan().fontFamily,
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const AdditionalInfoScreen(),
      ),
    );
  }
}

/// Listens to Firebase auth state and routes to the appropriate screen.
///
/// When a user is authenticated, automatically loads their streak progress
/// from Firestore before showing the home screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still determining auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.deepNavy,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.warmOrange),
            ),
          );
        }
        // User is logged in — load their progress
        if (snapshot.hasData) {
          // Trigger progress load (safe to call multiple times; no-ops if
          // already loaded for the same user).
          context.read<ProgressController>().loadProgress();
          return const HomeScreen();
        }
        // User is not logged in — reset progress state
        context.read<ProgressController>().reset();
        return const WelcomeScreen();
      },
    );
  }
}
