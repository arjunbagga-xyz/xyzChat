import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:libp2p/libp2p.dart';

class Network {
  late final PeerId _peerId;
  late final Libp2p _node;
  final _messageController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messages => _messageController.stream;

  Future<void> start() async {
    try {
      // Create a new peer identity
      _peerId = await PeerId.create();

      // Create a new libp2p node
      _node = Libp2p(
        peerId: _peerId,
        transports: [
          TCP(),
          WebSockets(),
        ],
        services: [
          GossipSub(),
        ],
      );

      // Start the node
      await _node.start();

      print('Node started with peer ID: ${_node.peerId.toB58String()}');

      _node.handle('/file/1.0.0', (stream) async {
        try {
          final sink = stream.sink;
          final source = stream.source;

          // Read the file info
          final fileInfoJson = utf8.decode(await source.first);
          final fileInfo = json.decode(fileInfoJson);
          final fileName = fileInfo['name'];
          final fileSize = fileInfo['size'];

          // Create a new file
          final file = File(fileName);
          final fileSink = file.openWrite();

          // Read the file data
          var receivedBytes = 0;
          await for (var chunk in source) {
            fileSink.add(chunk);
            receivedBytes += chunk.length;
            if (receivedBytes == fileSize) {
              break;
            }
          }

          await fileSink.close();
          _messageController.add(file);
        } catch (e) {
          print('Error handling file stream: $e');
        }
      });
    } catch (e) {
      print('Error starting network: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _node.stop();
    } catch (e) {
      print('Error stopping network: $e');
    }
  }

  void subscribe(String topic) {
    try {
      _node.pubsub.subscribe(topic);
      _node.pubsub.stream.listen((message) {
        _messageController.add(utf8.decode(message.data));
      });
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  void publish(String topic, String message) {
    try {
      _node.pubsub.publish(topic, utf8.encode(message));
    } catch (e) {
      print('Error publishing to topic: $e');
    }
  }

  Future<void> sendFile(PeerId peerId, File file) async {
    try {
      final stream = await _node.dial(peerId, ['/file/1.0.0']);
      final sink = stream.sink;
      final source = file.openRead();

      // Send the file info
      final fileInfo = {
        'name': file.path.split('/').last,
        'size': await file.length(),
      };
      sink.add(utf8.encode(json.encode(fileInfo)));

      // Send the file data
      await for (var chunk in source) {
        sink.add(chunk);
      }

      await sink.close();
    } catch (e) {
      print('Error sending file: $e');
    }
  }
}
