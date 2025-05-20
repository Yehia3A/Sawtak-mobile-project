import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';
import 'notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _postsCollection = 'posts';
  final String _apiUrl =
      "https://api-inference.huggingface.co/models/cardiffnlp/twitter-roberta-base-offensive";
  final String _apiKey = "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";

  // Create a new announcement (admin only)
  Future<Post> createAnnouncement({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required String userRole,
    List<Attachment> attachments = const [],
  }) async {
    if (userRole != 'gov_admin') {
      throw Exception(
        'Only government administrators can create announcements',
      );
    }

    try {
      final post = Post(
        id: const Uuid().v4(),
        title: title,
        content: content,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        type: PostType.announcement,
        attachments: attachments,
      );

      await _firestore
          .collection(_postsCollection)
          .doc(post.id)
          .set(post.toMap());
      // Send notification to all users
      await NotificationService.instance.sendNotificationToAll(
        'New Announcement',
        title,
        data: {'type': 'announcement', 'id': post.id},
      );
      return post;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  // Create a new poll (admin only)
  Future<Poll> createPoll({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required List<PollOption> options,
    required String userRole,
    required DateTime endDate,
    bool showResults = true,
    List<Attachment> attachments = const [],
  }) async {
    if (userRole != 'gov_admin') {
      throw Exception('Only government administrators can create polls');
    }

    try {
      if (options.length < 2) {
        throw Exception('A poll must have at least 2 options');
      }
      if (endDate.isBefore(DateTime.now())) {
        throw Exception('End date must be in the future');
      }

      final poll = Poll(
        id: const Uuid().v4(),
        title: title,
        content: content,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        options: options,
        endDate: endDate,
        showResults: showResults,
        attachments: attachments,
        votedUserIds: [],
      );

      await _firestore
          .collection(_postsCollection)
          .doc(poll.id)
          .set(poll.toMap());
      // Send notification to all users
      await NotificationService.instance.sendNotificationToAll(
        'New Poll',
        title,
        data: {'type': 'poll', 'id': poll.id},
      );
      return poll;
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  // Get all posts with pagination
  Stream<List<Post>> getPosts({int limit = 20, String? userRole}) {
    return _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final post = Post.fromFirestore(doc);
                if (post.type == PostType.poll) {
                  final poll = Poll.fromFirestore(doc);
                  if (poll.isExpired && userRole != 'gov_admin') {
                    return null;
                  }
                  return poll;
                }
                return post;
              })
              .where((post) => post != null)
              .cast<Post>()
              .toList();
        });
  }

  // Check if a comment is toxic
  Future<bool> isCommentToxic(String text) async {
    try {
      if (_isArabic(text)) {
        // Arabic: Use local Flask API
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> result = jsonDecode(response.body);
          if (result['toxic'] == true) {
            return true;
          }
        }
        return false;
      } else {
        // English: Use HuggingFace API
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"inputs": text}),
        );

        if (response.statusCode == 200) {
          final List<dynamic> result = jsonDecode(response.body);
          if (result.isNotEmpty && result[0] is List) {
            final List<dynamic> predictions = result[0];
            for (var prediction in predictions) {
              if (prediction['label'] == 'offensive' &&
                  prediction['score'] > 0.5) {
                return true;
              }
            }
          }
        }
        return false;
      }
    } catch (e) {
      print('Error checking comment toxicity: $e');
      return false;
    }
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String text,
    required String userId,
    required String userName,
    required bool isAnonymous,
    String? parentCommentId,
    String? userProfileImage,
  }) async {
    try {
      // Check if comment is toxic
      final isToxic = await isCommentToxic(text);
      if (isToxic) {
        throw Exception(
          'Your comment contains inappropriate content. Please revise and try again.',
        );
      }

      final comment = Comment(
        id: const Uuid().v4(),
        text: text,
        userId: isAnonymous ? null : userId,
        userName: isAnonymous ? 'Anonymous' : userName,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
        userProfileImage: isAnonymous ? null : userProfileImage,
      );

      final postDoc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final comments = List<Map<String, dynamic>>.from(
        postDoc.data()?['comments'] ?? [],
      );
      if (parentCommentId == null) {
        comments.add(comment.toMap());
      } else {
        final parentCommentIndex = comments.indexWhere(
          (c) => c['id'] == parentCommentId,
        );
        if (parentCommentIndex == -1) {
          throw Exception('Parent comment not found');
        }
        if (comments[parentCommentIndex]['replies'] == null) {
          comments[parentCommentIndex]['replies'] = [];
        }
        comments[parentCommentIndex]['replies'].add(comment.toMap());
      }

      await _firestore.collection(_postsCollection).doc(postId).update({
        'comments': comments,
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Vote on a poll
  Future<void> voteOnPoll({
    required String postId,
    required String userId,
    required String optionText, // Changed to match PollOption.text
  }) async {
    final pollRef = _firestore.collection(_postsCollection).doc(postId);

    try {
      await _firestore.runTransaction((transaction) async {
        final pollDoc = await transaction.get(pollRef);
        if (!pollDoc.exists) {
          throw Exception('Poll not found');
        }

        final poll = Poll.fromFirestore(pollDoc);
        if (poll.isExpired) {
          throw Exception('This poll has expired');
        }

        if (poll.votedUserIds.contains(userId)) {
          throw Exception('You have already voted on this poll');
        }

        final optionIndex = poll.options.indexWhere(
          (opt) => opt.text == optionText,
        );
        if (optionIndex == -1) {
          throw Exception('Invalid option');
        }

        final options = List<PollOption>.from(poll.options);
        options[optionIndex] = PollOption(
          text: options[optionIndex].text,
          votes: options[optionIndex].votes + 1,
        );
        final votedUserIds = List<String>.from(poll.votedUserIds)..add(userId);

        transaction.update(pollRef, {
          'options': options.map((opt) => opt.toMap()).toList(),
          'votedUserIds': votedUserIds,
        });
      });
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  // Check if a user has voted on a poll
  Future<bool> hasUserVoted({
    required String postId,
    required String userId,
  }) async {
    try {
      final pollDoc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (!pollDoc.exists) return false;

      final poll = Poll.fromFirestore(pollDoc);
      return poll.votedUserIds.contains(userId);
    } catch (e) {
      throw Exception('Failed to check vote status: $e');
    }
  }

  // Delete a post (admin only)
  Future<void> deletePost({
    required String postId,
    required String userRole,
  }) async {
    if (userRole != 'gov_admin') {
      throw Exception('Only government administrators can delete posts');
    }

    try {
      await _firestore.collection(_postsCollection).doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Delete a comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
    required String userRole,
  }) async {
    try {
      final postDoc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final comments = List<Map<String, dynamic>>.from(
        postDoc.data()?['comments'] ?? [],
      );
      final commentIndex = comments.indexWhere((c) => c['id'] == commentId);

      if (commentIndex == -1) {
        throw Exception('Comment not found');
      }

      final comment = comments[commentIndex];
      if (comment['userId'] != userId && userRole != 'gov_admin') {
        throw Exception(
          'You can only delete your own comments or you must be an admin',
        );
      }

      comments.removeAt(commentIndex);

      await _firestore.collection(_postsCollection).doc(postId).update({
        'comments': comments,
      });
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get a single post by ID
  Future<Post?> getPost(String postId) async {
    try {
      final doc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == 'poll'
          ? Poll.fromFirestore(doc)
          : Post.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  // Add attachment to a post
  Future<void> addAttachment({
    required String postId,
    required String name,
    required String url,
    required String type,
  }) async {
    try {
      final attachment = Attachment(
        id: const Uuid().v4(),
        name: name,
        url: url,
        type: type,
      );

      await _firestore.collection(_postsCollection).doc(postId).update({
        'attachments': FieldValue.arrayUnion([attachment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add attachment: $e');
    }
  }

  // Remove attachment from a post
  Future<void> removeAttachment({
    required String postId,
    required String attachmentId,
    required String userRole,
  }) async {
    if (userRole != 'gov_admin') {
      throw Exception('Only government administrators can remove attachments');
    }

    try {
      final postDoc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final attachments = List<Map<String, dynamic>>.from(
        postDoc.data()?['attachments'] ?? [],
      );
      final attachmentIndex = attachments.indexWhere(
        (a) => a['id'] == attachmentId,
      );

      if (attachmentIndex == -1) {
        throw Exception('Attachment not found');
      }

      attachments.removeAt(attachmentIndex);

      await _firestore.collection(_postsCollection).doc(postId).update({
        'attachments': attachments,
      });
    } catch (e) {
      throw Exception('Failed to remove attachment: $e');
    }
  }

  // Helper: Detect if text is Arabic
  bool _isArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}
