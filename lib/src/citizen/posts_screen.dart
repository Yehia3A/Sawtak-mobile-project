import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../services/posts.service.dart';
import '../widgets/post_card.dart';
import 'dart:async';

class PostsScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String userRole;

  const PostsScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostsService _postsService = PostsService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isCreatingPoll = false;
  bool _showResults = true;
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
    _titleController.dispose();
    _contentController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCreatingPoll && (_endDate == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end date and time')),
      );
      return;
    }

    try {
      if (_isCreatingPoll) {
        final options =
            _optionControllers
                .map((controller) => controller.text.trim())
                .where((text) => text.isNotEmpty)
                .toList();

        if (options.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least 2 options')),
          );
          return;
        }

        // Combine date and time
        final endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );

        await _postsService.createPoll(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          authorId: widget.currentUserId,
          authorName: widget.currentUserName,
          options: options,
          userRole: widget.userRole,
          endDate: endDateTime,
          showResults: _showResults,
        );
      } else {
        await _postsService.createAnnouncement(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          authorId: widget.currentUserId,
          authorName: widget.currentUserName,
          userRole: widget.userRole,
        );
      }

      _titleController.clear();
      _contentController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      setState(() {
        _isCreatingPoll = false;
        _endDate = null;
        _endTime = null;
        _showResults = true;
        _optionControllers.clear();
        _optionControllers.addAll([
          TextEditingController(),
          TextEditingController(),
        ]);
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
      }
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    _isCreatingPoll ? 'Create Poll' : 'Create Announcement',
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'Content',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          if (_isCreatingPoll) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _selectDate(context),
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      _endDate == null
                                          ? 'Select Date'
                                          : DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(_endDate!),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _selectTime(context),
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                      _endTime == null
                                          ? 'Select Time'
                                          : _endTime!.format(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Show Results'),
                              value: _showResults,
                              onChanged: (value) {
                                setState(() => _showResults = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            ..._optionControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                ),
                              );
                            }),
                            TextButton.icon(
                              onPressed: _addOption,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Option'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() => _isCreatingPoll = !_isCreatingPoll);
                      },
                      child: Text(
                        _isCreatingPoll
                            ? 'Switch to Announcement'
                            : 'Switch to Poll',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _createPost,
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          if (widget.userRole == 'gov_admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreatePostDialog,
            ),
        ],
      ),
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
              );
            },
          );
        },
      ),
    );
  }
}
