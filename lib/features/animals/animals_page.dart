import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/ads_service.dart';
import '../auth/auth_api.dart';
import 'animal_api.dart';
import 'animal_detail_page.dart';
import 'animal_form_page.dart';
import 'intake_requests_page.dart';
import 'animal_models.dart';
import '../../core/api_config.dart';

class AnimalsPage extends StatefulWidget {
  final AuthSession session;
  final AuthApi authApi;

  const AnimalsPage({super.key, required this.session, required this.authApi});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  late AnimalApi _animalApi;

  List<Animal> _animals = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  int _citizenTab = 0;
  bool get _isCitizen => widget.session.user['role'] == 'citoyen';
  bool get _isRefuge => widget.session.user['role'] == 'refuge';

  @override
  void initState() {
    super.initState();

    _animalApi = AnimalApi(baseUrl: '$apiBaseUrl/api', token: _getToken());

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });

    _loadAnimals();
  }

  String _getToken() {
    /*
     * IMPORTANT:
     *
     * Replace this with the exact access-token property
     * from your AuthSession.
     *
     * Example:
     * return widget.session.accessToken;
     */

    return widget.session.accessToken;
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final animals = _isCitizen || _isRefuge
          ? await _animalApi.getAnimals()
          : await _animalApi.getAdoptableAnimals();

      if (!mounted) return;

      setState(() {
        _animals = animals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Animal> get _filteredAnimals {
    final visible = _isCitizen
        ? _animals.where(
            (animal) => _citizenTab == 0 ? animal.isAdoptable : animal.isMine,
          )
        : _isRefuge
        ? _animals.where(
            (animal) =>
                _citizenTab == 0 ? animal.isAdoptable : !animal.isAdoptable,
          )
        : _animals;
    if (_search.isEmpty) {
      return visible.toList();
    }

    return visible.where((animal) {
      return animal.name.toLowerCase().contains(_search) ||
          animal.breed.toLowerCase().contains(_search);
    }).toList();
  }

  Future<void> _openAddAnimal() async {
    final created = await Navigator.push<Animal>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalFormPage(
          session: widget.session,
          authApi: widget.authApi,
          animalApi: _animalApi,
        ),
      ),
    );

    if (created != null) {
      if (_isCitizen) {
        setState(() => _citizenTab = 1);
      }
      await _loadAnimals();
    }
  }

  Future<void> _openIntakeRequests() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IntakeRequestsPage(animalApi: _animalApi),
      ),
    );
    await _loadAnimals();
  }

  Future<void> _openAnimal(Animal animal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailPage(
          animal: animal,
          session: widget.session,
          authApi: widget.authApi,
          animalApi: _animalApi,
        ),
      ),
    );

    await AdsService.instance.onAnimalDetailClosed();
    await _loadAnimals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animals = _filteredAnimals;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          _isCitizen && _citizenTab == 1
              ? context.tr('Mes animaux')
              : _isRefuge && _citizenTab == 1
              ? context.tr('Animaux de mon refuge')
              : context.tr('Animaux à adopter'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          if (_isRefuge)
            IconButton(
              tooltip: context.tr('Demandes de prise en charge'),
              onPressed: _openIntakeRequests,
              icon: const Icon(Icons.inbox_outlined),
            ),
          IconButton(onPressed: _loadAnimals, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _isCitizen || _isRefuge
          ? FloatingActionButton(
              onPressed: _openAddAnimal,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (_isCitizen || _isRefuge)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(context.tr('À adopter')),
                    selected: _citizenTab == 0,
                    onSelected: (_) => setState(() => _citizenTab = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      context.tr(_isCitizen ? 'Mes animaux' : 'Mon refuge'),
                    ),
                    selected: _citizenTab == 1,
                    onSelected: (_) => setState(() => _citizenTab = 1),
                  ),
                ],
              ),
            ),
          _buildSearch(),

          Expanded(child: _buildBody(animals)),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.tr('Rechercher un animal...'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Animal> animals) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 55),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnimals,
                child: Text(context.tr('Réessayer')),
              ),
            ],
          ),
        ),
      );
    }

    if (animals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAnimals,
        child: ListView(
          children: [
            SizedBox(height: 150),
            Icon(Icons.pets, size: 70, color: Colors.grey),
            SizedBox(height: 20),
            Center(
              child: Text(
                context.tr('Aucun animal disponible à l’adoption.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnimals,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: animals.length,
        itemBuilder: (context, index) {
          final animal = animals[index];

          return _AnimalCard(animal: animal, onTap: () => _openAnimal(animal));
        },
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback onTap;

  const _AnimalCard({required this.animal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (animal.breed.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            animal.breed,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                        if ((!animal.isAdoptable && animal.refugeId == null) ||
                            animal.intakeRequestStatus == 'accepted') ...[
                          const SizedBox(height: 6),
                          Text(
                            _intakeStatus(context, animal),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    if (animal.primaryPhoto == null || animal.primaryPhoto!.isEmpty) {
      return Container(
        height: 190,
        width: double.infinity,
        color: const Color(0xFFE8ECE7),
        child: const Icon(Icons.pets, size: 70, color: Colors.grey),
      );
    }

    return Image.network(
      animal.primaryPhoto!,
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: 190,
          color: const Color(0xFFE8ECE7),
          child: const Icon(Icons.pets, size: 70, color: Colors.grey),
        );
      },
    );
  }

  String _intakeStatus(BuildContext context, Animal animal) {
    return switch (animal.intakeRequestStatus) {
      'pending' =>
        context
            .tr('Demande envoyée à {name} — en attente')
            .replaceAll(
              '{name}',
              animal.intakeRefugeName ?? context.tr('un refuge'),
            ),
      'accepted' => context.tr('Un refuge a accepté la prise en charge'),
      'rejected' => context.tr(
        'Demande refusée — vous pouvez contacter un autre refuge',
      ),
      _ => context.tr('Votre animal — aucune demande de prise en charge'),
    };
  }
}
