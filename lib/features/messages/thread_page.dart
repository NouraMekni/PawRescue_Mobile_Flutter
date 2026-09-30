import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'messages_api.dart';
import 'messages_socket.dart';
import 'paw_pattern.dart';
import 'profile_avatar.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({
    super.key,
    required this.session,
    required this.api,
    required this.conversationId,
  });

  final AuthSession session;
  final MessagesApi api;
  final int conversationId;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _body = TextEditingController();
  final _socket = MessagesSocket();
  StreamSubscription<Map<String, dynamic>>? _events;
  Map<String, dynamic>? _conversation;
  String? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    final events = _socket.connect(widget.session.accessToken);
    _events = events?.listen((event) {
      if (event['conversation_id'] == widget.conversationId) {
        _load();
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _events?.cancel();
    _socket.close();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final conversation = await widget.api.detail(
        widget.session.accessToken,
        widget.conversationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = conversation;
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
    }
  }

  Future<void> _accept() async {
    await _run(() => widget.api.accept(widget.session.accessToken, widget.conversationId));
  }

  Future<void> _block() async {
    await _run(() => widget.api.block(widget.session.accessToken, widget.conversationId));
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.api.send(widget.session.accessToken, widget.conversationId, text);
      _body.clear();
      await _load();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _sending = true);
    try {
      final conversation = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = conversation;
        _error = null;
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    final messages = conversation?['messages'];
    final rows = messages is List ? messages : const [];
    final status = conversation?['status']?.toString();
    final needsResponse = conversation?['needs_response'] == true;
    final role = widget.session.user['role'];
    final title = role == 'refuge' || role == 'veterinaire'
        ? (conversation?['participant_name'] ?? 'Messages').toString()
        : ((conversation?['refuge_name'] ?? conversation?['veterinaire_name']) ?? 'Messages')
              .toString();
    final photo = (conversation?['photo'] ?? '').toString();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              ProfileAvatar(photo: photo == 'null' ? '' : photo, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: PawPattern(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: PawLogo.green))
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final row in rows)
                          if (row is Map) _bubble(Map<String, dynamic>.from(row)),
                        if (_error != null)
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  _bar(status, needsResponse),
                ],
              ),
        ),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> message) {
    final mine = message['sender'] == widget.session.user['id'];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? PawLogo.green : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: mine ? null : Border.all(color: const Color(0xFFE3E8E4)),
        ),
        child: Text(
          (message['body'] ?? '').toString(),
          style: TextStyle(color: mine ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _bar(String? status, bool needsResponse) {
    if (needsResponse) {
      return _panel(
        children: [
          const Text('Acceptez pour répondre, ou bloquez cette personne.'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: PawLogo.green),
                  onPressed: _sending ? null : _accept,
                  child: const Text('Accepter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _sending ? null : _block,
                  child: const Text('Bloquer'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (status == 'pending') {
      return _panel(
        children: const [
          Text('En attente d\'acceptation.'),
        ],
      );
    }
    if (status == 'blocked') {
      return _panel(
        children: const [
          Text('Vous ne pouvez pas envoyer de message.'),
        ],
      );
    }
    return _panel(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _body,
                decoration: const InputDecoration(
                  hintText: 'Votre message',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send, color: PawLogo.green),
            ),
          ],
        ),
      ],
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
