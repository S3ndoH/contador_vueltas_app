import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme.dart';
import '../../services/database_service.dart';

class WearTrainingScreen extends StatefulWidget {
  const WearTrainingScreen({super.key});

  @override
  State<WearTrainingScreen> createState() => _WearTrainingScreenState();
}

class _WearTrainingScreenState extends State<WearTrainingScreen> {
  final _databaseService = DatabaseService();
  String? _trainingId;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<double> _laps = [];
  double _lastLapTime = 0;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    // Iniciar cronómetro localmente de inmediato para mejor UX
    setState(() {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {});
      });
    });

    final id = await _databaseService.createTraining(
      trackLengthMeters: 200,
      description: 'Sesión Watch',
    );

    if (mounted) {
      setState(() {
        _trainingId = id; // Could be real or local_ timestamp
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(double seconds) {
    int minutes = (seconds / 60).floor();
    int secs = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get _currentTime => _stopwatch.elapsedMilliseconds / 1000.0;

  void _recordLap() async {
    double lapTime = _currentTime - _lastLapTime;
    int lapNumber = _laps.length + 1;
    double speed = (200 / (lapTime > 0 ? lapTime : 1)) * 3.6;

    setState(() {
      _laps.add(lapTime);
      _lastLapTime = _currentTime;
    });

    if (_trainingId != null) {
      _databaseService.addLap(
        trainingId: _trainingId!,
        lapNumber: lapNumber,
        durationSeconds: lapTime,
        averageSpeed: speed,
        tempId: _trainingId!, // Fallback for local queue
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Lap Button (Almost whole screen)
              Positioned.fill(
                child: InkWell(
                  onTap: _recordLap,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_currentTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'VUELTA ${_laps.length + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Status Indicator (Top)
              Positioned(
                top: shape == WearShape.round ? 12 : 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(
                    _trainingId != null
                        ? LucideIcons.cloud
                        : LucideIcons.cloudOff,
                    color: _trainingId != null
                        ? AppColors.success
                        : AppColors.error,
                    size: 14,
                  ),
                ),
              ),
              // Finish Button (Small, at bottom)
              Positioned(
                bottom: shape == WearShape.round ? 10 : 4,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.check,
                      color: AppColors.success,
                    ),
                    iconSize: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
