import '../../core/api_client.dart';
import 'adoption_models.dart';

class AdoptionApi {
  AdoptionApi(this.client);

  final ApiClient client;

  // ============================================================
  // GET /api/adoptions/
  // ============================================================

  Future<List<AdoptionRequest>> getAdoptionRequests({
    required String token,
  }) async {
    final data = await client.getList('/api/adoptions/', token: token);

    return data
        .whereType<Map>()
        .map(
          (json) => AdoptionRequest.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  // ============================================================
  // GET /api/adoptions/{id}/
  // ============================================================

  Future<AdoptionRequest> getAdoptionRequest({
    required int id,
    required String token,
  }) async {
    final data = await client.get('/api/adoptions/$id/', token: token);

    return AdoptionRequest.fromJson(data);
  }

  // ============================================================
  // POST /api/adoptions/
  //
  // Citizen creates an adoption request.
  //
  // Backend automatically determines:
  // - applicant = request.user
  // - refuge = animal.refuge
  // - status = pending
  // ============================================================

  Future<AdoptionRequest> createAdoptionRequest({
    required int animalId,
    required String token,
    String message = '',
  }) async {
    final data = await client.post('/api/adoptions/', {
      'animal': animalId,
      'message': message,
    }, token: token);

    return AdoptionRequest.fromJson(data);
  }

  // ============================================================
  // POST /api/adoptions/{id}/cancel/
  //
  // Only the applicant can cancel.
  // Only PENDING requests can be cancelled.
  // ============================================================

  Future<AdoptionRequest> cancelAdoptionRequest({
    required int id,
    required String token,
  }) async {
    final data = await client.post(
      '/api/adoptions/$id/cancel/',
      {},
      token: token,
    );

    return AdoptionRequest.fromJson(data);
  }

  // ============================================================
  // POST /api/adoptions/{id}/approve/
  //
  // Refuge or Admin.
  // review_note is optional.
  // ============================================================

  Future<AdoptionRequest> approveAdoptionRequest({
    required int id,
    required String token,
    String reviewNote = '',
  }) async {
    final data = await client.post('/api/adoptions/$id/approve/', {
      'review_note': reviewNote,
    }, token: token);

    return AdoptionRequest.fromJson(data);
  }

  // ============================================================
  // POST /api/adoptions/{id}/reject/
  //
  // Refuge or Admin.
  // review_note is optional.
  // ============================================================

  Future<AdoptionRequest> rejectAdoptionRequest({
    required int id,
    required String token,
    String reviewNote = '',
  }) async {
    final data = await client.post('/api/adoptions/$id/reject/', {
      'review_note': reviewNote,
    }, token: token);

    return AdoptionRequest.fromJson(data);
  }
}
