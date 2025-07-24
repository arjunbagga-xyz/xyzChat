// FILEPATH: lib/berty_network.dart

import 'dart:async';
import 'package:flutter/services.dart';

class BertyNetwork {
  static const MethodChannel _methodChannel = MethodChannel('berty/bridge/methods');
  static const EventChannel _eventChannel = EventChannel('berty/bridge/events');

  final StreamController<String> _messageController = StreamController.broadcast();

  Stream<String> get messages => _messageController.stream;

  BertyNetwork() {
    _eventChannel.receiveBroadcastStream().listen(_onNativeEvent, onError: _onNativeError);
  }

  /// Starts the Berty protocol service.
  Future<void> start() async {
    try {
      await _methodChannel.invokeMethod('start');
    } catch (e) {
      print('Error starting Berty protocol: $e');
    }
  }

  /// Sends a message via Berty protocol.
  Future<void> broadcast(String message) async {
    try {
      await _methodChannel.invokeMethod('sendMessage', {'message': message});
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Stops the Berty protocol service.
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stop');
      await _messageController.close();
    } catch (e) {
      print('Error stopping Berty protocol: $e');
    }
  }

  void _onNativeEvent(dynamic event) {
    if (event is Map && event['type'] == 'message' && event['payload'] is String) {
      _messageController.add(event['payload']);
    }
  }

  void _onNativeError(Object error) {
    print('Native event error: $error');
  }

  void dispose() {
    _messageController.close();
  }
}
