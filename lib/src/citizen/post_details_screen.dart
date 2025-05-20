import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../services/auth_service.dart';
import '../services/user.serivce.dart';
import '../providers/posts_provider.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  String? _userVote; // Track the user's vote

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
      _commentController.text = '@$userName ';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _commentController.clear();
    });
  }

  Future<void> _pickAndUploadFile(User? user, PostProvider postProvider) async {
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to upload files')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('attachments')
            .child('${widget.post.id}')
            .child(file.name);

        await storageRef.putData(file.bytes!);
        final downloadUrl = await storageRef.getDownloadURL();

        await postProvider.addAttachment(
          postId: widget.post.id,
          attachment: Attachment(
            id: '',
            name: file.name,
            url: downloadUrl,
            type: file.extension ?? 'unknown',
          ),
        );

        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    }
  }

  Future<void> _submitComment(
    User? user,
    PostsProvider postsProvider,
    UserService userService,
  ) async {
    if (_commentController.text.trim().isEmpty) return;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to comment')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (_isAnonymous) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Post Anonymously?'),
                content: const Text(
                  'Are you sure you want to post this comment anonymously? This cannot be changed later.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Post Anonymously'),
                  ),
                ],
              ),
        );

        if (confirmed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final userName = await userService.fetchUserFirstName(user.uid);

      await postsProvider.addComment(
        postId: widget.post.id,
        text: _commentController.text.trim(),
        userId: user.uid,
        userName: userName.isNotEmpty ? userName : 'Anonymous',
        isAnonymous: _isAnonymous,
        parentCommentId: _replyingToCommentId,
      );

      final newComment = Comment(
        id: UniqueKey().toString(),
        text: _commentController.text.trim(),
        userId: user.uid,
        userName: userName.isNotEmpty ? userName : 'Anonymous',
        isAnonymous: _isAnonymous,
        parentCommentId: _replyingToCommentId,
        createdAt: DateTime.now(),
        replies: [],
      );

      setState(() {
        widget.post.comments.add(newComment);
      });

      _commentController.clear();
      _cancelReply();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        if (e.toString().contains('inappropriate content')) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Comment Blocked'),
                  content: SelectableText.rich(
                    TextSpan(
                      text: e.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
        }
      }
    }
  }

  Future<void> _downloadAttachment(Attachment attachment) async {
    try {
      final url = Uri.parse(attachment.url);
      if (await url_launcher.canLaunchUrl(url)) {
        await url_launcher.launchUrl(url);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
      }
    }
  }

  void _showImagePreview(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Container(
                color: Colors.black,
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _voteOnPoll(
    String optionText,
    User? user,
    PostsProvider postsProvider,
  ) async {
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in to vote')));
      }
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Ensure the post is of type Poll
      if (widget.post.type != PostType.poll) {
        throw Exception('This post is not a poll');
      }

      final poll = widget.post as Poll;

      // Check if the user has already voted
      if (poll.votedUserIds.contains(user.uid)) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already voted on this poll'),
            ),
          );
        }
        return;
      }

      final optionIndex = poll.options.indexWhere(
        (opt) => opt.text == optionText,
      );
      if (optionIndex == -1) throw Exception('Option not found');

      await postsProvider.voteOnPoll(
        postId: widget.post.id,
        userId: user.uid,
        optionText: optionText,
      );

      // Update the user's vote locally
      setState(() {
        _userVote = optionText;
        poll.votedUserIds.add(user.uid);
        poll.options[optionIndex] = poll.options[optionIndex].copyWith(
          votes: poll.options[optionIndex].votes + 1,
        );
      });

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote submitted successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error voting in poll: $e')));
      }
    }
  }

  Widget _buildCommentItem(Comment comment, {bool isReply = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16, left: isReply ? 32 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  comment.userName[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
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
                          DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.text),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed:
                              () => _startReply(comment.id, comment.userName),
                          child: const Text('Reply'),
                        ),
                        if (comment.replies.isNotEmpty)
                          TextButton(
                            onPressed: () {},
                            child: Text('${comment.replies.length} replies'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => _buildCommentItem(reply, isReply: true),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(
    Attachment attachment,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                attachment.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadAttachment(attachment),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostProvider(),
      child: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return StreamBuilder<User?>(
            stream: _authService.authStateChanges,
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (authSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Auth error: ${authSnapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final user = authSnapshot.data;
              if (user != null) {
                if (_userVote == null && widget.post is Poll) {
                  postProvider.getPost(widget.post.id).first.then((post) {
                    if (post is Poll && post.votedUserIds.contains(user.uid)) {
                      final votedOption =
                          post.options
                              .firstWhere(
                                (opt) => opt.votes > 0,
                                orElse: () => PollOption(text: '', votes: 0),
                              )
                              .text;
                      if (mounted) setState(() => _userVote = votedOption);
                    }
                  });
                }
              }

              return Scaffold(
                body: Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 200,
                          pinned: true,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed:
                                  () => Share.share(
                                    'Check out this post: ${widget.post.title}\n${widget.post.content}',
                                  ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Builder(
                              builder: (context) {
                                final imageAttachment = widget.post.attachments
                                    ?.firstWhere(
                                      (a) =>
                                          (a.type ?? '').startsWith('image/'),
                                      orElse:
                                          () => Attachment(
                                            id: '',
                                            name: '',
                                            url: '',
                                            type: 'asset',
                                          ),
                                    );
                                if (imageAttachment != null &&
                                    imageAttachment.url.isNotEmpty &&
                                    imageAttachment.type != 'asset') {
                                  return CachedNetworkImage(
                                    imageUrl: imageAttachment.url,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Image.asset(
                                          'assets/homepage.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                  );
                                }
                                return Image.asset(
                                  'assets/homepage.jpg',
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          leading: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(widget.post.createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.post.authorName,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                MarkdownBody(
                                  data: widget.post.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (widget.post is Poll)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Poll Options:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ...(widget.post as Poll).options.map((
                                        option,
                                      ) {
                                        final poll = widget.post as Poll;
                                        final totalVotes = poll.options
                                            .map((o) => o.votes)
                                            .reduce((a, b) => a + b);
                                        final percentage =
                                            totalVotes > 0
                                                ? (option.votes /
                                                        totalVotes *
                                                        100)
                                                    .toStringAsFixed(1)
                                                : '0.0';
                                        return ListTile(
                                          title: Row(
                                            children: [
                                              Text(option.text),
                                              if (_userVote == option.text)
                                                const Text(
                                                  ' (Your Vote)',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Text(
                                            '${option.votes} votes ($percentage%)',
                                          ),
                                          onTap:
                                              _userVote == null &&
                                                      !poll.isExpired &&
                                                      user != null
                                                  ? () => _voteOnPoll(
                                                    option.text,
                                                    user,
                                                    PostsProvider(),
                                                  )
                                                  : null,
                                        );
                                      }).toList(),
                                      if (widget.post is Poll &&
                                          (widget.post as Poll).endDate != null)
                                        Text(
                                          'Ends: ${DateFormat('MMM dd, yyyy • hh:mm a').format((widget.post as Poll).endDate)}',
                                        ),
                                    ],
                                  ),
                                if (widget.post.type == PostType.announcement &&
                                    widget.post.attachments.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Attachments:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ...widget.post.attachments.map((
                                        attachment,
                                      ) {
                                        final isImage = (attachment.type ?? '')
                                            .startsWith('image/');
                                        return _buildAttachmentItem(
                                          attachment,
                                          isImage
                                              ? Icons.image
                                              : Icons.picture_as_pdf,
                                          isImage ? Colors.blue : Colors.red,
                                          onTap:
                                              isImage
                                                  ? () => _showImagePreview(
                                                    attachment.url,
                                                  )
                                                  : () => _downloadAttachment(
                                                    attachment,
                                                  ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...widget.post.comments
                                    .where(
                                      (comment) =>
                                          comment.parentCommentId == null,
                                    )
                                    .map(
                                      (comment) => _buildCommentItem(comment),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
                bottomNavigationBar: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyingToCommentId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to $_replyingToUserName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          Checkbox(
                            value: _isAnonymous,
                            onChanged:
                                (value) => setState(
                                  () => _isAnonymous = value ?? false,
                                ),
                          ),
                          const Text('Post as Anonymous'),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.help_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Anonymous Posting'),
                                      content: const Text(
                                        'When posting anonymously:\n\n• Your name will be hidden\n• Your comment cannot be edited later\n• You can still delete your comment\n• Your identity is still recorded for moderation',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('Got it'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText:
                                    _replyingToCommentId != null
                                        ? 'Write a reply...'
                                        : 'Add a comment...',
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
                                () => _submitComment(
                                  user,
                                  PostsProvider(),
                                  UserService(),
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed:
                                () => _pickAndUploadFile(user, postProvider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* Removed local PollOption class. Use the one from models/post.dart instead. */
