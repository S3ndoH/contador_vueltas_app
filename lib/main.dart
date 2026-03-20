import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/challenges_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/training_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wear/wear_home.dart';
import 'services/wear_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rwxsccdnidvihkjbapld.supabase.co',
    anonKey: 'sb_publishable_j3LDvViDYaTdDU9Mcox9zQ_wgrk8GsA',
  );

  // INITIALIZE WEAR SYNC
  WearSyncService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isWear;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LAPCOUNTER',
      theme: appTheme,
      home: _isWear == null
          ? DeviceDetectionSplash(
              onDetected: (isWear) {
                setState(() => _isWear = isWear);
              },
            )
          : _getInitialScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/training': (context) => const TrainingScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/challenges': (context) => const ChallengesScreen(),
        '/wear_home': (context) => const WearHomeScreen(),
      },
    );
  }

  Widget _getInitialScreen() {
    final session = Supabase.instance.client.auth.currentSession;
    if (_isWear == true) {
      // Allow WearHomeScreen even without a session to support "MODO LOCAL"
      return const WearHomeScreen();
    } else {
      // ON PHONE: If we have a session, try to sync it silently to the watch
      if (session != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WearSyncService().syncCurrentSession();
        });
        return const HomeScreen();
      }
      return const LoginScreen();
    }
  }
}

class DeviceDetectionSplash extends StatefulWidget {
  final Function(bool) onDetected;

  const DeviceDetectionSplash({super.key, required this.onDetected});

  @override
  State<DeviceDetectionSplash> createState() => _DeviceDetectionSplashState();
}

class _DeviceDetectionSplashState extends State<DeviceDetectionSplash> {
  bool? _isWear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isWear == null && constraints.maxWidth > 0) {
            final isWear = constraints.maxWidth < 330;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isWear == null) {
                setState(() => _isWear = isWear);
                widget.onDetected(isWear);
              }
            });
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }
}
