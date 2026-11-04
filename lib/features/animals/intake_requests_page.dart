import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'animal_api.dart';
import 'animal_models.dart';

class IntakeRequestsPage extends StatefulWidget {
  final AnimalApi animalApi;

  const IntakeRequestsPage({super.key, required this.animalApi});

  @override
  State<IntakeRequestsPage> createState() => _IntakeRequestsPageState();
}

class _IntakeRequestsPageState extends State<IntakeRequestsPage> {
  List<AnimalIntakeRequest> _requests = [];
  bool _loading = true;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await widget.animalApi.getIntakeRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _decide(AnimalIntakeRequest request, bool accept) async {
    setState(() => _processing.add(request.id));
    try {
      await widget.animalApi.decideIntakeRequest(
        requestId: request.id,
        accept: accept,
      );
      await _loadRequests();
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing.remove(request.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('Demandes de prise en charge')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(onPressed: _loadRequests, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(),
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadRequests,
                child: Text(context.tr('Réessayer')),
              ),
            ],
          ),
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Text(context.tr('Aucune demande de prise en charge.')),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) =>
            _requestCard(context, _requests[index]),
      ),
    );
  }

  Widget _requestCard(BuildContext context, AnimalIntakeRequest request) {
    final isPending = request.status == 'pending';
    final isProcessing = _processing.contains(request.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animalDetails(context, request.animalDetails),
            const SizedBox(height: 14),
            Text(
              request.animalName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (request.animalBreed.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(request.animalBreed),
            ],
            const SizedBox(height: 8),
            Text(
              context
                  .tr('Demandeur : {name}')
                  .replaceAll('{name}', request.citizenName),
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.message),
            ],
            const SizedBox(height: 8),
            Text(
              context
                  .tr('Statut : {status}')
                  .replaceAll(
                    '{status}',
                    context.tr(_statusLabel(request.status)),
                  ),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing
                          ? null
                          : () => _decide(request, false),
                      child: Text(context.tr('Refuser')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () => _decide(request, true),
                      child: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.tr('Accepter')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _animalDetails(BuildContext context, Animal? animal) {
    if (animal == null) {
      return const SizedBox.shrink();
    }
    final details = <(String, String)>[
      ('Race', animal.breed),
      ('Âge', _ageLabel(animal.estimatedAgeMonths)),
      ('Sexe', animal.sexDisplay),
      ('Taille', animal.size),
      ('Poids', animal.weightKg == null ? '' : '${animal.weightKg} kg'),
      ('Couleur', animal.color),
      ('Statut', animal.statusDisplay),
    ].where((entry) => entry.$2.trim().isNotEmpty).toList();
    final photos = animal.photos.isNotEmpty
        ? animal.photos.map((photo) => photo.image).toList()
        : [animal.primaryPhoto].whereType<String>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty)
          SizedBox(
            height: 210,
            child: PageView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photos[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE8ECE7),
                    alignment: Alignment.center,
                    child: const Icon(Icons.pets, size: 56),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets, size: 56, color: Colors.grey),
          ),
        const SizedBox(height: 12),
        Text(
          context.tr('Informations de l’animal'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final (label, value) in details)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              context
                  .tr('{label} : {value}')
                  .replaceAll('{label}', context.tr(label))
                  .replaceAll('{value}', context.tr(value)),
            ),
          ),
        if (animal.behavior.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            context.tr('Comportement'),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(animal.behavior),
        ],
      ],
    );
  }

  String _ageLabel(int? ageMonths) {
    if (ageMonths == null) return '';
    if (ageMonths < 12) return '$ageMonths ${context.tr('mois')}';
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    if (months == 0) {
      return '$years ${context.tr(years == 1 ? 'an' : 'ans')}';
    }
    return '$years ${context.tr(years == 1 ? 'an' : 'ans')} '
        '${context.tr('et')} $months ${context.tr('mois')}';
  }

  String _statusLabel(String status) => switch (status) {
    'pending' => 'En attente',
    'accepted' => 'Acceptée',
    'rejected' => 'Refusée',
    'cancelled' => 'Annulée',
    _ => status,
  };
}
