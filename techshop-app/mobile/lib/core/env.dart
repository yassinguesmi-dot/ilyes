import 'package:flutter/foundation.dart';

const String _defaultApiBaseUrl = 'http://localhost:4000/api';

String get apiBaseUrl {
  const defined = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultApiBaseUrl);

  if (defined.trim().isNotEmpty) return defined.trim();

  if (!kIsWeb) {
    return _defaultApiBaseUrl;
  }

  return _defaultApiBaseUrl;
}
