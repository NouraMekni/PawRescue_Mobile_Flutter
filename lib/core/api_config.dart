import 'package:flutter/foundation.dart';

String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Phone on the same Wi-Fi as this PC. The emulator address is 10.0.2.2.
    return 'http://192.168.100.135:8000';
  }
  return 'http://127.0.0.1:8000';
}
