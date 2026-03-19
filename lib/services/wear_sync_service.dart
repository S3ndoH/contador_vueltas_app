import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class WearSyncService {
  static const _channel = MethodChannel('com.example.lapcounter/wear_sync');
  
  static final WearSyncService _instance = WearSyncService._internal();
  factory WearSyncService() => _instance;
  WearSyncService._internal();

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenReceived => _tokenController.stream;

  void init() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onTokenReceived':
        final token = call.arguments['token'] as String?;
        if (token != null) {
          _tokenController.add(token);
        }
        break;
    }
  }

  Future<bool> sendTokenToWatch(String token) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendTokenToWatch', {'token': token});
      return result ?? false;
    } on PlatformException catch (e) {
      print("Error sending token to watch: ${e.message}");
      return false;
    }
  }

  /// Sends the current session token if available
  Future<bool> syncCurrentSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return await sendTokenToWatch(session.accessToken);
    }
    return false;
  }
}
