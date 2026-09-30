import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return _asMap(await _send('POST', path, body: body, token: token));
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return _asMap(await _send('PATCH', path, body: body, token: token));
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    return _asMap(await _send('GET', path, token: token));
  }

  Future<List<dynamic>> getList(String path, {String? token}) async {
    final decoded = await _send('GET', path, token: token);
    if (decoded is List) {
      return decoded;
    }
    throw ApiException('Réponse inattendue du serveur.');
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    String method = 'POST',
    String? token,
    String? fileField,
    String? filename,
    List<int>? bytes,
    List<http.MultipartFile> files = const [],
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('$_baseUrl$path'))
      ..fields.addAll(fields)
      ..files.addAll(files);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (fileField != null && filename != null && bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(fileField, bytes, filename: filename),
      );
    }
    final response = await _client.send(request);
    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw ApiException('Réponse inattendue du serveur.');
    }
    throw ApiException(readApiError(decoded));
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.send(
      http.Request(method, Uri.parse('$_baseUrl$path'))
        ..headers.addAll(headers)
        ..body = body == null ? '' : jsonEncode(body),
    );
    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(readApiError(decoded));
  }

  Map<String, dynamic> _asMap(Object? decoded) {
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw ApiException('Réponse inattendue du serveur.');
  }
}

String readApiError(Object? decoded) {
  if (decoded is Map) {
    final messages = <String>[];
    decoded.forEach((key, value) {
      if (value is List) {
        messages.add(value.join(' '));
      } else if (value != null) {
        messages.add(value.toString());
      }
    });
    if (messages.isNotEmpty) {
      return messages.join('\n');
    }
  }
  if (decoded is List && decoded.isNotEmpty) {
    return decoded.join('\n');
  }
  return 'La requête a échoué.';
}
