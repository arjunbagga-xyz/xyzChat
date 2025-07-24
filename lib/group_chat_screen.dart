import 'dart:io';

import 'package:decentralized_chat/chat_bubble.dart';
import 'package:decentralized_chat/group_management_screen.dart';
import 'package:decentralized_chat/network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:intl/intl.dart';

import 'group.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupName;

  const GroupChatScreen({super.key, required this.groupName});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final network = Network();
  final picker = ImagePicker();
  final record = Record();
  final audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _audioPath;
  String _username = 'user';
  final _crypt = Cryptor(algo: Algo.aes, key: 'a' * 32, iv: 'b' * 16);

  @override
  void initState() {
    super.initState();
    try {
      network.subscribe(widget.groupName);
      network.messages.listen((message) {
        setState(() {
          final decryptedMessage = _decryptMessage(message);
          final sender = decryptedMessage.split(': ')[0];
          final text = decryptedMessage.split(': ')[1];
          _messages.add({
            'text': text,
            'isMe': sender == _username,
            'timestamp': DateTime.now(),
          });
        });
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  String _encryptMessage(String message) {
    return _crypt.encrypt(inp: '$_username: $message');
  }

  String _decryptMessage(String message) {
    return _crypt.decrypt(enc: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupManagementScreen(
                    group: Group(
                      id: 0,
                      name: widget.groupName,
                      members: [], // TODO: Get members from database
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                if (message['text'] is String) {
                  return ChatBubble(
                    message: message['text'],
                    isMe: message['isMe'],
                    timestamp: message['timestamp'],
                  ).animate().fade().slide();
                }
                return Container();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () async {
                    try {
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        final file = File(pickedFile.path);
                        // TODO: Select a peer to send the file to
                        // await network.sendFile(network.peerId, file);
                      }
                    } catch (e) {
                      _showErrorDialog(e.toString());
                    }
                  },
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: () async {
                    try {
                      if (await record.isRecording()) {
                        final path = await record.stop();
                        setState(() {
                          _isRecording = false;
                          _audioPath = path;
                          _messages.add({
                            'text': File(path!),
                            'isMe': true,
                            'timestamp': DateTime.now(),
                          });
                        });
                      } else {
                        if (await record.hasPermission()) {
                          await record.start();
                          setState(() {
                            _isRecording = true;
                          });
                        }
                      }
                    } catch (e) {
                      _showErrorDialog(e.toString());
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    try {
                      final message = _messageController.text;
                      network.publish(widget.groupName, _encryptMessage(message));
                      setState(() {
                        _messages.add({
                          'text': message,
                          'isMe': true,
                          'timestamp': DateTime.now(),
                        });
                      });
                      _messageController.clear();
                    } catch (e) {
                      _showErrorDialog(e.toString());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}
