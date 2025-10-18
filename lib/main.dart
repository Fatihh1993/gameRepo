import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen_v2.dart';
import 'screens/home_screen.dart';
import 'utils/theme_manager.dart';
import 'utils/language_manager.dart';
import 'services/auth_service_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CodeQuizGame());
}

class CodeQuizGame extends StatefulWidget {
  const CodeQuizGame({super.key});

  @override
  State<CodeQuizGame> createState() => _CodeQuizGameState();
}

class _CodeQuizGameState extends State<CodeQuizGame> {
  final ThemeManager _themeManager = ThemeManager();
  final LanguageManager _languageManager = LanguageManager();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_themeManager, _languageManager]),
      builder: (context, child) {
        return MaterialApp(
          title: 'Code Quiz Game',
          debugShowCheckedModeBanner: false,
          themeMode: _themeManager.themeMode,
          
          // Aydınlık Tema
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: Colors.grey[50],
            cardTheme: const CardThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          // Karanlık Tema
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardThemeData(
              elevation: 4,
              color: const Color(0xFF1E1E1E),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          home: AuthWrapper(
            themeManager: _themeManager,
            languageManager: _languageManager,
          ),
        );
      },
    );
  }
}

// Auth durumunu kontrol eden wrapper
class AuthWrapper extends StatelessWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  
  const AuthWrapper({
    super.key,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthServiceV2();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Kullanıcı giriş yapmışsa Home, yoksa Login
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(
            themeManager: themeManager,
            languageManager: languageManager,
          );
        } else {
          return LoginScreenV2(
            themeManager: themeManager,
            languageManager: languageManager,
          );
        }
      },
    );
  }
}
