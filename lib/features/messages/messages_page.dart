import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'compose_page.dart';
import 'messages_api.dart';
import 'messages_socket.dart';
import 'profile_avatar.dart';
import 'thread_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.session, required this.authApi});

  final AuthSession session;
  final AuthApi authApi;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final MessagesApi _api = MessagesApi(widget.authApi.client);
  final _socket = MessagesSocket();
  StreamSubscription<Map<String, dynamic>>? _events;
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    final events = _socket.connect(widget.session.accessToken);
    _events = events?.listen((event) {
      if (event['type'] == 'notification.created') {
        return;
      }
      _load();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _events?.cancel();
    _socket.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _api.conversations(widget.session.accessToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = context.tr('Impossible de joindre le serveur.');
        _loading = false;
      });
    }
  }

  Future<void> _open(Map<String, dynamic> conversation) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ThreadPage(
          session: widget.session,
          api: _api,
          conversationId: conversation['id'] as int,
        ),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _compose() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposePage(session: widget.session, api: _api),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = widget.session.user['role'] != 'refuge';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          context.tr('Messages'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (canStart)
            IconButton(
              onPressed: _compose,
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.tr('Nouveau message'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PawLogo.green))
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _items.isEmpty
          ? Center(child: Text(context.tr('Aucune conversation.')))
          : RefreshIndicator(
              color: PawLogo.green,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final last = item['last_message'];
                  final preview = last is Map
                      ? (last['body'] ?? '').toString()
                      : '';
                  final photo = (item['photo'] ?? '').toString();
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _open(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            ProfileAvatar(photo: photo == 'null' ? '' : photo),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _title(item, context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preview.isEmpty
                                        ? context.tr(_statusLabel(item))
                                        : preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item['needs_response'] == true)
                              Container(
                                margin: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F5EC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  context.tr('Demande'),
                                  style: TextStyle(
                                    color: PawLogo.green,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _title(Map<String, dynamic> item, BuildContext context) {
    final role = widget.session.user['role'];
    if (role == 'refuge' || role == 'veterinaire') {
      return (item['participant_name'] ?? context.tr('Conversation'))
          .toString();
    }
    final refugeName = item['refuge_name']?.toString();
    if (refugeName != null && refugeName.isNotEmpty && refugeName != 'null') {
      return refugeName;
    }
    return (item['veterinaire_name'] ?? 'Conversation').toString();
  }

  String _statusLabel(Map<String, dynamic> item) {
    switch (item['status']) {
      case 'pending':
        return item['needs_response'] == true
            ? 'Demande à traiter'
            : 'En attente d\'acceptation';
      case 'blocked':
        return 'Vous ne pouvez pas envoyer de message.';
      default:
        return '';
    }
  }
}
