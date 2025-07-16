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
    initRenderers();
    _signaling = Signaling('ws://${widget.ip}:8080');
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
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _createPeerConnection() async {
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
  }

  void _handleOffer(Map<String, dynamic> offer) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    final answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);
    _signaling.send({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  void _handleAnswer(Map<String, dynamic> answer) {
    _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  void _handleCandidate(Map<String, dynamic> candidate) {
    _peerConnection!.addCandidate(
      RTCIceCandidate(
        candidate['candidate']['candidate'],
        candidate['candidate']['sdpMid'],
        candidate['candidate']['sdpMLineIndex'],
      ),
    );
  }

  void _createOffer() async {
    final offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);
    _signaling.send({
      'type': 'offer',
      'sdp': offer.sdp,
    });
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
