import 'package:flutter/material.dart';

import '../adoptions/adoption_models.dart';
import '../adoptions/adoption_request_page.dart';
import '../auth/auth_api.dart';
import 'animal_api.dart';
import 'animal_models.dart';

class AnimalDetailPage extends StatefulWidget {
  const AnimalDetailPage({
    super.key,
    required this.animal,
    required this.session,
    required this.authApi,
    required this.animalApi,
  });

  final Animal animal;
  final AuthSession session;
  final AuthApi authApi;
  final AnimalApi animalApi;

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  late Animal _animal;

  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _animal = widget.animal;

    _loadAnimal();
  }

  Future<void> _loadAnimal() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final animal = await widget.animalApi.getAnimal(
        widget.animal.id,
        token: widget.session.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _animal = animal;
        _loading = false;
      });
    } on AnimalApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les informations de l’animal.';
      });
    }
  }

  bool get _isCitizen {
    return widget.session.user['role'] == 'citoyen';
  }

  bool get _canRequestAdoption {
    return _isCitizen && _animal.isAdoptable && _animal.status == 'in_shelter';
  }

  bool get _canPublishForAdoption {
    return widget.session.user['role'] == 'refuge' &&
        _animal.refugeId != null &&
        _animal.status == 'in_shelter' &&
        !_animal.isAdoptable;
  }

  bool get _canRequestRefugeCare {
    return _isCitizen &&
        _animal.isMine &&
        _animal.refugeId == null &&
        _animal.status == 'owned' &&
        _animal.intakeRequestStatus != 'pending';
  }

  Future<void> _requestRefugeCare() async {
    setState(() => _actionLoading = true);
    try {
      final refuges = await widget.animalApi.getRefugeOptions();
      if (!mounted) return;
      if (refuges.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun refuge n’est disponible.')),
        );
        setState(() => _actionLoading = false);
        return;
      }
      final refugeId = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Choisir un refuge'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              shrinkWrap: true,
              children: refuges
                  .map(
                    (refuge) => ListTile(
                      title: Text(refuge.name),
                      onTap: () => Navigator.pop(dialogContext, refuge.id),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
      if (refugeId == null) {
        if (mounted) setState(() => _actionLoading = false);
        return;
      }
      await widget.animalApi.createIntakeRequest(
        animalId: _animal.id,
        refugeId: refugeId,
      );
      if (!mounted) return;
      await _loadAnimal();
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée au refuge.')),
      );
    } on AnimalApiException catch (error) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _publishForAdoption() async {
    try {
      final updated = await widget.animalApi.makeAdoptable(_animal.id);
      if (!mounted) return;
      setState(() => _animal = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal publié pour adoption.')),
      );
    } on AnimalApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _requestAdoption() async {
    final AdoptionRequest? result = await Navigator.push<AdoptionRequest>(
      context,
      MaterialPageRoute(
        builder: (_) => AdoptionRequestPage(
          animal: _animal,
          session: widget.session,
          authApi: widget.authApi,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre demande d’adoption a été envoyée.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadAnimal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(_animal.name),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAnimal,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 15),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _loadAnimal,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnimal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotos(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _animal.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _animal.breed.isEmpty
                        ? 'Race non précisée'
                        : 'Race : ${_animal.breed}',
                    style: TextStyle(fontSize: 17, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoGrid(),
                  if (_animal.behavior.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    _sectionTitle('Comportement'),
                    const SizedBox(height: 8),
                    Text(
                      _animal.behavior,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                  if (_animal.refugeName.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    _sectionTitle('Refuge'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _animal.refugeName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 25),
                  _buildStatus(),
                  if (_isCitizen &&
                      _animal.isMine &&
                      _animal.intakeRequestStatus != null) ...[
                    const SizedBox(height: 12),
                    _buildIntakeStatus(),
                  ],
                  if (_isCitizen &&
                      !_animal.isAdoptable &&
                      _animal.status != 'adopted') ...[
                    const SizedBox(height: 12),
                    _buildNotAvailableMessage(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotos() {
    if (_animal.photos.isEmpty) {
      return Container(
        height: 280,
        width: double.infinity,
        color: const Color(0xFFE8ECE7),
        child: const Icon(Icons.pets, size: 90, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        itemCount: _animal.photos.length,
        itemBuilder: (_, index) {
          final photo = _animal.photos[index];

          return Image.network(
            photo.image,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return Container(
                color: const Color(0xFFE8ECE7),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) {
              return Container(
                color: const Color(0xFFE8ECE7),
                child: const Icon(Icons.pets, size: 90, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                _animal.sex == 'M'
                    ? Icons.male
                    : _animal.sex == 'F'
                    ? Icons.female
                    : Icons.pets,
                'Sexe',
                _animal.sexDisplay.isEmpty ? _animal.sex : _animal.sexDisplay,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                Icons.straighten,
                'Taille',
                _animal.size.isEmpty ? 'Non précisée' : _animal.size,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _infoCard(Icons.cake_outlined, 'Âge', _ageText())),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                Icons.monitor_weight_outlined,
                'Poids',
                _animal.weightKg == null
                    ? 'Non précisé'
                    : '${_animal.weightKg} kg',
              ),
            ),
          ],
        ),
        if (_animal.color.isNotEmpty) ...[
          const SizedBox(height: 10),
          _infoCard(Icons.palette_outlined, 'Couleur', _animal.color),
        ],
      ],
    );
  }

  String _ageText() {
    final months = _animal.estimatedAgeMonths;

    if (months == null) {
      return 'Non précisé';
    }

    if (months < 12) {
      return '$months mois';
    }

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (remainingMonths == 0) {
      return '$years an${years > 1 ? 's' : ''}';
    }

    return '$years an${years > 1 ? 's' : ''} '
        'et $remainingMonths mois';
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIntakeStatus() {
    final status = _animal.intakeRequestStatus;
    final label = switch (status) {
      'pending' =>
        'Demande envoyée à ${_animal.intakeRefugeName ?? 'un refuge'} — en attente',
      'accepted' => 'Le refuge a accepté la prise en charge.',
      'rejected' =>
        'La demande a été refusée. Vous pouvez en contacter un autre.',
      _ => 'Aucune demande de prise en charge.',
    };
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w500));
  }

  Widget _buildStatus() {
    IconData icon = Icons.info_outline;

    if (_animal.status == 'in_shelter') {
      icon = Icons.home_work_outlined;
    } else if (_animal.status == 'adopted') {
      icon = Icons.favorite;
    } else if (_animal.status == 'reserved') {
      icon = Icons.bookmark_outline;
    } else if (_animal.status == 'rescued') {
      icon = Icons.volunteer_activism_outlined;
    } else if (_animal.status == 'stray') {
      icon = Icons.location_on_outlined;
    }

    final statusText = _animal.statusDisplay.isEmpty
        ? _animal.status
        : _animal.statusDisplay;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Statut : $statusText',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAvailableMessage() {
    String message = 'Cet animal n’est pas disponible à l’adoption.';

    if (_animal.status == 'reserved') {
      message = 'Cet animal est actuellement réservé.';
    } else if (_animal.status == 'stray') {
      message = 'Cet animal est actuellement signalé comme errant.';
    } else if (_animal.status == 'rescued') {
      message = 'Cet animal est encore en cours de prise en charge.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomButton() {
    if (_canRequestRefugeCare) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _actionLoading ? null : _requestRefugeCare,
              icon: _actionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.home_work_outlined),
              label: const Text('Demander l’aide d’un refuge'),
            ),
          ),
        ),
      );
    }
    if (_canPublishForAdoption) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _actionLoading ? null : _publishForAdoption,
              icon: const Icon(Icons.favorite_border),
              label: const Text('Proposer à l’adoption'),
            ),
          ),
        ),
      );
    }
    if (!_canRequestAdoption) {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _requestAdoption,
            icon: const Icon(Icons.favorite_border),
            label: const Text(
              'Demander l’adoption',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
