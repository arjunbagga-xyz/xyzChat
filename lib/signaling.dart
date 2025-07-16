import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';

class Signaling {
  final String _url;
  IOWebSocketChannel? _channel;
  final _onOpen = StreamController<void>.broadcast();
  final _onMessage = StreamController<dynamic>.broadcast();
  final _onClose = StreamController<void>.broadcast();

  Stream<void> get onOpen => _onOpen.stream;
  Stream<dynamic> get onMessage => _onMessage.stream;
  Stream<void> get onClose => _onClose.stream;

  Signaling(this._url);

  Future<void> connect() async {
    _channel = IOWebSocketChannel.connect(_url);
    _onOpen.add(null);
    _channel!.stream.listen((message) {
      _onMessage.add(json.decode(message));
    }, onDone: () {
      _onClose.add(null);
    });
  }

  void send(dynamic message) {
    _channel!.sink.add(json.encode(message));
  }

  Future<void> close() async {
    await _channel?.sink.close();
  }
}
