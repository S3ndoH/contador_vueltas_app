class TrainingSummary {
  final String trainingId;
  final String userId;
  final DateTime startedAt;
  final String? description;
  final int totalLaps;
  final double sessionAvgSpeed;
  final double maxSpeed;
  final double totalDurationSeconds;

  TrainingSummary({
    required this.trainingId,
    required this.userId,
    required this.startedAt,
    this.description,
    required this.totalLaps,
    required this.sessionAvgSpeed,
    required this.maxSpeed,
    required this.totalDurationSeconds,
  });

  factory TrainingSummary.fromMap(Map<String, dynamic> map) {
    return TrainingSummary(
      trainingId: map['training_id'],
      userId: map['user_id'],
      startedAt: DateTime.parse(map['started_at']),
      description: map['description'],
      totalLaps: map['total_laps'] ?? 0,
      sessionAvgSpeed: (map['session_avg_speed'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (map['max_speed'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds:
          (map['total_duration_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
