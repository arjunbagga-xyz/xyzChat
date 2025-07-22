import 'package:decentralized_chat/create_group_screen.dart';
import 'package:decentralized_chat/group.dart';
import 'package:decentralized_chat/group_chat_screen.dart';
import 'package:flutter/material.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final List<Group> _groups = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: group.profilePicture != null
                  ? FileImage(File(group.profilePicture!))
                  : null,
              child: group.profilePicture == null
                  ? const Icon(Icons.group)
                  : null,
            ),
            title: Text(group.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(groupName: group.name),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newGroup = await Navigator.push<Group>(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
          if (newGroup != null) {
            setState(() {
              _groups.add(newGroup);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

//Create a temporary File class to avoid errors
class File {
  final String path;
  File(this.path);
}
