import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme.dart';
import '../../services/database_service.dart';
import '../../services/automated_lap_service.dart';

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

  late final AutomatedLapService _lapService;
  bool _isCalibrating = true;
  bool _isGettingLocation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lapService = AutomatedLapService(onLapDetected: _recordAutomatedLap);
  }

  Future<void> _calibrateAndStart() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });
    try {
      await _lapService.setFinishLine();
      if (!mounted) return;
      setState(() {
        _isCalibrating = false;
        _isGettingLocation = false;
      });
      _startSession();
      _lapService.startTracking();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGettingLocation = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      debugPrint("Error GPS: $e");
    }
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
    _lapService.stopTracking();
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
    double speed = (200 / (lapTime > 0 ? lapTime : 1)) * 3.6;
    _recordAutomatedLap(speed, lapTime);
  }

  void _recordAutomatedLap(double speed, double duration) {
    if (!mounted) return;
    int lapNumber = _laps.length + 1;
    
    // Feedback de UI instántaneo (Color Speed)
    setState(() {
      _laps.add(duration);
      _lastLapTime = _currentTime;
    });

    if (_trainingId != null) {
      _databaseService.addLap(
        trainingId: _trainingId!,
        lapNumber: lapNumber,
        durationSeconds: duration,
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
          body: _isCalibrating 
            ? _buildCalibrationUI(shape) 
            : _buildTrainingUI(shape),
        );
      },
    );
  }

  Widget _buildCalibrationUI(WearShape shape) {
    return Center(
      child: _isGettingLocation
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  'Buscando satélites...\nQuédate al aire libre',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _calibrateAndStart,
                  borderRadius: BorderRadius.circular(48),
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.warning, AppColors.error],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.target, color: Colors.white, size: 28),
                        SizedBox(height: 4),
                        Text(
                          'Fijar Meta Virtual',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildTrainingUI(WearShape shape) {
    return Stack(
      children: [
        // Lap Button (Almost whole screen)
        Positioned.fill(
          child: InkWell(
            onTap: _recordLap, // Mantenemos el tap manual como backup
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.activity, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'VUELTA ${_laps.length + 1}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
              (_trainingId != null && !_trainingId!.startsWith('local_'))
                  ? LucideIcons.cloud
                  : LucideIcons.cloudOff,
              color: (_trainingId != null &&
                      !_trainingId!.startsWith('local_'))
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
    );
  }
}
