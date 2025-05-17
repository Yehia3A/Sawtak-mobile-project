import 'package:flutter/material.dart';
import '../models/advertisement_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';

class HomeAdvertiser extends StatefulWidget {
  const HomeAdvertiser({super.key});

  @override
  State<HomeAdvertiser> createState() => _HomeAdvertiserState();
}

class _HomeAdvertiserState extends State<HomeAdvertiser> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _linkController = TextEditingController();

  final _adService = AdvertisementService();
  final _authService = AuthService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final request = AdvertisementRequest(
      id: const Uuid().v4(),
      posterId: _authService.currentUser?.uid ?? '',
      posterName: _authService.currentUser?.displayName ?? 'Unknown',
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text,
      city: _cityController.text,
      area: _areaController.text,
      link: _linkController.text,
      createdAt: DateTime.now(),
    );

    try {
      await _adService.createRequest(request);
      _formKey.currentState!.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advertisement request submitted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.4)),

          SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Prompt box
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Create Advertisements posts for your Shop to people 1 step close to you!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    // Section title
                    const Text(
                      'Create Advertisement Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image URL field
                    _buildInputField(
                      'Image URL *',
                      _imageUrlController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an image URL';
                        }
                        final uri = Uri.tryParse(value);
                        if (uri == null || !uri.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // Title field
                    _buildInputField(
                      'Title *',
                      _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // Description field
                    _buildInputField(
                      'Description *',
                      _descriptionController,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // City field
                    _buildInputField(
                      'City *',
                      _cityController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a city';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // Area field
                    _buildInputField(
                      'Area *',
                      _areaController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an area';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // Link field
                    _buildInputField(
                      'Link (Facebook, Menu, etc.)',
                      _linkController,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.isAbsolute) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    // Post button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Text(
                                'Post',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/check_ads'),
        child: const Icon(Icons.list),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white70,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : 30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
