import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
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

  // v13/v15: Detect if it's a watch with high redundancy
  bool isWatch = false;
  try {
    const channel = MethodChannel('com.example.lapcounter/wear_sync');
    final bool? nativeIsWatch = await channel.invokeMethod<bool>('isWatch');
    isWatch = nativeIsWatch ?? false;
    debugPrint("main: Native isWatch detection: $isWatch");
  } catch (e) {
    debugPrint("main: Error in native detection: $e");
  }

  // v15: Fallback detection via platform/device info is hard in main(), 
  // but we can pass a 'forced' flag if we want. For now, rely on native channel 
  // and explicit initialization options.

  // INITIALIZE SUPABASE
  // v15: HARD DISABLE autoRefreshToken on Watch to protect Phone session.
  await Supabase.initialize(
    url: 'https://rwxsccdnidvihkjbapld.supabase.co',
    anonKey: 'sb_publishable_j3LDvViDYaTdDU9Mcox9zQ_wgrk8GsA',
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: !isWatch, 
    ),
  );

  // INITIALIZE WEAR SYNC
  final syncService = WearSyncService();
  syncService.init();

  // v14: Listen for session updates on the Phone to push them to the watch automatically
  if (!isWatch) {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (session != null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed)) {
        debugPrint("main: Session updated ($event), mirroring to watch (v14)...");
        // v14: Pass the userId along with accessToken
        syncService.syncTokens(session.accessToken, session.user.id);
      }
    });
  }

  runApp(MyApp(isWatchPreDetected: true, isWatchValue: isWatch));
}

class MyApp extends StatefulWidget {
  final bool isWatchPreDetected;
  final bool isWatchValue;
  const MyApp({super.key, this.isWatchPreDetected = false, this.isWatchValue = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isWear;

  @override
  void initState() {
    super.initState();
    if (widget.isWatchPreDetected) {
      _isWear = widget.isWatchValue;
    }
  }

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
