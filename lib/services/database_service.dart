import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_summary.dart';
import '../models/lap.dart';

// Result class for synchronization
final class SyncResult {
  final int syncedCount;
  final int failedCount;
  final int totalPending;

  SyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.totalPending,
  });
}

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static User? get currentUser => Supabase.instance.client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Get recent trainings from the view
  Future<List<TrainingSummary>> getRecentTrainings({int limit = 20}) async {
    try {
      final response = await _client
          .from('training_summaries')
          .select()
          .order('started_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => TrainingSummary.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recent trainings: $e');
      return [];
    }
  }

  // Get trainings for a specific date
  Future<List<TrainingSummary>> getTrainingsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

      final response = await _client
          .from('training_summaries')
          .select()
          .gte('started_at', startOfDay)
          .lte('started_at', endOfDay)
          .order('started_at', ascending: false);

      return (response as List).map((data) => TrainingSummary.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error fetching trainings by date: $e');
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
    final startTime = DateTime.now().toUtc().toIso8601String();
    final userId = _client.auth.currentUser?.id;

    try {
      if (userId == null) {
        // If not logged in, we MUST save locally with a temp ID
        final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        await savePendingTraining({
          'tempId': tempId,
          'track_length_meters': trackLengthMeters,
          'description': description,
          'started_at': startTime,
          'laps': [],
        });
        return tempId;
      }

      final response = await _client
          .from('trainings')
          .insert({
            'user_id': userId,
            'track_length_meters': trackLengthMeters,
            'description': description,
            'started_at': startTime,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating training (falling back to local): $e');
      // If error (connectivity), save locally with a temp ID
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await savePendingTraining({
        'tempId': tempId,
        'track_length_meters': trackLengthMeters,
        'description': description,
        'started_at': startTime,
        'laps': [],
      });
      return tempId;
    }
  }

  // --- Offline Sync Logic ---

  static const String _pendingSyncKey = 'pending_training_sync';

  // Save a training to local storage if offline
  Future<void> savePendingTraining(Map<String, dynamic> trainingData) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingSyncKey);
    List<dynamic> pendingList = pendingJson != null
        ? jsonDecode(pendingJson)
        : [];

    pendingList.add(trainingData);
    await prefs.setString(_pendingSyncKey, jsonEncode(pendingList));
    debugPrint('Training saved to local sync queue');
  }

  // Add a lap to a pending training in local storage
  Future<void> addLapToPending(
    String tempId,
    Map<String, dynamic> lapData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingSyncKey);
    if (pendingJson == null) return;

    List<dynamic> pendingList = jsonDecode(pendingJson);
    for (var training in pendingList) {
      if (training['tempId'] == tempId) {
        training['laps'] ??= [];
        training['laps'].add(lapData);
        break;
      }
    }
    await prefs.setString(_pendingSyncKey, jsonEncode(pendingList));
    debugPrint('Lap added to local sync queue (Training: $tempId)');
  }

  // Sync all pending data to Supabase
  Future<SyncResult> syncPendingData() async {
    final userId = currentUser?.id;
    if (userId == null) {
      return SyncResult(syncedCount: 0, failedCount: 0, totalPending: 0);
    }

    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingSyncKey);
    if (pendingJson == null) {
      return SyncResult(syncedCount: 0, failedCount: 0, totalPending: 0);
    }

    List<dynamic> pendingList = jsonDecode(pendingJson);
    if (pendingList.isEmpty) {
      return SyncResult(syncedCount: 0, failedCount: 0, totalPending: 0);
    }

    debugPrint('Starting sync of ${pendingList.length} pending sessions...');
    List<dynamic> remaining = [];
    int success = 0;

    for (var training in pendingList) {
      try {
        // 1. Create the training in Supabase
        final tResponse = await _client
            .from('trainings')
            .insert({
              'user_id': userId,
              'track_length_meters': training['track_length_meters'],
              'description': training['description'],
              'started_at': training['started_at'],
            })
            .select('id')
            .single();

        String realId = tResponse['id'];

        // 2. Add all its laps
        if (training['laps'] != null) {
          for (var lap in training['laps']) {
            await _client.from('laps').insert({
              'training_id': realId,
              'lap_number': lap['lap_number'],
              'duration_seconds': lap['duration_seconds'],
              'average_speed': lap['average_speed'],
            });
          }
        }
        success++;
        debugPrint('Session synchronized successfully!');
      } catch (e) {
        debugPrint('Failed to sync session, keeping it in queue: $e');
        remaining.add(training);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_pendingSyncKey);
    } else {
      await prefs.setString(_pendingSyncKey, jsonEncode(remaining));
    }

    return SyncResult(
      syncedCount: success,
      failedCount: remaining.length,
      totalPending: remaining.length,
    );
  }

  // Add a lap to a training session
  Future<bool> addLap({
    required String trainingId,
    required int lapNumber,
    required double durationSeconds,
    required double averageSpeed,
    String? tempId, // Used for local queue fallback
  }) async {
    try {
      // If it's a real GUID, it's a Supabase ID
      if (!trainingId.startsWith('local_')) {
        await _client.from('laps').insert({
          'training_id': trainingId,
          'lap_number': lapNumber,
          'duration_seconds': durationSeconds,
          'average_speed': averageSpeed,
        });
        return true;
      } else {
        // Otherwise, save to local queue
        await addLapToPending(trainingId, {
          'lap_number': lapNumber,
          'duration_seconds': durationSeconds,
          'average_speed': averageSpeed,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error adding lap (falling back to local): $e');
      if (tempId != null) {
        await addLapToPending(tempId, {
          'lap_number': lapNumber,
          'duration_seconds': durationSeconds,
          'average_speed': averageSpeed,
        });
      }
      return false;
    }
  }
}
