class AnimalPhoto {
  final int id;
  final String image;
  final bool isPrimary;
  final int order;

  AnimalPhoto({
    required this.id,
    required this.image,
    required this.isPrimary,
    required this.order,
  });

  factory AnimalPhoto.fromJson(Map<String, dynamic> json) {
    return AnimalPhoto(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      order: json['order'] ?? 0,
    );
  }
}

class RefugeOption {
  final int id;
  final String name;

  const RefugeOption({required this.id, required this.name});
}

class AnimalIntakeRequest {
  final int id;
  final int animalId;
  final String animalName;
  final String animalBreed;
  final Animal? animalDetails;
  final int refugeId;
  final String refugeName;
  final String citizenName;
  final String status;
  final String message;

  const AnimalIntakeRequest({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.animalBreed,
    this.animalDetails,
    required this.refugeId,
    required this.refugeName,
    required this.citizenName,
    required this.status,
    required this.message,
  });

  factory AnimalIntakeRequest.fromJson(Map<String, dynamic> json) {
    return AnimalIntakeRequest(
      id: json['id'] ?? 0,
      animalId: json['animal'] ?? 0,
      animalName: json['animal_name'] ?? '',
      animalBreed: json['animal_breed'] ?? '',
      animalDetails: json['animal_details'] is Map
          ? Animal.fromJson(Map<String, dynamic>.from(json['animal_details']))
          : null,
      refugeId: json['refuge'] ?? 0,
      refugeName: json['refuge_name'] ?? '',
      citizenName: json['citizen_name'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class Animal {
  final int id;
  final String name;

  final int? refugeId;
  final String refugeName;
  final bool isMine;
  final String? intakeRequestStatus;
  final String? intakeRefugeName;

  final String breed;
  final int? estimatedAgeMonths;
  final String sex;
  final String sexDisplay;

  final double? weightKg;
  final String color;
  final String behavior;

  final String status;
  final String statusDisplay;

  final String size;
  final bool isAdoptable;

  final String? primaryPhoto;
  final List<AnimalPhoto> photos;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Animal({
    required this.id,
    required this.name,
    this.refugeId,
    required this.refugeName,
    this.isMine = false,
    this.intakeRequestStatus,
    this.intakeRefugeName,
    required this.breed,
    this.estimatedAgeMonths,
    required this.sex,
    required this.sexDisplay,
    this.weightKg,
    required this.color,
    required this.behavior,
    required this.status,
    required this.statusDisplay,
    required this.size,
    required this.isAdoptable,
    this.primaryPhoto,
    required this.photos,
    this.createdAt,
    this.updatedAt,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    final photosJson = json['photos'];

    return Animal(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',

      refugeId: parseInt(json['refuge']),
      refugeName: json['refuge_name'] ?? '',
      isMine: json['is_mine'] ?? false,
      intakeRequestStatus: json['intake_request_status'],
      intakeRefugeName: json['intake_refuge_name'],

      breed: json['breed'] ?? '',
      estimatedAgeMonths: json['estimated_age_months'],

      sex: json['sex'] ?? 'unknown',
      sexDisplay: json['sex_display'] ?? '',

      weightKg: parseDouble(json['weight_kg']),
      color: json['color'] ?? '',
      behavior: json['behavior'] ?? '',

      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',

      size: json['size'] ?? '',
      isAdoptable: json['is_adoptable'] ?? false,

      primaryPhoto: json['primary_photo'],

      photos: photosJson is List
          ? photosJson
                .map(
                  (photo) =>
                      AnimalPhoto.fromJson(Map<String, dynamic>.from(photo)),
                )
                .toList()
          : [],

      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
