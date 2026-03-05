class Training {
  final String id;
  final String userId;
  final DateTime startedAt;
  final int trackLengthMeters;
  final String? description;

  Training({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.trackLengthMeters,
    this.description,
  });

  factory Training.fromMap(Map<String, dynamic> map) {
    return Training(
      id: map['id'],
      userId: map['user_id'],
      startedAt: DateTime.parse(map['started_at']),
      trackLengthMeters: map['track_length_meters'] ?? 200,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'track_length_meters': trackLengthMeters,
      'description': description,
    };
  }
}
