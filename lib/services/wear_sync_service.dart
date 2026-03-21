import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class WearSyncService {
  static const _channel = MethodChannel('com.example.lapcounter/wear_sync');
  
  static final WearSyncService _instance = WearSyncService._internal();
  factory WearSyncService() => _instance;
  WearSyncService._internal();

  final _tokenController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get onTokenReceived => _tokenController.stream;


  void init() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  /// Clears the synced token from the Data Layer to prevent it from being
  /// picked up again (e.g., after a logout).
  Future<void> clearSyncedToken() async {
    try {
      await _channel.invokeMethod('clearAuthData');
      debugPrint("WearSyncService: Token del Data Layer limpiado.");
    } catch (e) {
      debugPrint("WearSyncService: Error limpiando token: $e");
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onTokenReceived':
          final accessToken = call.arguments['accessToken'] as String?;
          final refreshToken = call.arguments['refreshToken'] as String?;
          final mirrorPayload = call.arguments['mirrorPayload'] as String?;
          final timestamp = call.arguments['timestamp'] as int? ?? 0;

          // v15: Redundancy check. Allow sync if timestamp is new OR if we're currently LOGGED OUT.
          // This fixes the "cannot re-sync without logout on phone" issue.
          final prefs = await SharedPreferences.getInstance();
          final lastTs = prefs.getInt('last_wear_sync_ts') ?? 0;
          final isLoggedOut = Supabase.instance.client.auth.currentSession == null;
          
          if (timestamp != 0 && timestamp <= lastTs && !isLoggedOut) {
            debugPrint("WearSyncService: Ignorando mensaje duplicado/antiguo (ts: $timestamp, last: $lastTs)");
            return;
          }
          
          await prefs.setInt('last_wear_sync_ts', timestamp);

          debugPrint("WearSyncService: Nuevo token recibido (ts: $timestamp)");
          _tokenController.add({
            'accessToken': accessToken ?? "",
            'refreshToken': refreshToken ?? "",
            'mirrorPayload': mirrorPayload ?? "",
          });
          break;
      }
    } catch (e) {
      debugPrint("WearSyncService: Error en _handleMethod: $e");
    }
  }

  Future<bool> sendTokenToWatch(String accessToken, String refreshToken) async {
    try {
      debugPrint("WearSyncService: Enviando tokens al reloj (híbrido)...");
      final result = await _channel.invokeMethod<bool>('sendTokenToWatch', {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      }).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint("WearSyncService: Timeout al sincronizar con el reloj.");
        return false;
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("WearSyncService: Error fatal en canal nativo: ${e.message}");
      return false;
    }
  }

  /// Sends the provided accessToken to the watch as a "Passive Mirror".
  /// v14: We ONLY send the accessToken and user ID to prevent the watch
  /// from consuming the refreshToken and invalidating the phone's session.
  Future<bool> syncTokens(String accessToken, String userId) async {
    debugPrint("WearSyncService: Enviando Mirror Token al reloj (v15)...");
    
    // We send a combined payload: "v14:userId|accessToken"
    final payload = "v14:$userId|$accessToken";
    
    // v15 fix: Key must be 'mirrorPayload' to match MainActivity.kt
    final success = await _channel.invokeMethod<bool>('sendMirrorToken', {
      'mirrorPayload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    debugPrint("WearSyncService: Resultado del envío Mirror: $success");
    return success ?? false;
  }

  /// Sends the current active session to the watch as a Mirror.
  Future<bool> syncCurrentSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint("WearSyncService: Sincronización manual iniciada (v15)...");
        return await syncTokens(session.accessToken, session.user.id);
      } else {
        debugPrint("WearSyncService: No hay sesión activa para sincronizar.");
      }
    } catch (e) {
      debugPrint("WearSyncService: Error en syncCurrentSession: $e");
    }
    return false;
  }
}
