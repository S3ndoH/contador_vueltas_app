import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Servicio encargado de detectar el cruce por la meta usando el GPS del Galaxy Watch 4 u otros dispositivos
class AutomatedLapService {
  // Coordenadas de la línea de meta (se deben capturar al iniciar el entrenamiento)
  Position? _finishLine;
  
  // Configuración técnica
  final double detectionRadius = 8.0; // Metros de sensibilidad para la meta
  final Duration lapCooldown = const Duration(seconds: 15); // Tiempo mínimo entre vueltas
  
  DateTime? _lastLapTime;
  StreamSubscription<Position>? _positionStream;
  
  // Callback que se ejecuta cuando se cuenta una vuelta
  final Function(double speed, double duration) onLapDetected;

  AutomatedLapService({required this.onLapDetected});

  /// Define la posición actual como la línea de meta
  Future<void> setFinishLine() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Activa el GPS/Ubicación en los ajustes del reloj primero.');
    }

    // Asegurarse de que tenemos permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    try {
      _finishLine = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // 'high' suele conseguir señal más rápido que 'bestForNavigation'
        ),
      ).timeout(const Duration(seconds: 60)); // 60 segundos porque un GPS en frío tarda mucho
    } on TimeoutException {
      throw Exception('No hay señal GPS (Timeout 60s). Aléjate de edificios altos.');
    } catch (e) {
      throw Exception('Error al obtener ubicación: $e');
    }
  }

  /// Inicia el rastreo automático
  void startTracking() {
    // Configuramos el GPS para alta frecuencia (ideal para deportes de velocidad)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // Actualiza cada 2 metros
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _checkLap(position);
    });
  }

  void _checkLap(Position currentPos) {
    if (_finishLine == null) return;

    // Calculamos la distancia entre el reloj y la meta virtual
    double distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      _finishLine!.latitude,
      _finishLine!.longitude,
    );

    // Lógica de detección:
    // 1. Estar dentro del radio de la meta.
    // 2. Haber pasado suficiente tiempo desde la última vuelta (cooldown).
    if (distance <= detectionRadius) {
      final now = DateTime.now();
      
      if (_lastLapTime == null || now.difference(_lastLapTime!) > lapCooldown) {
        
        double speedKmh = currentPos.speed * 3.6; // Convertir m/s a km/h
        double duration = _lastLapTime != null 
            ? now.difference(_lastLapTime!).inMilliseconds / 1000.0 
            : 0.0;

        _lastLapTime = now;
        onLapDetected(speedKmh, duration);
      }
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _lastLapTime = null;
  }
}
