import 'dart:async';
import 'dart:convert';

import 'package:p2plib/p2plib.dart';

class Network {
  late final P2PClient _client;
  final _messageController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messages => _messageController.stream;

  Future<void> start() async {
    _client = P2PClient(
      onMessage: (message) {
        _messageController.add(message);
      },
    );
    await _client.listen();
    print('P2P client listening on ${_client.address}');
  }

  void broadcast(String message) {
    _client.broadcast(message);
  }

  Future<void> stop() async {
    await _client.close();
  }
}
