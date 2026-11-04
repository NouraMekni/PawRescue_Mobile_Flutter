import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'messages_api.dart';
import 'thread_page.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({
    super.key,
    required this.session,
    required this.api,
    this.refugeId,
    this.veterinaireId,
    this.contactName,
    this.reportId,
  });

  final AuthSession session;
  final MessagesApi api;
  final int? refugeId;
  final int? veterinaireId;
  final String? contactName;
  final int? reportId;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _body = TextEditingController();
  List<Map<String, dynamic>> _refuges = [];
  int? _refugeId;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refugeId = widget.refugeId;
    if (widget.refugeId == null && widget.veterinaireId == null) {
      _loadRefuges();
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadRefuges() async {
    try {
      final refuges = await widget.api.refuges(widget.session.accessToken);
      if (!mounted) {
        return;
      }
      setState(() => _refuges = refuges);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _send() async {
    final refugeId = _refugeId;
    final body = _body.text.trim();
    if (refugeId == null && widget.veterinaireId == null) {
      setState(() => _error = context.tr('Choisissez un refuge.'));
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = context.tr('Le message ne peut pas être vide.'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final created = await widget.api.create(
        token: widget.session.accessToken,
        refugeId: refugeId,
        veterinaireId: widget.veterinaireId,
        body: body,
        reportId: widget.reportId,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ThreadPage(
            session: widget.session,
            api: widget.api,
            conversationId: created['id'] as int,
          ),
        ),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = context.tr('Impossible de joindre le serveur.'));
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
      appBar: AppBar(elevation: 0, title: Text(context.tr('Nouveau message'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.refugeId == null && widget.veterinaireId == null)
            DropdownButtonFormField<int>(
              initialValue: _refugeId,
              decoration: _decoration(context.tr('Refuge')),
              items: [
                for (final refuge in _refuges)
                  DropdownMenuItem(
                    value: refuge['id'] as int,
                    child: Text((refuge['name'] ?? '').toString()),
                  ),
              ],
              onChanged: (value) => setState(() => _refugeId = value),
            )
          else
            Text(
              widget.contactName == null
                  ? context.tr(
                      'Le destinataire doit accepter votre message avant de pouvoir répondre.',
                    )
                  : context
                        .tr(
                          'Écrire à {name}. Le destinataire doit accepter avant de répondre.',
                        )
                        .replaceAll('{name}', widget.contactName!),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _body,
            maxLines: 4,
            decoration: _decoration(context.tr('Message')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PawLogo.green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _loading ? null : _send,
            child: Text(
              _loading
                  ? context.tr('Envoi...')
                  : context.tr('Envoyer la demande'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
