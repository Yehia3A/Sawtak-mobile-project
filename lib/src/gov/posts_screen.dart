import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../services/posts.service.dart';
import '../widgets/post_card.dart';
import 'dart:async';

class GovPostsScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String userRole;

  const GovPostsScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<GovPostsScreen> createState() => _GovPostsScreenState();
}

class _GovPostsScreenState extends State<GovPostsScreen> {
  final PostsService _postsService = PostsService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Posts')),
      body: StreamBuilder<List<Post>>(
        stream: _postsService.getPosts(userRole: widget.userRole),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                currentUserId: widget.currentUserId,
                currentUserName: widget.currentUserName,
                postsService: _postsService,
                onDelete:
                    post.authorId == widget.currentUserId
                        ? () async {
                          try {
                            await _postsService.deletePost(
                              postId: post.id,
                              userRole: widget.userRole,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting post: $e'),
                                ),
                              );
                            }
                          }
                        }
                        : null,
                userRole: widget.userRole,
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
