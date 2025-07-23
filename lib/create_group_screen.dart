import 'dart:io';

import 'package:decentralized_chat/group.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _profilePicture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                _profilePicture = await _picker.pickImage(source: ImageSource.gallery);
                setState(() {});
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profilePicture != null
                    ? FileImage(File(_profilePicture!.path))
                    : null,
                child: _profilePicture == null
                    ? const Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add a way to select members
            ElevatedButton(
              onPressed: () {
                final newGroup = Group(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: _nameController.text,
                  profilePicture: _profilePicture?.path,
                  members: [], // TODO: Add members
                );
                Navigator.pop(context, newGroup);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
