import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_config.dart';

class MessagesSocket {
  WebSocketChannel? _channel;

  static bool get skipInTests =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  Stream<Map<String, dynamic>>? connect(String token) {
    if (skipInTests) {
      return null;
    }
    final httpUri = Uri.parse(apiBaseUrl);
    final uri = httpUri.replace(
      scheme: httpUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/messaging/',
      queryParameters: {'token': token},
    );
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream.map((event) {
      final decoded = event is String ? jsonDecode(event) : event;
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return <String, dynamic>{};
    });
  }

  void close() {
    _channel?.sink.close();
    _channel = null;
  }
}
