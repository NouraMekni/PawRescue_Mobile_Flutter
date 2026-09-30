import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/api_client.dart';

class AuthApi {
  AuthApi(this.client);

  final ApiClient client;

  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String role = 'citoyen',
  }) async {
    final data = await client.post('/api/auth/register/', {
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
    return client.postMultipart(
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
    final tokens = await client.post('/api/auth/token/', {
      'email': email,
      'password': password,
    });
    final access = tokens['access'] as String;
    final profile = await client.get('/api/auth/me/', token: access);
    return AuthSession(accessToken: access, user: profile);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
    required String phone,
    Map<String, dynamic>? profile,
  }) {
    return client.patch('/api/auth/me/', {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      if (profile != null) 'profile': profile,
    }, token: token);
  }

  Future<Map<String, dynamic>> updateProfilePhoto({
    required String token,
    required String filename,
    required List<int> bytes,
  }) {
    final lower = filename.toLowerCase();
    final subtype = lower.endsWith('.png')
        ? 'png'
        : lower.endsWith('.webp')
        ? 'webp'
        : 'jpeg';
    return client.postMultipart(
      '/api/auth/me/',
      method: 'PATCH',
      token: token,
      fields: const {},
      files: [
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: filename,
          contentType: MediaType('image', subtype),
        ),
      ],
    );
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
