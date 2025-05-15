import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      content: map['content'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class Chat {
  final String id;
  final String userId;
  final String role;
  final String? agentId;
  final bool isActive;

  Chat({
    required this.id,
    required this.userId,
    required this.role,
    this.agentId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'agentId': agentId,
      'isActive': isActive,
    };
  }

  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    return Chat(
      id: id,
      userId: map['userId'],
      role: map['role'],
      agentId: map['agentId'],
      isActive: map['isActive'],
    );
  }
}