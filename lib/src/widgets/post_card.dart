import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/models/post.dart';
import 'package:gov_citizen_app/src/services/posts.service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              const SizedBox(height: 8),
              const Text('', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    post.attachments.map((attachment) {
                      final isImage = attachment.type.toLowerCase().startsWith(
                        'image/',
                      );
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            isImage
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: attachment.url,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      attachment.name,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                      );
                    }).toList(),
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
