import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Chat> startOrGetChat(String role) async {
    final userId = _auth.currentUser!.uid;
    final chats = await _fs.collection('chats')
      .where('userId', isEqualTo: userId)
      .where('isActive', isEqualTo: true)
      .get();

    if (chats.docs.isNotEmpty) {
      final doc = chats.docs.first;
      return Chat.fromMap(doc.id, doc.data());
    }

    final newDoc = await _fs.collection('chats').add({
      'userId': userId,
      'role': role,
      'agentId': null,
      'isActive': true,
    });

    return Chat(id: newDoc.id, userId: userId, role: role, isActive: true);
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _fs.collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  Future<void> sendMessage(String chatId, String content) async {
    final msg = Message(
      senderId: _auth.currentUser!.uid,
      content: content,
      timestamp: DateTime.now(),
    );

    await _fs.collection('chats').doc(chatId).collection('messages').add(msg.toMap());
  }

  Future<void> endChat(String chatId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({'isEnded': true});
  }

  Future<void> assignAgentToChat(String chatId) async {
    final agentId = _auth.currentUser!.uid;
    await _fs.collection('chats').doc(chatId).update({'agentId': agentId});
  }

  Stream<List<Chat>> getUnassignedChats() {
    return _fs.collection('chats')
      .where('agentId', isNull: true)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Chat.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<Chat>> getAssignedChats(String agentId) {
    return _fs.collection('chats')
      .where('agentId', isEqualTo: agentId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Chat.fromMap(doc.id, doc.data())).toList());
  }
}