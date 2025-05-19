import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/posts.service.dart';

class PostsProvider extends ChangeNotifier {
  final PostsService _postsService = PostsService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String _error = '';

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String get error => _error;

  Stream<List<Post>> getPosts({String? userRole}) {
    return _postsService.getPosts(userRole: userRole);
  }

  Future<void> addComment({
    required String postId,
    required String text,
    required String userId,
    required String userName,
    String? parentCommentId,
    required bool isAnonymous,
  }) async {
    try {
      await _postsService.addComment(
        postId: postId,
        text: text,
        userId: userId,
        userName: userName,
        isAnonymous: false,
        parentCommentId: parentCommentId,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> voteOnPoll({
    required String postId,
    required String userId,
    required String optionText,
  }) async {
    try {
      await _postsService.voteOnPoll(
        postId: postId,
        userId: userId,
        optionText: optionText,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<bool> hasUserVoted({
    required String postId,
    required String userId,
  }) async {
    try {
      return await _postsService.hasUserVoted(postId: postId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }
}
