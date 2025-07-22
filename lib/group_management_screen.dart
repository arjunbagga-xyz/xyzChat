import 'package:decentralized_chat/group.dart';
import 'package:flutter/material.dart';

class GroupManagementScreen extends StatefulWidget {
  final Group group;

  const GroupManagementScreen({super.key, required this.group});

  @override
  _GroupManagementScreenState createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.group.members.length,
              itemBuilder: (context, index) {
                final member = widget.group.members[index];
                return ListTile(
                  title: Text(member),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () {
                      // TODO: Implement removing a member
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement leaving the group
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave Group'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement adding a new member
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
