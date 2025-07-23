import 'dart:io';

import 'package:decentralized_chat/call_screen.dart';
import 'package:decentralized_chat/chat_bubble.dart';
import 'package:decentralized_chat/contacts_screen.dart';
import 'package:decentralized_chat/create_group_screen.dart';
import 'package:decentralized_chat/groups_screen.dart';
import 'package:decentralized_chat/settings_screen.dart';
import 'package:decentralized_chat/theme.dart';
import 'package:decentralized_chat/transitions.dart';
import 'package:flutter/material.dart';
import 'package:decentralized_chat/database.dart';
import 'package:decentralized_chat/network.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_animator/flutter_animator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:intl/intl.dart';

import 'group.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    print(details);
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _onThemeModeChanged(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decentralized Chat',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: MyHomePage(
        title: 'Decentralized Chat',
        themeMode: _themeMode,
        onThemeModeChanged: _onThemeModeChanged,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final String title;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  final dbHelper = DatabaseHelper.instance;
  final network = Network();
  final picker = ImagePicker();
  final record = Record();
  final audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _audioPath;
  String _username = 'user';
  final _crypt = Cryptor(algo: Algo.aes, key: 'a' * 32, iv: 'b' * 16);
  final GlobalKey<AnimatorWidgetState> _sendButtonKey =
      GlobalKey<AnimatorWidgetState>();

  @override
  void initState() {
    super.initState();
    _filteredMessages = _messages;
    _searchController.addListener(() {
      filterMessages();
    });
    try {
      network.start();
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

  @override
  void dispose() {
    network.stop();
    super.dispose();
  }

  void filterMessages() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _filteredMessages = _messages.where((message) {
          return message['text'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    } else {
      setState(() {
        _filteredMessages = _messages;
      });
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
    return GlassContainer(
      height: double.infinity,
      width: double.infinity,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.2),
          Theme.of(context).colorScheme.secondary.withOpacity(0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.5),
          Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      blur: 15,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageTransition(
                    page: SettingsScreen(
                      themeMode: widget.themeMode,
                      onThemeModeChanged: widget.onThemeModeChanged,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageTransition(page: const GroupsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageTransition(page: const CallScreen(ip: "127.0.0.1")),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.contacts),
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageTransition(page: const ContactsScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = _filteredMessages[index];
                    if (message['text'] is String) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: ChatBubble(
                              message: message['text'],
                              isMe: message['isMe'],
                              timestamp: message['timestamp'],
                            ),
                          ),
                        ),
                      );
                    }
                    return Container();
                  },
                ),
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
                  Swing(
                    key: _sendButtonKey,
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _sendButtonKey.currentState?.forward();
                        try {
                          final message = _messageController.text;
                          network.broadcast(_encryptMessage(message));
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
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.person_add),
              label: 'Add Contact',
              onTap: () => _showAddContactDialog(context),
            ),
            SpeedDialChild(
              child: const Icon(Icons.group_add),
              label: 'Create Group',
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageTransition(page: const CreateGroupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final peerIdController = TextEditingController();
    XFile? profilePicture;

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
              TextButton(
                onPressed: () async {
                  profilePicture = await picker.pickImage(source: ImageSource.gallery);
                },
                child: const Text('Select Profile Picture'),
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
                      profilePicture: profilePicture?.path,
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
