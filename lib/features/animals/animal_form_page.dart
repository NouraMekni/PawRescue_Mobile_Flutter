import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../auth/auth_api.dart';
import 'animal_api.dart';
import 'animal_models.dart';

class AnimalFormPage extends StatefulWidget {
  final AuthSession session;
  final AuthApi authApi;
  final AnimalApi animalApi;

  const AnimalFormPage({
    super.key,
    required this.session,
    required this.authApi,
    required this.animalApi,
  });

  @override
  State<AnimalFormPage> createState() => _AnimalFormPageState();
}

class _AnimalFormPageState extends State<AnimalFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _behaviorController = TextEditingController();

  String _sex = 'unknown';
  String _size = '';
  int? _refugeId;
  List<RefugeOption> _refuges = [];
  String? _optionsError;
  String? _photoName;
  Uint8List? _photoBytes;
  Animal? _createdAnimal;

  bool _isAdoptable = true;
  bool _loading = false;
  bool _loadingOptions = true;
  bool get _isCitizen => widget.session.user['role'] == 'citoyen';

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _behaviorController.dispose();

    super.dispose();
  }

  Future<void> _loadOptions() async {
    if (!_isCitizen) {
      setState(() => _loadingOptions = false);
      return;
    }
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    try {
      final refuges = await widget.animalApi.getRefugeOptions();
      if (!mounted) return;
      setState(() {
        _refuges = refuges;
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _optionsError = error.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        _showError('Choisissez une image JPG, PNG ou WEBP.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        _showError('La photo ne doit pas dépasser 8 Mo.');
        return;
      }

      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();

      if (!mounted) return;
      setState(() {
        _photoName = file.name;
        _photoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      _showError(
        'Impossible de lire cette image. Choisissez un fichier JPG, PNG ou WEBP.',
      );
    }
  }

  Future<void> _submit() async {
    final createdAnimal = _createdAnimal;
    if (createdAnimal != null) {
      if (_photoBytes == null || _photoName == null) {
        Navigator.pop(context, createdAnimal);
        return;
      }
      await _uploadPhoto(createdAnimal);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final animal = await widget.animalApi.createAnimal(
        name: _nameController.text.trim(),
        intakeRefugeId: _isCitizen ? _refugeId : null,
        breed: _breedController.text.trim(),
        estimatedAgeMonths: int.tryParse(_ageController.text.trim()),
        sex: _sex,
        weightKg: double.tryParse(_weightController.text.trim()),
        color: _colorController.text.trim(),
        behavior: _behaviorController.text.trim(),
        size: _size,
        isAdoptable: !_isCitizen && _isAdoptable,
      );

      if (!mounted) return;
      setState(() {
        _createdAnimal = animal;
        _loading = false;
      });
      if (_photoBytes != null && _photoName != null) {
        await _uploadPhoto(animal);
      } else {
        Navigator.pop(context, animal);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(e.toString());
    }
  }

  Future<void> _uploadPhoto(Animal animal) async {
    setState(() => _loading = true);
    try {
      await widget.animalApi.uploadPhoto(
        animalId: animal.id,
        filename: _photoName!,
        bytes: _photoBytes!,
      );
      if (!mounted) return;
      Navigator.pop(context, animal);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(
        'Animal créé, mais la photo n’a pas été envoyée : $error. '
        'Vous pouvez réessayer sans recréer l’animal.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Ajouter un animal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _sectionTitle('Informations principales'),

            const SizedBox(height: 15),

            _textField(
              controller: _nameController,
              label: 'Nom',
              hint: 'Ex. Luna',
              icon: Icons.pets,
              required: true,
            ),

            const SizedBox(height: 12),

            if (_isCitizen) ...[
              const SizedBox(height: 12),
              _sectionTitle('Prise en charge (facultatif)'),
              const SizedBox(height: 8),
              const Text(
                'Vous pouvez enregistrer votre animal sans refuge. '
                'Si vous souhaitez le proposer à l’adoption, choisissez '
                'un refuge : il devra accepter la prise en charge avant '
                'que l’animal puisse être proposé à l’adoption.',
                style: TextStyle(color: Color(0xFF5B6470), height: 1.4),
              ),
              const SizedBox(height: 12),
              if (_loadingOptions)
                const LinearProgressIndicator()
              else if (_optionsError != null)
                _buildOptionsError()
              else if (_refuges.isEmpty)
                _buildEmptyOptions('Aucun refuge n’est disponible.')
              else
                _buildLookupDropdown(
                  label: 'Refuge à contacter',
                  icon: Icons.home_outlined,
                  options: _refuges,
                  value: _refugeId,
                  optional: true,
                  onChanged: (value) => setState(() => _refugeId = value),
                ),
            ],

            _textField(
              controller: _breedController,
              label: 'Race',
              hint: 'Ex. Berger allemand',
              icon: Icons.pets_outlined,
            ),

            const SizedBox(height: 12),

            _textField(
              controller: _ageController,
              label: 'Âge estimé en mois',
              hint: 'Ex. 24',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            _sectionTitle('Caractéristiques'),

            const SizedBox(height: 15),

            _buildSexDropdown(),

            const SizedBox(height: 12),

            _buildSizeDropdown(),

            const SizedBox(height: 12),

            _textField(
              controller: _weightController,
              label: 'Poids en kg',
              hint: 'Ex. 12.5',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            const SizedBox(height: 12),

            _textField(
              controller: _colorController,
              label: 'Couleur',
              hint: 'Ex. Marron et blanc',
              icon: Icons.palette_outlined,
            ),

            const SizedBox(height: 20),

            _sectionTitle('Photo de l’animal'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_photoName ?? 'Ajouter une photo (facultatif)'),
            ),
            if (_photoBytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _photoBytes!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    alignment: Alignment.center,
                    color: const Color(0xFFE9EEEA),
                    child: const Text('Aperçu de la photo indisponible'),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            _sectionTitle('Comportement'),

            const SizedBox(height: 15),

            TextFormField(
              controller: _behaviorController,
              minLines: 4,
              maxLines: 7,
              decoration: InputDecoration(
                labelText: 'Comportement',
                hintText: 'Décrivez le comportement de l’animal...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 70),
                  child: Icon(Icons.psychology_outlined),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!_isCitizen) _buildAdoptionSwitch(),

            const SizedBox(height: 30),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _loading
                      ? 'Ajout en cours...'
                      : _createdAnimal != null && _photoBytes != null
                      ? 'Réessayer l’envoi de la photo'
                      : _createdAnimal != null
                      ? 'Terminer'
                      : 'Ajouter l’animal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (_createdAnimal != null && _photoBytes != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.pop(context, _createdAnimal),
                child: const Text('Continuer sans photo'),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLookupDropdown({
    required String label,
    required IconData icon,
    required List<RefugeOption> options,
    required int? value,
    bool optional = false,
    required ValueChanged<int?> onChanged,
  }) {
    final available =
        !_loadingOptions && _optionsError == null && options.isNotEmpty;
    return DropdownButtonFormField<int>(
      initialValue: optional
          ? (options.any((option) => option.id == value) ? value : -1)
          : (options.any((option) => option.id == value) ? value : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        if (optional)
          const DropdownMenuItem<int>(
            value: -1,
            child: Text('Aucun refuge pour le moment'),
          ),
        ...options.map(
          (option) =>
              DropdownMenuItem<int>(value: option.id, child: Text(option.name)),
        ),
      ],
      onChanged: available && !_loading
          ? (selected) => onChanged(selected == -1 ? null : selected)
          : null,
      validator: optional
          ? null
          : (selected) => selected == null ? 'Sélectionnez $label' : null,
    );
  }

  Widget _buildOptionsError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impossible de charger les refuges : $_optionsError',
          style: const TextStyle(color: Colors.red),
        ),
        TextButton.icon(
          onPressed: _loadOptions,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildEmptyOptions(String message) {
    return Text(message, style: const TextStyle(color: Colors.red));
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label est obligatoire';
              }

              return null;
            }
          : null,
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _sex,
      decoration: InputDecoration(
        labelText: 'Sexe',
        prefixIcon: const Icon(Icons.male),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'unknown', child: Text('Inconnu')),
        DropdownMenuItem(value: 'M', child: Text('Mâle')),
        DropdownMenuItem(value: 'F', child: Text('Femelle')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _sex = value;
        });
      },
    );
  }

  Widget _buildSizeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _size,
      decoration: InputDecoration(
        labelText: 'Taille',
        prefixIcon: const Icon(Icons.straighten),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('Non précisée')),
        DropdownMenuItem(value: 'small', child: Text('Petit')),
        DropdownMenuItem(value: 'medium', child: Text('Moyen')),
        DropdownMenuItem(value: 'large', child: Text('Grand')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _size = value;
        });
      },
    );
  }

  Widget _buildAdoptionSwitch() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Proposer à l’adoption',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'L’animal apparaîtra dans la liste des animaux adoptables.',
          ),
          value: _isAdoptable,
          onChanged: (value) {
            setState(() {
              _isAdoptable = value;
            });
          },
        ),
      ),
    );
  }
}
