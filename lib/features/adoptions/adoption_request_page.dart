import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../animals/animal_models.dart';
import '../auth/auth_api.dart';
import 'adoption_api.dart';
import 'adoption_models.dart';

class AdoptionRequestPage extends StatefulWidget {
  const AdoptionRequestPage({
    super.key,
    required this.animal,
    required this.session,
    required this.authApi,
  });

  final Animal animal;
  final AuthSession session;
  final AuthApi authApi;

  @override
  State<AdoptionRequestPage> createState() => _AdoptionRequestPageState();
}

class _AdoptionRequestPageState extends State<AdoptionRequestPage> {
  late final AdoptionApi _adoptionApi;

  final TextEditingController _messageController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _adoptionApi = AdoptionApi(ApiClient());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final AdoptionRequest request = await _adoptionApi.createAdoptionRequest(
        animalId: widget.animal.id,
        token: widget.session.accessToken,
        message: _messageController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      await _showSuccessDialog(request);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('Impossible d’envoyer la demande d’adoption.');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog(AdoptionRequest request) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('Demande envoyée'),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            context
                .tr(
                  'Votre demande d’adoption pour {name} a été envoyée avec succès.\n\nLe statut actuel de votre demande est : {status}.',
                )
                .replaceAll('{name}', widget.animal.name)
                .replaceAll(
                  '{status}',
                  context.tr(
                    request.statusDisplay.isNotEmpty
                        ? request.statusDisplay
                        : 'En attente',
                  ),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.tr('OK')),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    // Return the created adoption request
    // to AnimalDetailPage.
    Navigator.of(context).pop(request);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF243028)),
        title: Text(
          context.tr('Demande d’adoption'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF243028),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimalCard(animal),

              const SizedBox(height: 28),

              Text(
                context.tr('Votre demande'),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF243028),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                context.tr(
                  'Vous pouvez ajouter un message pour présenter votre projet d’adoption au refuge.',
                ),
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _messageController,
                maxLines: 7,
                maxLength: 1000,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: context
                      .tr(
                        'Exemple :\n\nBonjour, je souhaite adopter {name}. Je dispose d’un environnement adapté et je souhaite lui offrir un foyer stable et sécurisé.',
                      )
                      .replaceAll('{name}', animal.name),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C8B73),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _buildInformationCard(),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitRequest,
                  icon: _submitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    context.tr(
                      _submitting ? 'Envoi en cours...' : 'Envoyer ma demande',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F7D67),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  context.tr(
                    'Le refuge examinera votre demande avant de prendre une décision.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final image = animal.primaryPhoto;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.isNotEmpty)
            Image.network(
              image,
              height: 210,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _animalPlaceholder();
              },
            )
          else
            _animalPlaceholder(),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF243028),
                        ),
                      ),

                      const SizedBox(height: 5),

                      if (animal.breed.isNotEmpty)
                        Text(
                          context
                              .tr('Race : {value}')
                              .replaceAll('{value}', animal.breed),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 16, color: Colors.green),
                      SizedBox(width: 5),
                      Text(
                        context.tr('Adoptable'),
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animalPlaceholder() {
    return Container(
      height: 210,
      width: double.infinity,
      color: const Color(0xFFE8ECE7),
      child: const Icon(Icons.pets, size: 75, color: Colors.grey),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF5F7D67)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Votre demande sera enregistrée comme '
              '« En attente ». Le refuge pourra ensuite '
              'l’approuver ou la refuser.',
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
