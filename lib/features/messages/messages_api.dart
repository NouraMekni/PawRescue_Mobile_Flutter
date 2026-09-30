import '../../core/api_client.dart';

class MessagesApi {
  MessagesApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> conversations(String token) async {
    final rows = await _client.getList('/api/messaging/conversations/', token: token);
    return [for (final row in rows) if (row is Map) Map<String, dynamic>.from(row)];
  }

  Future<List<Map<String, dynamic>>> refuges(String token) async {
    final rows = await _client.getList('/api/messaging/refuges/', token: token);
    return [for (final row in rows) if (row is Map) Map<String, dynamic>.from(row)];
  }

  Future<List<Map<String, dynamic>>> veterinaires(String token) async {
    final rows = await _client.getList('/api/messaging/veterinaires/', token: token);
    return [for (final row in rows) if (row is Map) Map<String, dynamic>.from(row)];
  }

  Future<Map<String, dynamic>> create({
    required String token,
    required String body,
    int? refugeId,
    int? veterinaireId,
    int? reportId,
  }) {
    return _client.post('/api/messaging/conversations/', {
      if (refugeId != null) 'refuge': refugeId,
      if (veterinaireId != null) 'veterinaire': veterinaireId,
      'body': body,
      if (reportId != null) 'report': reportId,
    }, token: token);
  }

  Future<Map<String, dynamic>> detail(String token, int id) {
    return _client.get('/api/messaging/conversations/$id/', token: token);
  }

  Future<Map<String, dynamic>> send(String token, int id, String body) {
    return _client.post(
      '/api/messaging/conversations/$id/messages/',
      {'body': body},
      token: token,
    );
  }

  Future<Map<String, dynamic>> accept(String token, int id) {
    return _client.post('/api/messaging/conversations/$id/accept/', {}, token: token);
  }

  Future<Map<String, dynamic>> block(String token, int id) {
    return _client.post('/api/messaging/conversations/$id/block/', {}, token: token);
  }
}
