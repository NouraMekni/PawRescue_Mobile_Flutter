import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'reports_api.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key, required this.session, required this.reports});

  final AuthSession session;
  final ReportsApi reports;

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _presence = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  String _type = 'stray';
  String? _severity;
  String? _photoName;
  Uint8List? _photoBytes;
  String? _error;
  bool _loading = false;
  bool _locating = false;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _presence.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      setState(() => _error = 'La photo ne doit pas dépasser 8 Mo.');
      return;
    }
    setState(() {
      _photoName = file.name;
      _photoBytes = bytes;
      _error = null;
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

  Future<void> _submit() async {
    final latitude = double.tryParse(_latitude.text.trim().replaceAll(',', '.'));
    final longitude = double.tryParse(_longitude.text.trim().replaceAll(',', '.'));
    if (_photoBytes == null || _photoName == null) {
      setState(() => _error = 'Ajoutez une photo de l\'animal.');
      return;
    }
    if (_type == 'injured' && (_severity == null || _severity!.isEmpty)) {
      setState(() => _error = 'Indiquez la gravité.');
      return;
    }
    if (latitude == null || longitude == null) {
      setState(() => _error = 'Indiquez la latitude et la longitude.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.reports.create(
        token: widget.session.accessToken,
        type: _type,
        severity: _type == 'injured' ? _severity : null,
        latitude: latitude,
        longitude: longitude,
        description: _description.text.trim(),
        addressText: _address.text.trim(),
        estimatedPresence: _presence.text.trim(),
        photoName: _photoName!,
        photoBytes: _photoBytes!,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouveau signalement'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Où est l\'animal ?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Une photo et la position suffisent pour prévenir le refuge le plus proche.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _TypeCard(
                label: 'Animal errant',
                icon: Icons.pets,
                selected: _type == 'stray',
                onTap: () => setState(() {
                  _type = 'stray';
                  _severity = null;
                }),
              ),
              const SizedBox(width: 12),
              _TypeCard(
                label: 'Animal blessé',
                icon: Icons.healing,
                selected: _type == 'injured',
                onTap: () => setState(() => _type = 'injured'),
              ),
            ],
          ),
          if (_type == 'injured') ...[
            const SizedBox(height: 16),
            const Text('Gravité', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                _Severity('mild', 'Léger'),
                _Severity('moderate', 'Modéré'),
                _Severity('critical', 'Critique'),
              ].map((choice) {
                return ChoiceChip(
                  label: Text(choice.label),
                  selected: _severity == choice.value,
                  selectedColor: PawLogo.green.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _severity = choice.value),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          _field(_description, 'Description', maxLines: 3),
          const SizedBox(height: 12),
          _field(_address, 'Adresse'),
          const SizedBox(height: 12),
          _field(_presence, 'Depuis quand est-il là ?'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(_photoName ?? 'Ajouter une photo'),
          ),
          if (_photoBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_photoBytes!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field(_latitude, 'Latitude')),
              const SizedBox(width: 12),
              Expanded(child: _field(_longitude, 'Longitude')),
            ],
          ),
          const SizedBox(height: 8),
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
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PawLogo.green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Envoi...' : 'Envoyer le signalement'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F8F8),
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? PawLogo.green.withValues(alpha: 0.12) : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? PawLogo.green : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? PawLogo.green : Colors.black54),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? PawLogo.green : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Severity {
  const _Severity(this.value, this.label);

  final String value;
  final String label;
}
