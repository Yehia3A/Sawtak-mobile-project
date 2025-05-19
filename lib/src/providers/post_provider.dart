import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
    String? parentCommentId,
    bool isAnonymous = false,
    String? userProfileImage,
  }) async {
    try {
      // Get current post
      final docSnap = await _firestore.collection('posts').doc(postId).get();
      final post = Post.fromFirestore(docSnap);

      // Create new comment
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        text: text,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
        isAnonymous: isAnonymous,
        userProfileImage: userProfileImage,
        replies: [],
      );

      // Add comment to the post's comments list
      final updatedComments = [...post.comments, newComment];

      // Update post in Firestore
      await _firestore.collection('posts').doc(postId).update({
        'comments': updatedComments.map((c) => c.toMap()).toList(),
      });

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final docSnap = await _firestore.collection('posts').doc(postId).get();
      if (!docSnap.exists) {
        throw Exception('Post not found');
      }

      final post = Post.fromFirestore(docSnap);

      // Filter out the comment and its replies
      final updatedComments =
          post.comments
              .where(
                (comment) =>
                    comment.id != commentId &&
                    comment.parentCommentId != commentId,
              )
              .toList();

      // Update post in Firestore
      await _firestore.collection('posts').doc(postId).update({
        'comments': updatedComments.map((c) => c.toMap()).toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error deleting comment: $e');
      throw e;
    }
  }

  Future<void> addAttachment({
    required String postId,
    required Attachment attachment,
  }) async {
    try {
      // Get the current post document
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final post = Post.fromFirestore(postDoc);

      // Add new attachment to the list
      final updatedAttachments = [...post.attachments, attachment];

      // Update Firestore
      await _firestore.collection('posts').doc(postId).update({
        'attachments': updatedAttachments.map((a) => a.toMap()).toList(),
      });

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      print('Error adding attachment: $e');
      throw e;
    }
  }

  Future<void> deleteAttachment(String postId, String attachmentId) async {
    try {
      // Get the current post document
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final post = Post.fromFirestore(postDoc);

      // Remove the attachment
      final updatedAttachments =
          post.attachments.where((a) => a.id != attachmentId).toList();

      // Update Firestore
      await _firestore.collection('posts').doc(postId).update({
        'attachments': updatedAttachments.map((a) => a.toMap()).toList(),
      });

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      print('Error deleting attachment: $e');
      throw e;
    }
  }

  Future<void> votePoll({
    required String pollId,
    required String userId,
    required int optionIndex,
  }) async {
    try {
      // Get current poll
      final docSnap = await _firestore.collection('posts').doc(pollId).get();
      if (!docSnap.exists) throw Exception('Poll not found');

      final poll = Post.fromFirestore(docSnap) as Poll;
      if (poll.isExpired) throw Exception('Poll has ended');
      if (poll.votedUserIds.contains(userId)) throw Exception('Already voted');

      // Update the vote count for the selected option
      final updatedOptions = List<PollOption>.from(poll.options);
      updatedOptions[optionIndex] = PollOption(
        text: poll.options[optionIndex].text,
        votes: poll.options[optionIndex].votes + 1,
      );

      // Add user to voted list
      final updatedVotedUserIds = [...poll.votedUserIds, userId];

      // Update poll in Firestore
      await _firestore.collection('posts').doc(pollId).update({
        'options':
            updatedOptions
                .map((o) => {'text': o.text, 'votes': o.votes})
                .toList(),
        'votedUserIds': updatedVotedUserIds,
      });

      notifyListeners();
    } catch (e) {
      print('Error voting in poll: $e');
      throw e;
    }
  }

  Stream<Post> getPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) => Post.fromFirestore(doc));
  }

  Stream<List<Post>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Post>> getPostsByType(PostType type) {
    return _firestore
        .collection('posts')
        .where('type', isEqualTo: type.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }
}
