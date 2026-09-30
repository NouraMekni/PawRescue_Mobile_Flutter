import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/api_client.dart';

class ReportsApi {
  ReportsApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list(String token) async {
    final rows = await _client.getList('/api/reports/', token: token);
    return [
      for (final row in rows)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  Future<Map<String, dynamic>> create({
    required String token,
    required String type,
    required double latitude,
    required double longitude,
    String description = '',
    String addressText = '',
    String estimatedPresence = '',
    String? severity,
    required String photoName,
    required List<int> photoBytes,
  }) {
    final fields = <String, String>{
      'type': type,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'description': description,
      'address_text': addressText,
      'estimated_presence': estimatedPresence,
    };
    if (severity != null && severity.isNotEmpty) {
      fields['severity'] = severity;
    }
    return _client.postMultipart(
      '/api/reports/',
      token: token,
      fields: fields,
      files: [
        http.MultipartFile.fromBytes(
          'photos',
          photoBytes,
          filename: photoName,
          contentType: _imageType(photoName),
        ),
      ],
    );
  }
}

MediaType _imageType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) {
    return MediaType('image', 'png');
  }
  if (lower.endsWith('.webp')) {
    return MediaType('image', 'webp');
  }
  return MediaType('image', 'jpeg');
}
