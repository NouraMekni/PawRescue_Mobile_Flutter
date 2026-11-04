import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import 'auth_api.dart';
import 'paw_logo.dart';
import 'pending_verification_page.dart';
import 'vet_info_page.dart';

const refugeStructures = <String>['Refuge', 'Association'];

class RefugeInfoPage extends StatefulWidget {
  const RefugeInfoPage({
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
  State<RefugeInfoPage> createState() => _RefugeInfoPageState();
}

class _RefugeInfoPageState extends State<RefugeInfoPage> {
  final _name = TextEditingController();
  final _rne = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _officialEmail = TextEditingController();
  final _representative = TextEditingController();
  String? _structure;
  String? _governorate;
  String? _documentName;
  List<int>? _documentBytes;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _rne.dispose();
    _address.dispose();
    _phone.dispose();
    _officialEmail.dispose();
    _representative.dispose();
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

  bool get _complete =>
      _name.text.trim().isNotEmpty &&
      _structure != null &&
      _rne.text.trim().isNotEmpty &&
      _governorate != null &&
      _address.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _officialEmail.text.trim().isNotEmpty &&
      _representative.text.trim().isNotEmpty &&
      _documentBytes != null &&
      _documentName != null;

  Future<void> _submit() async {
    if (!_complete) {
      setState(() => _error = 'Remplissez les champs obligatoires et le justificatif.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authApi.registerRefuge(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        password: widget.password,
        phone: '+216${_phone.text.trim()}',
        name: _name.text.trim(),
        structure: _structure!,
        rne: _rne.text.trim(),
        governorate: _governorate!,
        address: _address.text.trim(),
        officialEmail: _officialEmail.text.trim(),
        representativeName: _representative.text.trim(),
        documentName: _documentName!,
        documentBytes: _documentBytes!,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PendingVerificationPage(authApi: widget.authApi),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: const Color(0xFF243028),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Vérification de l’organisation',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ces informations seront vérifiées par un administrateur.',
            style: TextStyle(color: Color(0xFF6E7872), fontSize: 15),
          ),
          const SizedBox(height: 20),
          _label('Nom officiel de l’organisation'),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              hintText: 'Nom du refuge ou de l’association',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Type de structure'),
          DropdownButtonFormField<String>(
            initialValue: _structure,
            hint: const Text('Sélectionnez un type de structure'),
            items: refugeStructures
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: _loading ? null : (value) => setState(() => _structure = value),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Numéro RNE'),
          TextField(
            controller: _rne,
            decoration: InputDecoration(
              hintText: 'Ex. 1234567A',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Gouvernorat'),
          DropdownButtonFormField<String>(
            initialValue: _governorate,
            hint: const Text('Sélectionnez un gouvernorat'),
            items: tunisianGovernorates
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: _loading ? null : (value) => setState(() => _governorate = value),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Adresse du siège'),
          TextField(
            controller: _address,
            decoration: InputDecoration(
              hintText: 'Adresse complète',
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
          _label('Email officiel'),
          TextField(
            controller: _officialEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'contact@organisation.tn',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Nom du représentant légal'),
          TextField(
            controller: _representative,
            decoration: InputDecoration(
              hintText: 'Nom et prénom',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Justificatif officiel'),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickDocument,
            icon: const Icon(Icons.upload_outlined, color: PawLogo.green),
            label: Text(
              _documentName ?? 'Télécharger un document\nPDF, JPG ou PNG (Max 5 Mo)',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Votre compte sera activé après validation par l’équipe PawRescue.',
            style: TextStyle(color: Color(0xFF6E7872)),
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
