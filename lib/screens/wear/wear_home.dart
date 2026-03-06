import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../../services/database_service.dart';
import 'wear_training.dart';
import 'wear_login.dart';

class WearHomeScreen extends StatefulWidget {
  const WearHomeScreen({super.key});

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WearHomeScreenState extends State<WearHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _updatePendingCount();
    // Start monitoring connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        _handleAutoSync();
      }
    });

    // Initial sync check
    _handleAutoSync();
  }

  Future<void> _updatePendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_training_sync');
    if (pendingJson != null) {
      final List<dynamic> pendingList = jsonDecode(pendingJson);
      if (mounted) {
        setState(() => _pendingCount = pendingList.length);
      }
    } else {
      if (mounted) {
        setState(() => _pendingCount = 0);
      }
    }
  }

  Future<void> _handleAutoSync() async {
    if (_isSyncing || !DatabaseService.isLoggedIn) {
      _updatePendingCount();
      return;
    }

    setState(() => _isSyncing = true);
    final result = await _databaseService.syncPendingData();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _pendingCount = result.totalPending;
      });

      if (result.syncedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.syncedCount} entrenamientos subidos',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSynced = DatabaseService.isLoggedIn;

    return WatchShape(
      builder: (context, shape, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
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
                    Text(
                      isSynced ? 'CONECTADO' : 'MODO LOCAL',
                      style: TextStyle(
                        color: isSynced ? AppColors.success : AppColors.error,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pendingCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$_pendingCount PENDIENTE${_pendingCount > 1 ? 'S' : ''}',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
              // Settings/Login Button
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isSynced ? LucideIcons.userCheck : LucideIcons.userX,
                    color: isSynced ? AppColors.success : Colors.white54,
                    size: 16,
                  ),
                  onPressed: () {
                    if (!isSynced) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WearLoginScreen(),
                        ),
                      );
                    } else {
                      // Show status or logout option
                      _showStatusDialog();
                    }
                  },
                ),
              ),
              // Sync Indicator
              if (_isSyncing)
                const Positioned(
                  top: 10,
                  left: 10,
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Sincronización', style: TextStyle(fontSize: 14)),
        content: const Text(
          'Tu cuenta está vinculada. Tus entrenamientos se subirán automáticamente.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pop(context);
                _updatePendingCount();
                setState(() {});
              }
            },
            child: const Text(
              'CERRAR SESIÓN',
              style: TextStyle(color: AppColors.error, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
