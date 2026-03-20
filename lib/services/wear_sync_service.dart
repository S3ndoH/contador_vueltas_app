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
          final timestamp = call.arguments['timestamp'] as int? ?? 0;

          if (accessToken == null || refreshToken == null) return;

          // Deduplicación persistente por timestamp
          final prefs = await SharedPreferences.getInstance();
          final lastTs = prefs.getInt('last_wear_sync_ts') ?? 0;

          if (timestamp != 0 && timestamp <= lastTs) {
            debugPrint("WearSyncService: Ignorando mensaje antiguo (ts: $timestamp, last: $lastTs)");
            return;
          }
          
          await prefs.setInt('last_wear_sync_ts', timestamp);

          debugPrint("WearSyncService: Nuevo token recibido (ts: $timestamp)");
          _tokenController.add({
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          });
          break;
      }
    } catch (e) {
      debugPrint("WearSyncService: Error en _handleMethod: $e");
    }
  }

  Future<bool> sendTokenToWatch(String accessToken, String refreshToken) async {
    try {
      print("WearSyncService: Enviando tokens al reloj (híbrido)...");
      final result = await _channel.invokeMethod<bool>('sendTokenToWatch', {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      }).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint("WearSyncService: Timeout al sincronizar con el reloj.");
        return false;
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print("WearSyncService: Error fatal en canal nativo: ${e.message}");
      return false;
    }
  }

  /// Sends the current session tokens if available
  Future<bool> syncCurrentSession() async {
    try {
      // FIX (v9): Force session refresh on the phone to get a brand new, UNUSED refresh token.
      // Supabase refresh tokens are one-time use (rotation), so if the phone already used it, 
      // the watch will fail with 400 unless we get a fresh one.
      debugPrint("WearSyncService: Refrescando sesión antes de enviar al reloj...");
      await Supabase.instance.client.auth.refreshSession();
      
      // Pequeña pausa para asegurar que el estado de Supabase sea consistente
      await Future.delayed(const Duration(milliseconds: 200));

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final accessToken = session.accessToken;
        final refreshToken = session.refreshToken;
        
        if (refreshToken != null) {
          debugPrint("WearSyncService: Enviando tokens frescos al reloj...");
          final success = await sendTokenToWatch(accessToken, refreshToken);
          debugPrint("WearSyncService: Resultado del envío: $success");
          return success;
        }
      } else {
        debugPrint("WearSyncService: No hay sesión activa tras el refresco.");
      }
    } catch (e) {
      debugPrint("WearSyncService: Error en syncCurrentSession: $e");
    }
    return false;
  }
}
