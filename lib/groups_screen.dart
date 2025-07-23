import 'dart:io';

import 'package:decentralized_chat/create_group_screen.dart';
import 'package:decentralized_chat/group.dart';
import 'package:decentralized_chat/group_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
      body: AnimationLimiter(
        child: ListView.builder(
          itemCount: _groups.length,
          itemBuilder: (context, index) {
            final group = _groups[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: ListTile(
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
                          builder: (context) =>
                              GroupChatScreen(groupName: group.name),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
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
