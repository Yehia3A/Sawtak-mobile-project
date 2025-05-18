import 'package:cloud_firestore/cloud_firestore.dart';

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
      'createdAt': createdAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'comments': comments.map((x) => x.toMap()).toList(),
      'attachments': attachments.map((x) => x.toMap()).toList(),
    };
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      print('Invalid date type: $value ([33m${value.runtimeType}[0m)');
      return DateTime.now();
    }

    return Post(
      id: doc.id,
      title: data['title'] as String,
      content: data['content'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: parseDate(data['createdAt']),
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
      'createdAt': createdAt.toIso8601String(),
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
      createdAt: DateTime.parse(map['createdAt'] as String),
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
    required this.endDate,
    this.showResults = true,
    List<String>? votedUserIds,
    List<Attachment> attachments = const [],
    List<Comment> comments = const [],
  }) : votedUserIds = votedUserIds ?? [],
       super(type: PostType.poll, attachments: attachments, comments: comments);

  bool get isExpired => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'options': options.map((option) => option.toMap()).toList(),
      'votedUserIds': votedUserIds,
      'endDate': endDate.toIso8601String(),
      'showResults': showResults,
    };
  }

  factory Poll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      print('Invalid date type: $value (${value.runtimeType})');
      return DateTime.now();
    }

    final comments =
        (data['comments'] as List<dynamic>?)
            ?.map((x) => Comment.fromMap(x as Map<String, dynamic>))
            .toList() ??
        [];

    return Poll(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: parseDate(data['createdAt']),
      options:
          (data['options'] as List<dynamic>)
              .map(
                (option) => PollOption.fromMap(option as Map<String, dynamic>),
              )
              .toList(),
      votedUserIds: List<String>.from(data['votedUserIds'] ?? []),
      endDate: parseDate(data['endDate']),
      showResults: data['showResults'] ?? true,
      attachments:
          (data['attachments'] as List<dynamic>?)
              ?.map(
                (attachment) =>
                    Attachment.fromMap(attachment as Map<String, dynamic>),
              )
              .toList() ??
          [],
      comments: comments,
    );
  }

  Poll copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    List<PollOption>? options,
    List<String>? votedUserIds,
    DateTime? endDate,
    bool? showResults,
    List<Attachment>? attachments,
  }) {
    return Poll(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      options: options ?? this.options,
      votedUserIds: votedUserIds ?? this.votedUserIds,
      endDate: endDate ?? this.endDate,
      showResults: showResults ?? this.showResults,
      attachments: attachments ?? this.attachments,
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
    return PollOption(text: map['text'] ?? '', votes: map['votes'] ?? 0);
  }

  PollOption copyWith({String? text, int? votes}) {
    return PollOption(text: text ?? this.text, votes: votes ?? this.votes);
  }
}
