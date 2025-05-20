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
        final data = doc.data() as Map<String, dynamic>?;
        final isEnded =
            data != null && data.containsKey('isEnded')
                ? data['isEnded'] ?? false
                : false;
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Chat', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () async {
                final confirm = await showEndChatDialog(context);
                if (confirm) {
                  await _chatService.endChat(_chat!.id);
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
                stream: _chatService.getMessages(_chat!.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == _auth.currentUser!.uid;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isMe
                                    ? const Color(0xFFF9EBC8)
                                    : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 6),
                              bottomRight: Radius.circular(isMe ? 6 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border:
                                isMe
                                    ? Border.all(
                                      color: const Color(0xFFA77A37),
                                      width: 1.5,
                                    )
                                    : null,
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              color:
                                  isMe
                                      ? const Color(0xFF7A5A1E)
                                      : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
<<<<<<< Updated upstream
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
=======
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
>>>>>>> Stashed changes
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
<<<<<<< Updated upstream
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
=======
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFA77A37)),
>>>>>>> Stashed changes
                      onPressed: () async {
                        if (_controller.text.trim().isEmpty) return;
                        await _chatService.sendMessage(
                          _chat!.id,
                          _controller.text.trim(),
                        );
                        _controller.clear();
                      },
                    ),
                  ],
                ),
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
        stream: _chatService.getAssignedChats(_auth.currentUser?.uid ?? ''),
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
                ),
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
      builder:
          (context) => AlertDialog(
            title: Text('Chat Ended'),
            content: Text('This chat has been ended by the admin.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  String targetRoute = '/home';
                  if (_role == 'Citizen') targetRoute = '/citizenHome';
                  if (_role == 'Advertiser') targetRoute = '/advertiserHome';

                  Navigator.of(context).pushReplacementNamed(targetRoute);
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Stream<DocumentSnapshot> _getChatStream(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .snapshots();
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
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Chat', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
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
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMe =
                          msg.senderId ==
                          FirebaseAuth.instance.currentUser!.uid;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe ? Color(0xFFEACE9F) : Color(0xFFA77A37),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                isMe
                                    ? Border.all(
                                      color: Color(0xFFA77A37),
                                      width: 2,
                                    )
                                    : null,
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () async {
                        if (_controller.text.trim().isEmpty) return;
                        await _chatService.sendMessage(
                          widget.chatId,
                          _controller.text.trim(),
                        );
                        _controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatEndedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Chat Ended'),
            content: Text('This chat has been ended by the user.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/govHome');
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc['isEnded'] == true && mounted) {
            _showChatEndedPopup();
          }
        });
  }
}

Future<bool> showEndChatDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
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
      ) ??
      false;
}
