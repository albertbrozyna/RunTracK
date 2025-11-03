import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';


@pragma('vm:entry-point')
class ForegroundTrackService {
  static final FlutterBackgroundService service = FlutterBackgroundService();

  // Inicjalizacja serwisu
  @pragma('vm:entry-point') // <-- jeśli wywołujesz z natywnego kodu
  static Future<void> initializeService() async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        initialNotificationTitle: "Tracking",
        initialNotificationContent: "Service is running",
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance serviceInstance) async {
    if (serviceInstance is AndroidServiceInstance) {
      serviceInstance.on('stopService').listen((event) {
        serviceInstance.stopSelf();
      });
    }

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
      );
      print("📍 Background location: ${position.latitude}, ${position.longitude}");

      // Tutaj możesz też wysyłać dane do UI:
      service.invoke('update', {
        'lat': position.latitude,
        'lng': position.longitude,
      });
    });
  }

  // Funkcja do startowania tracking’u
  @pragma('vm:entry-point') // <-- jeśli wywołujesz z natywnego kodu
  static Future<void> startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      print("⚠️ Location service is disabled");
      return;
    }

    await service.startService();
    print("▶️ Background tracking started");
  }

  // Funkcja do zatrzymywania tracking’u
  @pragma('vm:entry-point') // <-- jeśli wywołujesz z natywnego kodu
  static void stopTracking() {
    service.invoke('stopService');
    print("🛑 Background tracking stopped");
  }
}
