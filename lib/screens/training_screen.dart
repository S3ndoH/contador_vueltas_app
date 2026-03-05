import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/database_service.dart';

class TrainingScreen extends StatefulWidget {
  final int trackLengthMeters;
  const TrainingScreen({super.key, this.trackLengthMeters = 200});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _databaseService = DatabaseService();
  String? _trainingId;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  final List<double> _laps = [];
  double _lastLapTime = 0;
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    final id = await _databaseService.createTraining(
      trackLengthMeters: widget.trackLengthMeters,
      description: 'Sesión de Entrenamiento',
    );

    if (mounted) {
      if (id != null) {
        setState(() {
          _trainingId = id;
          _stopwatch.start();
          _startTimer();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión en Supabase')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(double seconds) {
    int minutes = (seconds / 60).floor();
    int secs = (seconds % 60).floor();
    int milliseconds = ((seconds - seconds.floor()) * 100).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  double get _currentTime => _stopwatch.elapsedMilliseconds / 1000.0;

  void _recordLap() async {
    if (_trainingId == null || _isSaving) return;

    double lapTime = _currentTime - _lastLapTime;
    int lapNumber = _laps.length + 1;
    double speed = (widget.trackLengthMeters / lapTime) * 3.6; // km/h

    setState(() {
      _laps.add(lapTime);
      _lastLapTime = _currentTime;
    });

    await _databaseService.addLap(
      trainingId: _trainingId!,
      lapNumber: lapNumber,
      durationSeconds: lapTime,
      averageSpeed: speed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildLapsList()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _confirmExit(),
                icon: const Icon(LucideIcons.x, color: Colors.white),
              ),
              const Text(
                'Sesión en Vivo',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            _formatTime(_currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'VUELTA ${_laps.length + 1}',
            style: const TextStyle(
              color: AppColors.primary,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLapsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: _laps.isEmpty
          ? const Center(
              child: Text(
                'Aún no hay vueltas',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _laps.length,
              reverse: true,
              separatorBuilder: (_, _) =>
                  Divider(color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                int reversedIndex = _laps.length - 1 - index;
                double lapTime = _laps[reversedIndex];
                double speed = (widget.trackLengthMeters / lapTime) * 3.6;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '#${reversedIndex + 1}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        _formatTime(lapTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${speed.toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _recordLap,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'LAP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            LucideIcons.flag,
            AppColors.error,
            () => _finishSession(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('¿Cancelar Sesión?'),
        content: const Text(
          'Los datos de esta sesión no se guardarán permanentemente si sales ahora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'SALIR',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _finishSession() {
    _stopwatch.stop();
    _timer?.cancel();
    Navigator.pop(context, true); // Return true to indicate session finished
  }
}
