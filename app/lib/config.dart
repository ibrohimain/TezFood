import 'package:flutter/foundation.dart';

class ApiConfig {
  static const defined = String.fromEnvironment('API_BASE');

  static String get base {
    if (defined.isNotEmpty) return _trim(defined);
    if (kIsWeb) {
      final uri = Uri.base;
      // Production: API va web bir origin (masalan :8096).
      final local = uri.host == 'localhost' || uri.host == '127.0.0.1';
      if (!local) return uri.origin;
      if (uri.port == 8080 || uri.port == 80 || uri.port == 443) {
        return uri.origin;
      }
    }
    return 'http://127.0.0.1:8080';
  }

  static String _trim(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String? imageUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    final name = fileName.split('/').last;
    return '$base/uploads/$name';
  }
}
