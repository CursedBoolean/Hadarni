import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'views/constants/app_colors.dart';
import 'views/auth/welcome_screen.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HadarniApp());
}

class HadarniApp extends StatelessWidget {
  const HadarniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>(
      create: (_) => AuthController(),
      child: MaterialApp(
        title: 'هدّرني',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.deepNavy,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}

/// Listens to Firebase auth state and routes to the appropriate screen.
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
        // User is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // User is not logged in
        return const WelcomeScreen();
      },
    );
  }
}
