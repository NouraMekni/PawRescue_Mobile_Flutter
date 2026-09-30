import '../../core/api_client.dart';

class NotificationsApi {
  NotificationsApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list(String token) async {
    final rows = await _client.getList('/api/notifications/', token: token);
    return [for (final row in rows) if (row is Map) Map<String, dynamic>.from(row)];
  }

  Future<Map<String, dynamic>> markRead(String token, int id) {
    return _client.post('/api/notifications/$id/read/', {}, token: token);
  }
}
