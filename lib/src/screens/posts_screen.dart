import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/citizen/post_details_screen.dart';
import 'package:gov_citizen_app/src/services/posts.service.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';

class PostsScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String userRole;
  final String initialFilter;

  const PostsScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.userRole,
    this.initialFilter = 'All',
  }) : super(key: key);

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostsService _postsService = PostsService();
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _postsService.deletePost(postId: postId, userRole: widget.userRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
      }
    }
  }

  List<Post> _getFilteredPosts(List<Post> posts) {
    switch (_selectedFilter) {
      case 'Announcements':
        return posts.where((post) => post is! Poll).toList();
      case 'Polls':
        return posts.where((post) => post is Poll).toList();
      default:
        return posts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
        title: Row(
          children: [
            Text(
              _selectedFilter == 'Announcements' ? 'Announcements' : 'Posts',
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedFilter,
              items:
                  ['All', 'Announcements', 'Polls'].map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFilter = value);
                }
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Post>>(
          stream: _postsService.getPosts(userRole: widget.userRole),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load posts: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final posts = snapshot.data ?? [];
            final filteredPosts = _getFilteredPosts(posts);
            if (filteredPosts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFilter == 'All'
                          ? Icons.post_add
                          : _selectedFilter == 'Announcements'
                          ? Icons.announcement
                          : Icons.poll,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_selectedFilter.toLowerCase()} yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 0,
                  right: 0,
                  bottom: 140, // Enough for nav bar + FAB
                ),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  return PostCard(
                    post: post,
                    currentUserId: widget.currentUserId,
                    currentUserName: widget.currentUserName,
                    postsService: _postsService,
                    onDelete:
                        widget.userRole == 'gov_admin'
                            ? () => _deletePost(post.id)
                            : null,
                    userRole: widget.userRole,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailsScreen(post: post),
                          ),
                        ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
