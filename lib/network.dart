// FILEPATH: lib/network.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Network {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final _messageController = StreamController<String>.broadcast();

  late final WebSocketChannel _signalingChannel;

  Stream<String> get messages => _messageController.stream;

  /// Connects to signaling server and sets up WebRTC peer connection.
  Future<void> start(String signalingServerUrl) async {
    _signalingChannel = WebSocketChannel.connect(Uri.parse(signalingServerUrl));

    _signalingChannel.stream.listen(_onSignalingMessage, onDone: () {
      print('Signaling connection closed');
    }, onError: (error) {
      print('Signaling error: $error');
    });

    final config = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _sendSignal({
          'type': 'candidate',
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _setupDataChannel();
    };

    // Create data channel if this is the caller
    _dataChannel = await _peerConnection!.createDataChannel('chat', RTCDataChannelInit());
    _setupDataChannel();

    // Create and send offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignal({
      'type': 'offer',
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });

    print('WebRTC peer connection and data channel created, offer sent');
  }

  void _setupDataChannel() {
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      _messageController.add(message.text);
    };
  }

  void _onSignalingMessage(dynamic message) async {
    final Map<String, dynamic> map = jsonDecode(message);

    switch (map['type']) {
      case 'offer':
        {
          final description = RTCSessionDescription(map['sdp'], map['sdpType']);
          await _peerConnection!.setRemoteDescription(description);
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          _sendSignal({
            'type': 'answer',
            'sdp': answer.sdp,
            'sdpType': answer.type,
          });
          break;
        }
      case 'answer':
        {
          final description = RTCSessionDescription(map['sdp'], map['sdpType']);
          await _peerConnection!.setRemoteDescription(description);
          break;
        }
      case 'candidate':
        {
          final candidateMap = map['candidate'];
          final candidate = RTCIceCandidate(
            candidateMap['candidate'],
            candidateMap['sdpMid'],
            candidateMap['sdpMLineIndex'],
          );
          await _peerConnection!.addCandidate(candidate);
          break;
        }
      default:
        print('Unknown signaling message type: ${map['type']}');
    }
  }

  void _sendSignal(Map<String, dynamic> data) {
    _signalingChannel.sink.add(jsonEncode(data));
  }

  /// Sends a message over the data channel.
  void broadcast(String message) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  /// Closes connections and cleans up.
  Future<void> stop() async {
    await _dataChannel?.close();
    await _peerConnection?.close();
    await _signalingChannel.sink.close();
    _messageController.close();
  }

  /// Subscribes to incoming messages stream.
  Stream<String> subscribe() => _messageController.stream;

  /// Publishes a message locally to the stream.
  void publish(String message) {
    _messageController.add(message);
  }

  void dispose() {
    _messageController.close();
  }
}