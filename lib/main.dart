import 'dart:io';

import 'package:decentralized_chat/call_screen.dart';
import 'package:decentralized_chat/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:decentralized_chat/database.dart';
import 'package:decentralized_chat/network.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:steel_crypt/steel_crypt.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    print(details);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decentralized Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Decentralized Chat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final List<dynamic> _messages = [];
  final dbHelper = DatabaseHelper.instance;
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
      network.start();
      network.subscribe('chat');
      network.messages.listen((message) {
        setState(() {
          _messages.add(_decryptMessage(message));
        });
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  @override
  void dispose() {
    network.stop();
    super.dispose();
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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CallScreen(ip: "127.0.0.1")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsScreen()),
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
                if (message is String) {
                  return ListTile(
                    title: Text(message),
                  );
                } else if (message is File) {
                  if (message.path.endsWith('.m4a')) {
                    return ListTile(
                      title: Text(message.path.split('/').last),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          try {
                            audioPlayer.play(DeviceFileSource(message.path));
                          } catch (e) {
                            _showErrorDialog(e.toString());
                          }
                        },
                      ),
                    );
                  }
                  return ListTile(
                    title: Image.file(message),
                  );
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
                          _messages.add(File(path!));
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
                      network.publish('chat', _encryptMessage(_messageController.text));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final peerIdController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a new contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              TextField(
                controller: peerIdController,
                decoration: const InputDecoration(hintText: 'Peer ID'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                try {
                  await dbHelper.create(
                    Contact(
                      id: 0, // The database will assign an ID
                      name: nameController.text,
                      peerId: peerIdController.text,
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
            ),
          ],
        );
      },
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
