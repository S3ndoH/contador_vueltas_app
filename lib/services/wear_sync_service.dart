import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class WearSyncService {
  static const _channel = MethodChannel('com.example.lapcounter/wear_sync');
  
  static final WearSyncService _instance = WearSyncService._internal();
  factory WearSyncService() => _instance;
  WearSyncService._internal();

  final _tokenController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get onTokenReceived => _tokenController.stream;

  // Track last received timestamp to avoid duplicate processing from hybrid channels
  int _lastTokenTimestamp = 0;

  void init() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onTokenReceived':
        final accessToken = call.arguments['accessToken'] as String?;
        final refreshToken = call.arguments['refreshToken'] as String?;
        final timestamp = call.arguments['timestamp'] as int? ?? 0;

        // Skip if this is a duplicated message (same tokens arrived via Data and Message client)
        if (timestamp != 0 && timestamp <= _lastTokenTimestamp) return;
        _lastTokenTimestamp = timestamp;

        if (accessToken != null && refreshToken != null) {
          print("WearSyncService: Token recibido de la capa nativa (ts: $timestamp)");
          _tokenController.add({
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          });
        }
        break;
    }
  }

  Future<bool> sendTokenToWatch(String accessToken, String refreshToken) async {
    try {
      print("WearSyncService: Enviando tokens al reloj (híbrido)...");
      final result = await _channel.invokeMethod<bool>('sendTokenToWatch', {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
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
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final accessToken = session.accessToken;
        final refreshToken = session.refreshToken;
        
        if (refreshToken != null) {
          print("WearSyncService: Sincronizando tokens directamente...");
          return await sendTokenToWatch(accessToken, refreshToken);
        }
      } else {
        print("WearSyncService: No hay sesión activa para sincronizar.");
      }
    } catch (e) {
      print("WearSyncService: Error en syncCurrentSession: $e");
    }
    return false;
  }
}
