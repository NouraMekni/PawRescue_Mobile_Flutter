import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../auth/auth_api.dart';
import '../auth/login_page.dart';
import '../auth/paw_logo.dart';

String roleLabel(String? role) {
  switch (role) {
    case 'benevole':
      return 'Bénévole';
    case 'veterinaire':
      return 'Vétérinaire';
    case 'refuge':
      return 'Refuge';
    case 'admin':
      return 'Administrateur';
    default:
      return 'Citoyen';
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.session,
    required this.authApi,
    this.onUserUpdated,
  });

  final AuthSession session;
  final AuthApi authApi;
  final VoidCallback? onUserUpdated;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final String _role;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _bio;
  late final TextEditingController _maxMissions;
  late final TextEditingController _license;
  late final TextEditingController _specialties;
  late final TextEditingController _radius;
  late final TextEditingController _refugeName;
  late final TextEditingController _refugePhone;
  late final TextEditingController _description;
  late final TextEditingController _capacity;
  late final TextEditingController _actionRadius;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late bool _available;
  Uint8List? _photoBytes;
  String? _photoName;
  String? _error;
  String? _saved;
  bool _loading = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final user = widget.session.user;
    final profile = user['profile'] is Map
        ? Map<String, dynamic>.from(user['profile'] as Map)
        : <String, dynamic>{};
    _role = (user['role'] ?? 'citoyen').toString();
    _firstName = TextEditingController(text: (user['first_name'] ?? '').toString());
    _lastName = TextEditingController(text: (user['last_name'] ?? '').toString());
    _phone = TextEditingController(text: (user['phone'] ?? '').toString());
    _address = TextEditingController(text: (profile['address'] ?? '').toString());
    _bio = TextEditingController(text: (profile['bio'] ?? '').toString());
    _maxMissions = TextEditingController(text: '${profile['max_missions'] ?? 3}');
    _license = TextEditingController(text: (profile['license_number'] ?? '').toString());
    _specialties = TextEditingController(text: (profile['specialties'] ?? '').toString());
    _radius = TextEditingController(text: '${profile['radius_km'] ?? 15}');
    _refugeName = TextEditingController(text: (profile['name'] ?? '').toString());
    _refugePhone = TextEditingController(text: (profile['phone'] ?? '').toString());
    _description = TextEditingController(text: (profile['description'] ?? '').toString());
    _capacity = TextEditingController(text: '${profile['capacity'] ?? 0}');
    _actionRadius = TextEditingController(text: '${profile['action_radius_km'] ?? 20}');
    _latitude = TextEditingController(text: _text(profile['latitude']));
    _longitude = TextEditingController(text: _text(profile['longitude']));
    _available = profile['is_available'] != false;
  }

  String _text(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _phone,
      _address,
      _bio,
      _maxMissions,
      _license,
      _specialties,
      _radius,
      _refugeName,
      _refugePhone,
      _description,
      _capacity,
      _actionRadius,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _usesLocation =>
      _role == 'benevole' || _role == 'veterinaire' || _role == 'refuge';

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() => _error = 'La photo ne doit pas dépasser 5 Mo.');
      return;
    }
    setState(() {
      _photoBytes = bytes;
      _photoName = file.name;
      _error = null;
      _saved = null;
    });
  }

  Future<void> _useMyPosition() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Autorisez la localisation pour remplir la position.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _latitude.text = position.latitude.toStringAsFixed(6);
      _longitude.text = position.longitude.toStringAsFixed(6);
    } catch (_) {
      setState(() => _error = 'Activez la localisation de l\'appareil.');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  double? _readDouble(TextEditingController controller) {
    final text = controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  int? _readInt(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(text);
  }

  Map<String, dynamic>? _profilePayload() {
    switch (_role) {
      case 'citoyen':
        return {'address': _address.text.trim()};
      case 'benevole':
        return {
          'bio': _bio.text.trim(),
          'is_available': _available,
          'max_missions': _readInt(_maxMissions) ?? 3,
          'latitude': _readDouble(_latitude),
          'longitude': _readDouble(_longitude),
        };
      case 'veterinaire':
        return {
          'license_number': _license.text.trim(),
          'specialties': _specialties.text.trim(),
          'is_available': _available,
          'radius_km': _readDouble(_radius) ?? 15,
          'latitude': _readDouble(_latitude),
          'longitude': _readDouble(_longitude),
        };
      case 'refuge':
        return {
          'name': _refugeName.text.trim(),
          'address': _address.text.trim(),
          'phone': _refugePhone.text.trim(),
          'description': _description.text.trim(),
          'capacity': _readInt(_capacity) ?? 0,
          'action_radius_km': _readDouble(_actionRadius) ?? 20,
          'latitude': _readDouble(_latitude),
          'longitude': _readDouble(_longitude),
        };
      default:
        return null;
    }
  }

  String? _validate() {
    final latitudeInvalid =
        _latitude.text.trim().isNotEmpty && _readDouble(_latitude) == null;
    final longitudeInvalid =
        _longitude.text.trim().isNotEmpty && _readDouble(_longitude) == null;
    if (_usesLocation && (latitudeInvalid || longitudeInvalid)) {
      return 'La latitude ou la longitude est invalide.';
    }
    if (_role == 'refuge') {
      if (_refugeName.text.trim().isEmpty) {
        return 'Le nom du refuge est obligatoire.';
      }
      if (_readDouble(_latitude) == null || _readDouble(_longitude) == null) {
        return 'Indiquez la position du refuge.';
      }
    }
    if (_role == 'benevole' && _maxMissions.text.trim().isNotEmpty && _readInt(_maxMissions) == null) {
      return 'Le nombre de missions est invalide.';
    }
    if (_role == 'refuge' && _capacity.text.trim().isNotEmpty && _readInt(_capacity) == null) {
      return 'La capacité est invalide.';
    }
    return null;
  }

  Future<void> _save() async {
    final validation = _validate();
    if (validation != null) {
      setState(() {
        _error = validation;
        _saved = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _saved = null;
    });
    try {
      var user = await widget.authApi.updateProfile(
        token: widget.session.accessToken,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        profile: _profilePayload(),
      );
      if (_photoBytes != null && _photoName != null) {
        user = await widget.authApi.updateProfilePhoto(
          token: widget.session.accessToken,
          filename: _photoName!,
          bytes: _photoBytes!,
        );
      }
      widget.session.user
        ..clear()
        ..addAll(user);
      widget.onUserUpdated?.call();
      if (!mounted) {
        return;
      }
      setState(() => _saved = 'Profil enregistré.');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Impossible de joindre le serveur.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(authApi: widget.authApi)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = (widget.session.user['email'] ?? '').toString();
    final photoUrl = (widget.session.user['photo'] ?? '').toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          Center(
            child: InkWell(
              onTap: _pickPhoto,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFE7F5EC),
                backgroundImage: _photoBytes != null
                    ? MemoryImage(_photoBytes!)
                    : (photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null),
                child: _photoBytes == null && photoUrl.isEmpty
                    ? const Icon(Icons.photo_camera_outlined, color: PawLogo.green, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajouter une photo',
            textAlign: TextAlign.center,
            style: TextStyle(color: PawLogo.green, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            roleLabel(_role),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _field(_firstName, 'Prénom'),
          const SizedBox(height: 12),
          _field(_lastName, 'Nom'),
          const SizedBox(height: 12),
          _field(_phone, 'Téléphone'),
          const SizedBox(height: 18),
          ..._roleFields(),
          Text(email, style: const TextStyle(color: Colors.black54)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_saved != null) ...[
            const SizedBox(height: 12),
            Text(_saved!, style: const TextStyle(color: PawLogo.green)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PawLogo.green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Enregistrement...' : 'Enregistrer'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _logout, child: const Text('Se déconnecter')),
        ],
      ),
    );
  }

  List<Widget> _roleFields() {
    switch (_role) {
      case 'citoyen':
        return [
          _field(_address, 'Adresse'),
          const SizedBox(height: 12),
        ];
      case 'benevole':
        return [
          _field(_bio, 'Bio', maxLines: 3),
          const SizedBox(height: 12),
          _field(_maxMissions, 'Missions maximum', keyboard: TextInputType.number),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: PawLogo.green,
            title: const Text('Disponible pour une mission'),
            value: _available,
            onChanged: (value) => setState(() => _available = value),
          ),
          ..._locationFields(),
        ];
      case 'veterinaire':
        return [
          _field(_license, 'Numéro de licence'),
          const SizedBox(height: 12),
          _field(_specialties, 'Spécialités', maxLines: 2),
          const SizedBox(height: 12),
          _field(_radius, 'Rayon d\'intervention (km)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: PawLogo.green,
            title: const Text('Disponible'),
            value: _available,
            onChanged: (value) => setState(() => _available = value),
          ),
          ..._locationFields(),
        ];
      case 'refuge':
        return [
          _field(_refugeName, 'Nom du refuge'),
          const SizedBox(height: 12),
          _field(_address, 'Adresse'),
          const SizedBox(height: 12),
          _field(_refugePhone, 'Téléphone du refuge'),
          const SizedBox(height: 12),
          _field(_description, 'Description', maxLines: 3),
          const SizedBox(height: 12),
          _field(_capacity, 'Capacité', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          _field(
            _actionRadius,
            'Rayon d\'action (km)',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          ..._locationFields(),
        ];
      default:
        return const [];
    }
  }

  List<Widget> _locationFields() {
    return [
      Row(
        children: [
          Expanded(
            child: _field(
              _latitude,
              'Latitude',
              keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _longitude,
              'Longitude',
              keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _locating ? null : _useMyPosition,
          icon: _locating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: PawLogo.green),
                )
              : const Icon(Icons.my_location, color: PawLogo.green),
          label: const Text('Utiliser ma position', style: TextStyle(color: PawLogo.green)),
        ),
      ),
    ];
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PawLogo.green),
        ),
      ),
    );
  }
}
