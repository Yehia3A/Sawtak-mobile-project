import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseFirestoreDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is Map) {
    if (value['_seconds'] != null) {
      return Timestamp(value['_seconds'], value['_nanoseconds'] ?? 0).toDate();
    }
  }
  if (value is String) {
    final timestamp = DateTime.tryParse(value);
    if (timestamp != null) return timestamp;
  }
  if (value is DateTime) return value;
  print('Invalid date type: $value (${value.runtimeType})');
  return DateTime.now();
}

enum PostType { announcement, poll }

class Attachment {
  final String id;
  final String name;
  final String url;
  final String type; // 'pdf', 'image', etc.

  Attachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'url': url, 'type': type};
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
    );
  }
}

class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final PostType type;
  final List<Comment> comments;
  final List<Attachment> attachments;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.type,
    this.comments = const [],
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.toString().split('.').last,
      'comments': comments.map((x) => x.toMap()).toList(),
      'attachments': attachments.map((x) => x.toMap()).toList(),
    };
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      title: data['title'] as String,
      content: data['content'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: parseFirestoreDate(data['createdAt']),
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
      ),
      comments:
          (data['comments'] as List<dynamic>?)
              ?.map((x) => Comment.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      attachments:
          (data['attachments'] as List<dynamic>?)
              ?.map((x) => Attachment.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Comment {
  final String id;
  final String text;
  final String? userId;
  final String userName;
  final bool isAnonymous;
  final DateTime createdAt;
  final List<Comment> replies;
  final String? parentCommentId;
  final String? userProfileImage;

  Comment({
    required this.id,
    required this.text,
    this.userId,
    required this.userName,
    required this.isAnonymous,
    required this.createdAt,
    this.replies = const [],
    this.parentCommentId,
    this.userProfileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      'userName': userName,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'replies': replies.map((x) => x.toMap()).toList(),
      'parentCommentId': parentCommentId,
      'userProfileImage': userProfileImage,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      text: map['text'] as String,
      userId: map['userId'] as String?,
      userName: map['userName'] as String,
      isAnonymous: map['isAnonymous'] as bool,
      createdAt: parseFirestoreDate(map['createdAt']),
      replies:
          (map['replies'] as List<dynamic>?)
              ?.map((x) => Comment.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      parentCommentId: map['parentCommentId'] as String?,
      userProfileImage: map['userProfileImage'] as String?,
    );
  }
}

class Poll extends Post {
  final List<PollOption> options;
  final List<String> votedUserIds;
  final DateTime endDate;
  final bool showResults;

  Poll({
    required super.id,
    required super.title,
    required super.content,
    required super.authorId,
    required super.authorName,
    required super.createdAt,
    required this.options,
    required this.votedUserIds,
    required this.endDate,
    this.showResults = true,
    super.attachments = const [],
    super.comments = const [],
  }) : super(type: PostType.poll);

  bool get isExpired => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'options': options.map((option) => option.toMap()).toList(),
      'votedUserIds': votedUserIds,
      'endDate': Timestamp.fromDate(endDate),
      'showResults': showResults,
    };
  }

  factory Poll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Poll(
      id: doc.id,
      title: data['title'] as String,
      content: data['content'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: parseFirestoreDate(data['createdAt']),
      options:
          (data['options'] as List<dynamic>)
              .map(
                (option) => PollOption.fromMap(option as Map<String, dynamic>),
              )
              .toList(),
      votedUserIds: List<String>.from(data['votedUserIds'] ?? []),
      endDate: parseFirestoreDate(data['endDate']),
      showResults: data['showResults'] ?? true,
      attachments:
          (data['attachments'] as List<dynamic>?)
              ?.map(
                (attachment) =>
                    Attachment.fromMap(attachment as Map<String, dynamic>),
              )
              .toList() ??
          [],
      comments:
          (data['comments'] as List<dynamic>?)
              ?.map(
                (comment) => Comment.fromMap(comment as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class PollOption {
  final String text;
  final int votes;

  PollOption({required this.text, this.votes = 0});

  Map<String, dynamic> toMap() {
    return {'text': text, 'votes': votes};
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(text: map['text'] as String, votes: map['votes'] as int);
  }

  PollOption copyWith({String? text, int? votes}) {
    return PollOption(text: text ?? this.text, votes: votes ?? this.votes);
  }
}
