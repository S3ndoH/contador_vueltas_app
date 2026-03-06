import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme.dart';
import 'wear_training.dart';

class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.roller_skating,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'LAPCOUNTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WearTrainingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(LucideIcons.play, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
