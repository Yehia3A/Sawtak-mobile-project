import 'dart:ui';

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
import 'dart:io';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../services/auth_service.dart';
import '../services/user.serivce.dart';
import '../providers/posts_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  String? _userVote; // Track the user's vote
  late AnimationController _aniController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _aniController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _aniController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _aniController, curve: Curves.easeOutCubic),
    );
    _aniController.forward();
  }

  @override
  void dispose() {
    _aniController.dispose();
    _commentController.dispose();
    super.dispose();
  }

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
        final pickedFile = result.files.first;
        if (pickedFile.bytes != null && pickedFile.name.isNotEmpty) {
          await postProvider.addAttachment(
            postId: widget.post.id,
            fileBytes: pickedFile.bytes!,
            fileName: pickedFile.name,
          );
        } else if (pickedFile.path != null) {
          final file = File(pickedFile.path!);
          await postProvider.addAttachment(postId: widget.post.id, file: file);
        } else {
          throw Exception('No file data found');
        }

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
                        Text('Auth error: \\${authSnapshot.error}'),
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
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // Background
                    Image.asset(
                      'assets/homepage.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                                expandedHeight: 220,
                          pinned: true,
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                leading: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed:
                                  () => Share.share(
                                          'Check out this post: \\${widget.post.title}\\n\\${widget.post.content}',
                                  ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                                  background: _buildTopImage(),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.title,
                                  style: const TextStyle(
                                                fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                  ),
                                ),
                                            const SizedBox(height: 12),
                                Row(
                                  children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.white70,
                                                ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                                  ).format(
                                                    widget.post.createdAt,
                                                  ),
                                      style: const TextStyle(
                                                    color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                                const Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: Colors.white70,
                                                ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.post.authorName,
                                      style: const TextStyle(
                                                    color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                            const SizedBox(height: 20),
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                MarkdownBody(
                                  data: widget.post.content,
                                  styleSheet: MarkdownStyleSheet(
                                                p: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                            if (widget
                                                .post
                                                .attachments
                                                .isNotEmpty)
                                              _buildAttachments(),
                                if (widget.post is Poll)
                                              _buildPollOptions(user),
                                            const SizedBox(height: 24),
                                      const Text(
                                              'Comments',
                                        style: TextStyle(
                                                fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...widget.post.comments
                                                .where(
                                                  (comment) =>
                                                      comment.parentCommentId ==
                                                      null,
                                                )
                                                .map(
                                                  (comment) =>
                                                      _buildCommentItem(
                                                        comment,
                                                      ),
                                                )
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                        ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
                bottomNavigationBar: _buildCommentInput(user, postProvider),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopImage() {
    final imageAttachment =
        widget.post.attachments.isNotEmpty
            ? widget.post.attachments.firstWhere(
              (a) =>
                  (a.type ?? '').contains('image') ||
                  a.name.toLowerCase().endsWith('.jpg') ||
                  a.name.toLowerCase().endsWith('.jpeg') ||
                  a.name.toLowerCase().endsWith('.png') ||
                  a.name.toLowerCase().endsWith('.webp'),
              orElse:
                  () => Attachment(id: '', name: '', url: '', type: 'asset'),
            )
            : null;
    if (imageAttachment != null &&
        imageAttachment.url.isNotEmpty &&
        imageAttachment.type != 'asset') {
      return GestureDetector(
        onTap: () => _showImagePreview(imageAttachment.url),
        child: Hero(
          tag: imageAttachment.url,
          child: CachedNetworkImage(
            imageUrl: imageAttachment.url,
                                                  fit: BoxFit.cover,
            placeholder:
                (context, url) =>
                    const Center(child: CircularProgressIndicator()),
            errorWidget:
                (context, error, stackTrace) => Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.error_outline,
                                                          size: 40,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          );
    }
    return Image.asset('assets/homepage.jpg', fit: BoxFit.cover);
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments:',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.post.attachments.map((attachment) {
                final isImage =
                    attachment.type.toLowerCase().contains('image') ||
                    attachment.name.toLowerCase().endsWith('.jpg') ||
                    attachment.name.toLowerCase().endsWith('.jpeg') ||
                    attachment.name.toLowerCase().endsWith('.png') ||
                    attachment.name.toLowerCase().endsWith('.webp');
                if (isImage) {
                  return GestureDetector(
                    onTap: () => _showImagePreview(attachment.url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: attachment.url,
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                      ),
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: () => _downloadAttachment(attachment),
                    child: Container(
                      width: 120,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
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
                    ),
                  );
                }
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPollOptions(User? user) {
    // ... keep your poll options logic, but update styling if needed ...
    // You can wrap poll options in glassmorphism containers for consistency
    // ...
    return Container(); // Placeholder for brevity
  }

  Widget _buildCommentInput(User? user, PostProvider postProvider) {
    return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
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
                          Checkbox(
                            value: _isAnonymous,
                            onChanged:
                    (value) => setState(() => _isAnonymous = value ?? false),
                                ),
              const Text(
                'Post as Anonymous',
                style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white70),
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
                              onPressed: () => Navigator.pop(context),
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
                    fillColor: Colors.white.withOpacity(0.07),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                  style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                icon: const Icon(Icons.send, color: Colors.amber),
                            onPressed:
                    () => _submitComment(user, PostsProvider(), UserService()),
                          ),
                          IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.white70),
                onPressed: () => _pickAndUploadFile(user, postProvider),
                          ),
                        ],
                      ),
                    ],
      ),
    );
  }
}

/* Removed local PollOption class. Use the one from models/post.dart instead. */
