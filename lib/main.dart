import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth;
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/report_status_screen.dart';
import 'screens/social_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const CivicConnectApp());
}

class CivicConnectApp extends StatelessWidget {
  const CivicConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => auth.AuthProvider()..initialize(),),
      ],
      child: const _AppWithRouter(),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _initializeRouter();
  }

  void _initializeRouter() {
    _router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        try {
          final authProvider = context.read<auth.AuthProvider>();
          final loggedIn = authProvider.user != null;
          final isLoggingIn = state.matchedLocation == '/login';
          if (!authProvider.initialized) return null;
          if (!loggedIn) {
            return isLoggingIn ? null : '/login';
          }
          if (isLoggingIn) return '/';
          return null;
        } catch (e) {
          debugPrint('Router redirect error: $e');
          return '/login';
        }
      },
      routes: [
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/', builder: (c, s) => const MainScreen()),
        GoRoute(path: '/report', builder: (c, s) => const ReportScreen()),
        GoRoute(path: '/my-reports', builder: (context, state) => const MyReportsScreen()),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        GoRoute(
          path: '/report-status/:reportId',
          builder: (context, state) {
            final reportId = state.pathParameters['reportId']!;
            return ReportStatusScreen(reportId: reportId);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A8A),
        brightness: Brightness.light,
      ).copyWith(
        surface: Colors.white,
        onSurface: Colors.black87,
        primary: const Color(0xFF1E3A8A), // Dark blue
        secondary: const Color(0xFFEA580C), // Orange accent
        tertiary: const Color(0xFF2C3E50),
        outline: const Color(0xFFE5E7EB),
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Color(0x1A000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x332196F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        labelStyle: const TextStyle(color: Color(0xFF374151)),
      ),
    );
    final authProvider = context.watch<auth.AuthProvider>();
    return MaterialApp.router(
      title: 'UrbanVoice',
      theme: theme,
      routerConfig: _router,
      builder: (context, child) {
        if (!authProvider.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child!;
      },
    );
  }
}
