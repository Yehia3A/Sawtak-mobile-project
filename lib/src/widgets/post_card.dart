import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../services/posts.service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final String currentUserName;
  final PostsService postsService;
  final VoidCallback? onDelete;

  const PostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.postsService,
    this.onDelete,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await widget.postsService.addComment(
        postId: widget.post.id,
        text: _commentController.text.trim(),
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        isAnonymous: _isAnonymous,
      );
      _commentController.clear();
      setState(() => _isAnonymous = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
    }
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
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
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
                      const SizedBox(height: 4),
                      Text(
                        'Posted by ${widget.post.authorName} on ${DateFormat('MMM dd, yyyy').format(widget.post.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.onDelete != null && isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.post.content),
            if (widget.post is Poll) ...[
              const SizedBox(height: 16),
              _buildPollResults(context, widget.post as Poll),
            ],
            if (widget.post.comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Comments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...widget.post.comments.map(
                (comment) => ListTile(
                  leading: CircleAvatar(child: Text(comment.userName[0])),
                  title: Text(comment.userName),
                  subtitle: Text(comment.text),
                  trailing: Text(
                    DateFormat('MMM dd, yyyy').format(comment.createdAt),
                  ),
                ),
              ),
            ],
          ],
        ),
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
}
