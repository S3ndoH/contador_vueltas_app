import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/training_summary.dart';
import '../models/lap.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get recent trainings from the view
  Future<List<TrainingSummary>> getRecentTrainings() async {
    try {
      final response = await _client
          .from('training_summaries')
          .select()
          .order('started_at', ascending: false);

      return (response as List)
          .map((data) => TrainingSummary.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recent trainings: $e');
      return [];
    }
  }

  // Get laps for a specific training
  Future<List<Lap>> getTrainingLaps(String trainingId) async {
    try {
      final response = await _client
          .from('laps')
          .select()
          .eq('training_id', trainingId)
          .order('lap_number', ascending: true);

      return (response as List).map((data) => Lap.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error fetching training laps: $e');
      return [];
    }
  }

  // Get stats from RPC
  Future<Map<String, dynamic>?> getTrainingStats(String trainingId) async {
    try {
      final response = await _client.rpc(
        'get_training_stats',
        params: {'t_id': trainingId},
      );
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching training stats: $e');
      return null;
    }
  }

  // Create a new training session
  Future<String?> createTraining({
    int trackLengthMeters = 200,
    String? description,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('trainings')
          .insert({
            'user_id': userId,
            'track_length_meters': trackLengthMeters,
            'description': description,
            'started_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating training: $e');
      return null;
    }
  }

  // Add a lap to a training session
  Future<bool> addLap({
    required String trainingId,
    required int lapNumber,
    required double durationSeconds,
    required double averageSpeed,
  }) async {
    try {
      await _client.from('laps').insert({
        'training_id': trainingId,
        'lap_number': lapNumber,
        'duration_seconds': durationSeconds,
        'average_speed': averageSpeed,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding lap: $e');
      return false;
    }
  }
}
