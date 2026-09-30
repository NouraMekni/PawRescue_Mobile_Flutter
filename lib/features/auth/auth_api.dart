import '../../core/api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String role = 'citoyen',
  }) async {
    final data = await _client.post('/api/auth/register/', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'role': role,
    });
    return AuthSession.fromJson(data);
  }

  Future<void> registerVeterinaire({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String licenseNumber,
    required String governorate,
    required String clinicName,
    required String address,
    required String documentName,
    required List<int> documentBytes,
  }) {
    return _client.postMultipart(
      '/api/auth/register/',
      fields: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'role': 'veterinaire',
        'phone': phone,
        'license_number': licenseNumber,
        'governorate': governorate,
        'clinic_name': clinicName,
        'address': address,
      },
      fileField: 'verification_document',
      filename: documentName,
      bytes: documentBytes,
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _client.post('/api/auth/token/', {
      'email': email,
      'password': password,
    });
    final access = tokens['access'] as String;
    final profile = await _client.get('/api/auth/me/', token: access);
    return AuthSession(accessToken: access, user: profile);
  }
}

class AuthSession {
  AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final Map<String, dynamic> user;

  factory AuthSession.fromJson(Map<String, dynamic> data) {
    final user = data['user'];
    return AuthSession(
      accessToken: data['access'] as String,
      user: user is Map<String, dynamic> ? user : <String, dynamic>{},
    );
  }
}
