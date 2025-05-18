import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../services/posts.service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final String currentUserName;
  final PostsService postsService;
  final VoidCallback? onDelete;
  final String userRole;

  const PostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.postsService,
    this.onDelete,
    required this.userRole,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToUserName;
  bool _isAnonymous = false;
  bool _isExpanded = false;
  bool _showComments = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment({String? parentCommentId}) async {
    if (_commentController.text.trim().isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Post Comment'),
            content: const Text(
              'Do you want to post this comment anonymously?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Anonymous'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Anonymous'),
              ),
            ],
          ),
    );
    if (result == null) return;
    final isAnonymous = result;
    final userProfileImage =
        isAnonymous ? null : FirebaseAuth.instance.currentUser?.photoURL;

    try {
      await widget.postsService.addComment(
        postId: widget.post.id,
        text: _commentController.text.trim(),
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        isAnonymous: isAnonymous,
        parentCommentId: parentCommentId,
        userProfileImage: userProfileImage,
      );
      _commentController.clear();
      setState(() {
        _isAnonymous = false;
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
      _commentController.text = '';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _commentController.clear();
    });
  }

  Future<void> _votePoll(int optionIndex) async {
    if (widget.post is! Poll) return;

    try {
      await widget.postsService.votePoll(
        pollId: widget.post.id,
        userId: widget.currentUserId,
        optionIndex: optionIndex,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error voting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        widget.currentUserName == 'Admin' ||
        widget.currentUserId == 'gov_admin';
    final hasImage = widget.post.attachments.any(
      (a) => a.type.startsWith('image/'),
    );
    final isPoll = widget.post is Poll;
    final isCitizen = widget.userRole == 'citizen';
    final poll = isPoll ? widget.post as Poll : null;
    final hasVoted =
        isPoll && poll!.votedUserIds.contains(widget.currentUserId);
    final pollExpired = isPoll && poll!.isExpired;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info and menu
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    widget.post.authorName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy • hh:mm a',
                        ).format(widget.post.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),

          // Post image if available
          if (hasImage)
            CachedNetworkImage(
              imageUrl:
                  widget.post.attachments
                      .firstWhere((a) => a.type.startsWith('image/'))
                      .url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              placeholder:
                  (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
            ),

          // Post content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.post.content, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),

          // Poll section if it's a poll
          if (isPoll) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCitizen && !pollExpired && !hasVoted)
                    ...poll!.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await _votePoll(index);
                            setState(() {});
                          },
                          child: Text(option.text),
                        ),
                      );
                    }).toList(),
                  if (!isCitizen || pollExpired || hasVoted)
                    _buildPollResults(context, poll!),
                ],
              ),
            ),
          ],

          // Comments section
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed:
                      () => setState(() => _showComments = !_showComments),
                ),
                Text(
                  '${widget.post.comments.length} Comments',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Comments list
          if (_showComments && widget.post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children:
                    widget.post.comments
                        .where((c) => c.parentCommentId == null)
                        .map((comment) => _buildCommentItem(comment, 0))
                        .toList(),
              ),
            ),

          // Comment input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyingToCommentId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to $_replyingToUserName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cancelReply,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText:
                              _replyingToCommentId == null
                                  ? 'Write a comment...'
                                  : 'Write a reply...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed:
                          () => _addComment(
                            parentCommentId: _replyingToCommentId,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollResults(BuildContext context, Poll poll) {
    final totalVotes = poll.options.fold<int>(
      0,
      (sum, option) => sum + option.votes,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: poll.isExpired ? Colors.red[100] : Colors.blue[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            poll.isExpired
                ? 'Poll ended on ${DateFormat('MMM dd, yyyy hh:mm a').format(poll.endDate)}'
                : 'Ends on ${DateFormat('MMM dd, yyyy hh:mm a').format(poll.endDate)}',
            style: TextStyle(
              color: poll.isExpired ? Colors.red[900] : Colors.blue[900],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...poll.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final percentage =
              totalVotes > 0
                  ? (option.votes / totalVotes * 100).toStringAsFixed(1)
                  : '0.0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.text,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('$percentage%'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: totalVotes > 0 ? option.votes / totalVotes : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  '${option.votes} vote${option.votes != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }),
        if (totalVotes == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('No votes yet', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildCommentAvatar(Comment comment) {
    if (comment.isAnonymous) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person_outline, color: Colors.white, size: 18),
      );
    } else if (comment.userProfileImage != null &&
        comment.userProfileImage!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(comment.userProfileImage!),
        backgroundColor: Colors.grey[200],
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue[100],
        child: Text(
          comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.blue, fontSize: 12),
        ),
      );
    }
  }

  Widget _buildCommentItem(Comment comment, int indentLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0 * indentLevel, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentAvatar(comment),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.isAnonymous ? 'Anonymous' : comment.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.text),
                    TextButton(
                      onPressed:
                          () => _startReply(comment.id, comment.userName),
                      child: const Text(
                        'Reply',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Render replies
        ...comment.replies
            .map((reply) => _buildCommentItem(reply, indentLevel + 1))
            .toList(),
      ],
    );
  }
}
