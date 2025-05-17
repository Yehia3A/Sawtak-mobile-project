// lib/screens/chat_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat.service.dart';
import '../services/user.serivce.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  Chat? _chat;
  String? _role;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final uid = _auth.currentUser!.uid;
    _role = await UserService().fetchUserRole(uid);

    if (_role == 'Gov Admin') return setState(() {}); // Gov sees list instead

    final chat = await _chatService.startOrGetChat(_role!);
    setState(() => _chat = chat);
    if (_chat != null) {
      _getChatStream(_chat!.id).listen((doc) {
        final isEnded = doc['isEnded'] ?? false;
        if (isEnded && mounted) {
          _showChatEndedPopup(); // show dialog
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == 'Gov Admin') {
      return _buildAgentChatList();
    }

if (_chat == null) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
return _buildChatUI();
  }

  Widget _buildChatUI() {
    return Container(
  decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/chat_bg.png'), // Your image file
      fit: BoxFit.cover,
    ),
  ),
  child: Scaffold(
    backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final confirm = await showEndChatDialog(context);
              if (confirm) {
                await _chatService.endChat(_chat!.id);
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(_chat!.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _auth.currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.content),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;
                    await _chatService.sendMessage(_chat!.id, _controller.text.trim());
                    _controller.clear();
                  },
                )
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAgentChatList() {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  return Scaffold(
    appBar: AppBar(title: const Text('Chats')),
    body: StreamBuilder<List<Chat>>(
      stream: _chatService.getAssignedChats(currentUser.uid),
      builder: (context, assignedSnapshot) {
        if (!assignedSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignedChats = assignedSnapshot.data!;
        if (assignedChats.isNotEmpty) {
          // ✅ Show only the currently assigned chat
          final chat = assignedChats.first;
          return ListView(
            children: [
              ListTile(
                title: Text(chat.role),
                subtitle: const Text('Assigned to you'),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPageAssigned(chatId: chat.id),
                    ),
                  );
                },
              )
            ],
          );
        } else {
          // ✅ Show unassigned chats
          return StreamBuilder<List<Chat>>(
            stream: _chatService.getUnassignedChats(),
            builder: (context, unassignedSnapshot) {
              if (!unassignedSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final unassignedChats = unassignedSnapshot.data!;
              return ListView.builder(
                itemCount: unassignedChats.length,
                itemBuilder: (context, index) {
                  final chat = unassignedChats[index];
                  return ListTile(
                    title: Text(chat.role),
                    subtitle: const Text('Tap to assign and respond'),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () async {
                      await _chatService.assignAgentToChat(chat.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPageAssigned(chatId: chat.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        }
      },
    ),
  );
}
void _showChatEndedPopup() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Chat Ended'),
      content: Text('This chat has been ended by the admin.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pushReplacementNamed('/home'); // adjust if needed
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
}

Stream<DocumentSnapshot> _getChatStream(String chatId) {
  return FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots();
}

}

class ChatPageAssigned extends StatefulWidget {
  final String chatId;
  const ChatPageAssigned({super.key, required this.chatId});

  @override
  State<ChatPageAssigned> createState() => _ChatPageAssignedState();
}

class _ChatPageAssignedState extends State<ChatPageAssigned> {
  final _controller = TextEditingController();
  final _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
      return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/chat_bg.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final confirm = await showEndChatDialog(context);
              if (confirm) {
                await _chatService.endChat(widget.chatId);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == FirebaseAuth.instance.currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.content),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;
                    await _chatService.sendMessage(widget.chatId, _controller.text.trim());
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

Future<bool> showEndChatDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('End this chat?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('End'),
        ),
      ],
    ),
  ) ?? false;
}