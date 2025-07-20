import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:decentralized_chat/signaling.dart';

class CallScreen extends StatefulWidget {
  final String ip;

  const CallScreen({super.key, required this.ip});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isCameraOff = false;
  late final Signaling _signaling;
  RTCPeerConnection? _peerConnection;

  @override
  void initState() {
    super.initState();
    try {
      initRenderers();
      _signaling = Signaling('wss://${widget.ip}:8080');
      _signaling.connect();
      _signaling.onMessage.listen((message) {
        if (message['type'] == 'offer') {
          _handleOffer(message);
        } else if (message['type'] == 'answer') {
          _handleAnswer(message);
        } else if (message['type'] == 'candidate') {
          _handleCandidate(message);
        }
      });
      _createPeerConnection();
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signaling.close();
    _peerConnection?.dispose();
    super.dispose();
  }

  void initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _createPeerConnection() async {
    try {
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      }, {
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      });

      _peerConnection!.onIceCandidate = (candidate) {
        _signaling.send({
          'type': 'candidate',
          'candidate': {
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          },
        });
      };

      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video') {
          _remoteRenderer.srcObject = event.streams[0];
        }
      };

      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });

      _localRenderer.srcObject = stream;
      stream.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, stream);
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _handleOffer(Map<String, dynamic> offer) async {
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      final answer = await _peerConnection!.createAnswer({});
      await _peerConnection!.setLocalDescription(answer);
      _signaling.send({
        'type': 'answer',
        'sdp': answer.sdp,
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _handleAnswer(Map<String, dynamic> answer) {
    try {
      _peerConnection!.setRemoteDescription(
        RTCSessionDescription(answer['sdp'], answer['type']),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _handleCandidate(Map<String, dynamic> candidate) {
    try {
      _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidate['candidate']['candidate'],
          candidate['candidate']['sdpMid'],
          candidate['candidate']['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _createOffer() async {
    try {
      final offer = await _peerConnection!.createOffer({});
      await _peerConnection!.setLocalDescription(offer);
      _signaling.send({
        'type': 'offer',
        'sdp': offer.sdp,
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              _createOffer();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: SizedBox(
              width: 100,
              height: 150,
              child: RTCVideoView(_localRenderer),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "mute",
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
              });
            },
            child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "camera",
            onPressed: () {
              setState(() {
                _isCameraOff = !_isCameraOff;
              });
            },
            child: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "end_call",
            onPressed: () {
              Navigator.pop(context);
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }
}
