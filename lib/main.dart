import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/training_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/wear/wear_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rwxsccdnidvihkjbapld.supabase.co',
    anonKey: 'sb_publishable_j3LDvViDYaTdDU9Mcox9zQ_wgrk8GsA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LAPCOUNTER',
      theme: appTheme,
      home: _getInitialScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/training': (context) => const TrainingScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/wear_home': (context) => const WearHomeScreen(),
      },
    );
  }

  Widget _getInitialScreen() {
    return Builder(
      builder: (context) {
        final double width = MediaQuery.of(context).size.width;
        // Typical Wear OS screens are small (often < 300dp)
        if (width > 0 && width < 300) {
          return const WearHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
