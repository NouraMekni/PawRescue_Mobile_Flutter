class AdoptionRequest {
  final int id;

  final int animalId;
  final String animalName;

  final int applicantId;
  final String applicantName;

  final int refugeId;
  final String refugeName;

  final String message;

  final String status;
  final String statusDisplay;

  final int? reviewedById;
  final String reviewedByName;

  final String reviewNote;

  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const AdoptionRequest({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.applicantId,
    required this.applicantName,
    required this.refugeId,
    required this.refugeName,
    required this.message,
    required this.status,
    required this.statusDisplay,
    this.reviewedById,
    required this.reviewedByName,
    required this.reviewNote,
    this.createdAt,
    this.reviewedAt,
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) {
        return value;
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }

      return DateTime.tryParse(value.toString());
    }

    return AdoptionRequest(
      id: parseInt(json['id']),

      animalId: parseInt(json['animal']),

      animalName:
          json['animal_name']?.toString() ??
          json['animal_display']?.toString() ??
          '',

      applicantId: parseInt(json['applicant']),

      applicantName:
          json['applicant_name']?.toString() ??
          json['applicant_display']?.toString() ??
          '',

      refugeId: parseInt(json['refuge']),

      refugeName:
          json['refuge_name']?.toString() ??
          json['refuge_display']?.toString() ??
          '',

      message: json['message']?.toString() ?? '',

      status: json['status']?.toString() ?? 'pending',

      statusDisplay:
          json['status_display']?.toString() ??
          json['status']?.toString() ??
          '',

      reviewedById: parseNullableInt(json['reviewed_by']),

      reviewedByName:
          json['reviewed_by_name']?.toString() ??
          json['reviewed_by_display']?.toString() ??
          '',

      reviewNote: json['review_note']?.toString() ?? '',

      createdAt: parseDate(json['created_at']),

      reviewedAt: parseDate(json['reviewed_at']),
    );
  }

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  bool get isCancelled => status == 'cancelled';
}
