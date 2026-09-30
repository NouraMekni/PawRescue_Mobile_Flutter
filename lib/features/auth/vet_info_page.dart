import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import 'auth_api.dart';
import 'login_page.dart';
import 'paw_logo.dart';

const tunisianGovernorates = <String>[
  'Tunis',
  'Ariana',
  'Ben Arous',
  'Manouba',
  'Nabeul',
  'Zaghouan',
  'Bizerte',
  'Béja',
  'Jendouba',
  'Le Kef',
  'Siliana',
  'Sousse',
  'Monastir',
  'Mahdia',
  'Sfax',
  'Kairouan',
  'Kasserine',
  'Sidi Bouzid',
  'Gabès',
  'Médenine',
  'Tataouine',
  'Gafsa',
  'Tozeur',
  'Kébili',
];

class VetInfoPage extends StatefulWidget {
  const VetInfoPage({
    super.key,
    required this.authApi,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final AuthApi authApi;
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  @override
  State<VetInfoPage> createState() => _VetInfoPageState();
}

class _VetInfoPageState extends State<VetInfoPage> {
  final _license = TextEditingController();
  final _clinic = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String? _governorate;
  String? _documentName;
  List<int>? _documentBytes;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _license.dispose();
    _clinic.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() => _error = 'Le fichier ne doit pas dépasser 5 Mo.');
      return;
    }
    setState(() {
      _documentName = file.name;
      _documentBytes = bytes;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_license.text.trim().isEmpty ||
        _governorate == null ||
        _clinic.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _documentBytes == null ||
        _documentName == null) {
      setState(() => _error = 'Remplissez les champs obligatoires et le justificatif.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authApi.registerVeterinaire(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        password: widget.password,
        phone: '+216${_phone.text.trim()}',
        licenseNumber: _license.text.trim(),
        governorate: _governorate!,
        clinicName: _clinic.text.trim(),
        address: _address.text.trim(),
        documentName: _documentName!,
        documentBytes: _documentBytes!,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => _PendingPage(authApi: widget.authApi),
        ),
        (_) => false,
      );
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
        foregroundColor: const Color(0xFF243028),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Informations professionnelles',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ces informations seront vérifiées par un administrateur.',
            style: TextStyle(color: Color(0xFF6E7872), fontSize: 15),
          ),
          const SizedBox(height: 20),
          _label("Numéro d'inscription à l'Ordre"),
          TextField(
            controller: _license,
            decoration: InputDecoration(
              hintText: '4582',
              suffixIcon: const Icon(Icons.help_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Gouvernorat'),
          DropdownButtonFormField<String>(
            initialValue: _governorate,
            hint: const Text('Choisir'),
            items: tunisianGovernorates
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: _loading ? null : (value) => setState(() => _governorate = value),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Nom du cabinet / clinique'),
          TextField(
            controller: _clinic,
            decoration: InputDecoration(
              hintText: 'Clinique VetCare',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Adresse (optionnel)'),
          const SizedBox(height: 6),
          TextField(
            controller: _address,
            decoration: InputDecoration(
              hintText: 'Avenue Habib Bourguiba, Tunis',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Téléphone'),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixText: '+216 ',
              hintText: '98 765 432',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Justificatif professionnel'),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickDocument,
            icon: const Icon(Icons.description_outlined, color: PawLogo.green),
            label: Text(_documentName ?? 'Importer un document\nPDF, JPG ou PNG (Max 5 MB)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: PawLogo.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_loading ? 'Envoi...' : 'Soumettre pour vérification'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _PendingPage extends StatelessWidget {
  const _PendingPage({required this.authApi});

  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 64, color: PawLogo.green),
            const SizedBox(height: 16),
            const Text(
              'Compte en attente de vérification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un administrateur doit valider votre dossier avant que vous puissiez vous connecter.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage(authApi: authApi)),
                  (_) => false,
                );
              },
              style: FilledButton.styleFrom(backgroundColor: PawLogo.green),
              child: const Text('Retour à la connexion'),
            ),
          ],
        ),
      ),
    );
  }
}
