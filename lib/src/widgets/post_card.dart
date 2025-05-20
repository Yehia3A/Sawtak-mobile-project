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
  final VoidCallback? onEdit;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.postsService,
    required this.onDelete,
    required this.userRole,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (userRole == 'gov_admin') ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditDialog(context),
                      tooltip: 'Edit Announcement',
                    ),
                  ],
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (post.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      post.attachments.map((attachment) {
                        final isImage = attachment.type
                            .toLowerCase()
                            .startsWith('image/');
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
                                    child: Image.network(
                                      attachment.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
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
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
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
              const SizedBox(height: 12),
              if (post.type == PostType.poll)
                TextButton(
                  onPressed: () => _showVoteDialog(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.amber),
                  child: const Text('Vote'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showVoteDialog(BuildContext context) {
    // Implementation of _showVoteDialog method
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text(
                'Edit Announcement',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      SelectableText.rich(
                        TextSpan(
                          text: errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      setState(() {
                        errorMessage = 'Title and content cannot be empty.';
                      });
                      return;
                    }
                    final updates = <String, dynamic>{};
                    if (title != post.title) updates['title'] = title;
                    if (content != post.content) updates['content'] = content;
                    if (updates.isNotEmpty) {
                      try {
                        await postsService.updateAnnouncement(
                          post.id,
                          updates,
                          userRole,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Error: $e';
                        });
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
