class Lap {
  final String id;
  final String trainingId;
  final int lapNumber;
  final double averageSpeed;
  final double durationSeconds;
  final DateTime createdAt;

  Lap({
    required this.id,
    required this.trainingId,
    required this.lapNumber,
    required this.averageSpeed,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory Lap.fromMap(Map<String, dynamic> map) {
    return Lap(
      id: map['id'],
      trainingId: map['training_id'],
      lapNumber: map['lap_number'],
      averageSpeed: (map['average_speed'] as num).toDouble(),
      durationSeconds: (map['duration_seconds'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'training_id': trainingId,
      'lap_number': lapNumber,
      'average_speed': averageSpeed,
      'duration_seconds': durationSeconds,
    };
  }
}
