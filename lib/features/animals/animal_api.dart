import 'dart:convert';

import 'package:http/http.dart' as http;

import 'animal_models.dart';

class AnimalApiException implements Exception {
  final String message;

  AnimalApiException(this.message);

  @override
  String toString() => message;
}

class AnimalApi {
  final String baseUrl;
  final String token;
  final http.Client _client;

  AnimalApi({required this.baseUrl, required this.token, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          return data['detail'].toString();
        }

        final messages = <String>[];

        data.forEach((key, value) {
          if (value is List) {
            messages.add('$key: ${value.join(', ')}');
          } else {
            messages.add('$key: $value');
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors.
    }

    return 'Erreur serveur (${response.statusCode})';
  }

  Future<List<Animal>> getAdoptableAnimals() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/animals/adoptable/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      return data
          .map((json) => Animal.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    // Support Django REST Framework pagination.
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((json) => Animal.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    throw AnimalApiException('Format de réponse inattendu pour les animaux.');
  }

  Future<List<Animal>> getAnimals() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/animals/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      return data
          .map((json) => Animal.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((json) => Animal.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    throw AnimalApiException('Format de réponse inattendu pour les animaux.');
  }

  Future<List<RefugeOption>> getRefugeOptions() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/messaging/refuges/'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    final decoded = jsonDecode(response.body);
    final rows = decoded is List
        ? decoded
        : decoded is Map && decoded['results'] is List
        ? decoded['results'] as List
        : null;
    if (rows == null) {
      throw AnimalApiException('Format de réponse inattendu pour les refuges.');
    }

    final refuges = <RefugeOption>[];
    for (final row in rows) {
      if (row is! Map) {
        continue;
      }
      final id = int.tryParse(row['id'].toString());
      final name = (row['name'] ?? '').toString().trim();
      if (id != null && name.isNotEmpty) {
        refuges.add(RefugeOption(id: id, name: name));
      }
    }
    return refuges;
  }

  Future<List<AnimalIntakeRequest>> getIntakeRequests() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/animals/intake-requests/'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }
    final decoded = jsonDecode(response.body);
    final rows = decoded is List
        ? decoded
        : decoded is Map && decoded['results'] is List
        ? decoded['results'] as List
        : null;
    if (rows == null) {
      throw AnimalApiException(
        'Format de réponse inattendu pour les demandes de prise en charge.',
      );
    }
    return rows
        .map(
          (row) => AnimalIntakeRequest.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<AnimalIntakeRequest> decideIntakeRequest({
    required int requestId,
    required bool accept,
  }) async {
    final action = accept ? 'accept' : 'reject';
    final response = await _client.post(
      Uri.parse('$baseUrl/animals/intake-requests/$requestId/$action/'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }
    return AnimalIntakeRequest.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<AnimalIntakeRequest> createIntakeRequest({
    required int animalId,
    required int refugeId,
    String message = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/animals/intake-requests/'),
      headers: _headers,
      body: jsonEncode({
        'animal': animalId,
        'refuge': refugeId,
        'message': message,
      }),
    );
    if (response.statusCode != 201) {
      throw AnimalApiException(_errorMessage(response));
    }
    return AnimalIntakeRequest.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<Animal> getAnimal(int id, {required String token}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/animals/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    return Animal.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<Animal> createAnimal({
    required String name,
    int? intakeRefugeId,
    String breed = '',
    int? estimatedAgeMonths,
    String sex = 'unknown',
    double? weightKg,
    String color = '',
    String behavior = '',
    String size = '',
    bool isAdoptable = false,
  }) async {
    final body = {
      'name': name,
      'breed': breed,
      'estimated_age_months': estimatedAgeMonths,
      'sex': sex,
      'weight_kg': weightKg,
      'color': color,
      'behavior': behavior,
      'size': size,
      'is_adoptable': isAdoptable,
    };
    if (intakeRefugeId != null) {
      body['intake_refuge'] = intakeRefugeId;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/animals/'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw AnimalApiException(_errorMessage(response));
    }

    return Animal.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<void> uploadPhoto({
    required int animalId,
    required String filename,
    required List<int> bytes,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/animals/$animalId/photos/'),
          )
          ..headers['Authorization'] = _headers['Authorization']!
          ..fields['is_primary'] = 'true'
          ..fields['order'] = '0'
          ..files.add(
            http.MultipartFile.fromBytes('image', bytes, filename: filename),
          );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw AnimalApiException(_errorMessage(response));
    }
  }

  Future<Animal> updateAnimal(
    int id, {
    String? name,
    int? refugeId,
    String? breed,
    int? estimatedAgeMonths,
    String? sex,
    double? weightKg,
    String? color,
    String? behavior,
    String? status,
    String? size,
    bool? isAdoptable,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) {
      body['name'] = name;
    }

    if (refugeId != null) {
      body['refuge'] = refugeId;
    }

    if (breed != null) {
      body['breed'] = breed;
    }

    if (estimatedAgeMonths != null) {
      body['estimated_age_months'] = estimatedAgeMonths;
    }

    if (sex != null) {
      body['sex'] = sex;
    }

    if (weightKg != null) {
      body['weight_kg'] = weightKg;
    }

    if (color != null) {
      body['color'] = color;
    }

    if (behavior != null) {
      body['behavior'] = behavior;
    }

    if (status != null) {
      body['status'] = status;
    }

    if (size != null) {
      body['size'] = size;
    }

    if (isAdoptable != null) {
      body['is_adoptable'] = isAdoptable;
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/animals/$id/'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    return Animal.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<void> deleteAnimal(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/animals/$id/'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw AnimalApiException(_errorMessage(response));
    }
  }

  Future<Animal> makeAdoptable(int id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/animals/$id/make-adoptable/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    return Animal.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<Animal> removeFromAdoption(int id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/animals/$id/remove-from-adoption/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AnimalApiException(_errorMessage(response));
    }

    return Animal.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }
}
