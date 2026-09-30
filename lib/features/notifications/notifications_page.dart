import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import '../messages/messages_api.dart';
import '../messages/messages_socket.dart';
import '../messages/thread_page.dart';
import 'notifications_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.session,
    required this.authApi,
    this.onUnreadChanged,
  });

  final AuthSession session;
  final AuthApi authApi;
  final ValueChanged<int>? onUnreadChanged;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsApi _api = NotificationsApi(widget.authApi.client);
  late final MessagesApi _messages = MessagesApi(widget.authApi.client);
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
      if (event['type'] != 'notification.created') {
        return;
      }
      final notification = event['notification'];
      if (notification is! Map) {
        return;
      }
      final item = Map<String, dynamic>.from(notification);
      setState(() {
        _items.removeWhere((row) => row['id'] == item['id']);
        _items.insert(0, item);
        _error = null;
        _loading = false;
      });
      _publishCount();
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
      final items = await _api.list(widget.session.accessToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
      _publishCount();
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
        _error = 'Impossible de joindre le serveur.';
        _loading = false;
      });
    }
  }

  void _publishCount() {
    final unread = _items.where((item) => item['is_read'] != true).length;
    widget.onUnreadChanged?.call(unread);
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id is int && item['is_read'] != true) {
      try {
        final updated = await _api.markRead(widget.session.accessToken, id);
        if (!mounted) {
          return;
        }
        setState(() {
          final index = _items.indexWhere((row) => row['id'] == id);
          if (index >= 0) {
            _items[index] = updated;
          }
        });
        _publishCount();
      } on ApiException catch (error) {
        if (!mounted) {
          return;
        }
        setState(() => _error = error.message);
      }
    }
    final data = item['data'];
    final conversationId = data is Map ? data['conversation_id'] : null;
    if (conversationId is int && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ThreadPage(
            session: widget.session,
            api: _messages,
            conversationId: conversationId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PawLogo.green))
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _items.isEmpty
          ? const Center(child: Text('Aucune notification.'))
          : RefreshIndicator(
              color: PawLogo.green,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final unread = item['is_read'] != true;
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _open(item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: unread ? PawLogo.green : const Color(0xFFE3E8E4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (item['title'] ?? '').toString(),
                                    style: TextStyle(
                                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if ((item['body'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item['body'].toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ],
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
}
