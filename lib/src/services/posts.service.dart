import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';

class PostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _postsCollection = 'posts';

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
    required List<String> options,
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
        options: options.map((text) => PollOption(text: text)).toList(),
        endDate: endDate,
        showResults: showResults,
        attachments: attachments,
      );

      await _firestore
          .collection(_postsCollection)
          .doc(poll.id)
          .set(poll.toMap());
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
                final data = doc.data();
                if (data['type'] == 'poll') {
                  final poll = Poll.fromFirestore(doc);
                  // Show expired polls only to admins
                  if (poll.isExpired && userRole != 'gov_admin') {
                    return null;
                  }
                  return poll;
                }
                return Post.fromFirestore(doc);
              })
              .where((post) => post != null)
              .cast<Post>()
              .toList();
        });
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String text,
    required String userId,
    required String userName,
    required bool isAnonymous,
  }) async {
    try {
      final comment = Comment(
        id: const Uuid().v4(),
        text: text,
        userId: isAnonymous ? null : userId,
        userName: isAnonymous ? 'Anonymous' : userName,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_postsCollection).doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Vote on a poll
  Future<void> votePoll({
    required String pollId,
    required String userId,
    required int optionIndex,
  }) async {
    final pollRef = _firestore.collection(_postsCollection).doc(pollId);

    try {
      await _firestore.runTransaction((transaction) async {
        final pollDoc = await transaction.get(pollRef);
        if (!pollDoc.exists) {
          throw Exception('Poll not found');
        }

        final poll = Poll.fromFirestore(pollDoc);

        // Check if poll has expired
        if (poll.isExpired) {
          throw Exception('This poll has expired');
        }

        // Check if user has already voted
        if (poll.votedUserIds.contains(userId)) {
          throw Exception('You have already voted on this poll');
        }

        // Validate option index
        if (optionIndex < 0 || optionIndex >= poll.options.length) {
          throw Exception('Invalid option index');
        }

        // Update the vote count for the selected option
        final options = List<Map<String, dynamic>>.from(
          pollDoc.data()!['options'],
        );
        options[optionIndex]['votes'] =
            (options[optionIndex]['votes'] ?? 0) + 1;

        // Add user to votedUserIds
        final votedUserIds = List<String>.from(
          pollDoc.data()!['votedUserIds'] ?? [],
        );
        votedUserIds.add(userId);

        // Update the document
        transaction.update(pollRef, {
          'options': options,
          'votedUserIds': votedUserIds,
        });
      });
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  // Check if a user has voted on a poll
  Future<bool> hasUserVoted({
    required String pollId,
    required String userId,
  }) async {
    try {
      final pollDoc =
          await _firestore.collection(_postsCollection).doc(pollId).get();
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
        postDoc.data()!['comments'] ?? [],
      );
      final commentIndex = comments.indexWhere((c) => c['id'] == commentId);

      if (commentIndex == -1) {
        throw Exception('Comment not found');
      }

      // Verify comment ownership or admin status
      final comment = comments[commentIndex];
      if (comment['userId'] != userId && userRole != 'gov_admin') {
        throw Exception('You can only delete your own comments');
      }

      comments.removeAt(commentIndex);

      await _firestore.collection(_postsCollection).doc(postId).update({
        'comments': comments,
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get a single post by ID
  Future<Post?> getPost(String postId) async {
    try {
      final doc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
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
        postDoc.data()!['attachments'] ?? [],
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
}
