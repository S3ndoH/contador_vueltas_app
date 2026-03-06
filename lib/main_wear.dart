import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/wear/wear_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - Using the same URL/Key as the main app
  await Supabase.initialize(
    url: 'https://rwxsccdnidvihkjbapld.supabase.co',
    anonKey: 'sb_publishable_j3LDvViDYaTdDU9Mcox9zQ_wgrk8GsA',
  );

  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAPCOUNTER Wear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        visualDensity: VisualDensity.compact,
      ),
      home: const WearHomeScreen(),
    );
  }
}
