import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/models/post.dart';
import 'package:gov_citizen_app/src/services/posts.service.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String currentUserId;
  final String currentUserName;
  final PostsService postsService;
  final VoidCallback? onDelete;
  final String userRole;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.postsService,
    required this.onDelete,
    required this.userRole,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  post.authorName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(post.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.content),
            const SizedBox(height: 8),
            if (post is Poll) ...[
              const Text(
                'Poll Results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(post as Poll).options.map(
                (opt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${opt.text}: ${opt.votes} votes'),
                ),
              ),
              if ((post as Poll).endDate != null)
                Text(
                  'Ends: ${DateFormat('yyyy-MM-dd HH:mm').format((post as Poll).endDate)}',
                ),
            ],
            if (post.type == PostType.announcement &&
                post.attachments.isNotEmpty) ...[
              const Text(
                'Attachments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...post.attachments.map(
                (attachment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    attachment.name,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(onPressed: onTap, child: const Text('View Details')),
          ],
        ),
      ),
    );
  }
}
