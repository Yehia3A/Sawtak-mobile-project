import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/posts.service.dart';
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
  List<Post> _posts = [];
  bool _isLoading = true;
  String _error = '';
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      final posts =
          await _postsService.getPosts(userRole: widget.userRole).first;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load posts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _postsService.deletePost(postId: postId, userRole: widget.userRole);
      setState(() {
        _posts.removeWhere((post) => post.id == postId);
      });
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

  List<Post> _getFilteredPosts() {
    switch (_selectedFilter) {
      case 'Announcements':
        return _posts.where((post) => post is! Poll).toList();
      case 'Polls':
        return _posts.where((post) => post is Poll).toList();
      default:
        return _posts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _getFilteredPosts();
    return Scaffold(
      appBar: AppBar(
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
        title: Text(
          _selectedFilter == 'Announcements' ? 'Announcements' : 'Posts',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPosts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : filteredPosts.isEmpty
                  ? Center(
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
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
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
