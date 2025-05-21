import 'package:flutter/material.dart';
import '../models/advertisement_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';
import '../data/egypt_locations.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';

class HomeAdvertiser extends StatefulWidget {
  const HomeAdvertiser({super.key});

  @override
  State<HomeAdvertiser> createState() => _HomeAdvertiserState();
}

class _HomeAdvertiserState extends State<HomeAdvertiser>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _linkController = TextEditingController();

  String? _selectedCity;
  String? _selectedArea;
  List<String> _availableAreas = [];

  final _adService = AdvertisementService();
  final _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _linkController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeLocations() {
    if (_selectedCity != null) {
      _availableAreas = getAreasForCity(_selectedCity!);
    }
  }

  void _onCityChanged(String? newCity) {
    setState(() {
      _selectedCity = newCity;
      _availableAreas = newCity != null ? getAreasForCity(newCity) : [];
      _selectedArea = null;
    });
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines ?? 1,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required IconData icon,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        isExpanded: true,
        icon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        dropdownColor: Colors.black.withOpacity(0.9),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
        ),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Gradient overlay
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
          // Content
          SafeArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Welcome Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                  child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      const Text(
                                'Create Advertisement',
                                style: TextStyle(
                                  color: Colors.white,
                          fontSize: 28,
                                  fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                                ),
                              ),
                      const SizedBox(height: 8),
                              Text(
                        'Reach your target audience effectively',
                                style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                ),
                // Form
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFormField(
                                controller: _titleController,
                                label: 'Advertisement Title',
                                icon: Icons.title,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              _buildFormField(
                                controller: _descriptionController,
                                label: 'Description',
                                icon: Icons.description,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                                maxLines: 3,
                              ),
                              _buildFormField(
                                controller: _imageUrlController,
                                label: 'Image URL',
                                icon: Icons.image,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an image URL';
                                  }
                                  return null;
                                },
                              ),
                              _buildFormField(
                                controller: _linkController,
                                label: 'Link (optional)',
                                icon: Icons.link,
                              ),
                              _buildDropdownField(
                                value: _selectedCity,
                                hint: 'Select City',
                                items: getAllCities(),
                                icon: Icons.location_city,
                                onChanged: _onCityChanged,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a city';
                                  }
                                  return null;
                                },
                              ),
                              if (_selectedCity != null)
                              _buildDropdownField(
                                value: _selectedArea,
                                  hint: 'Select Area',
                                items: _availableAreas,
                                  icon: Icons.location_on,
                                  onChanged: (value) {
                                  setState(() {
                                      _selectedArea = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select an area';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                    shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Advertisement',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final adRequest = AdvertisementRequest(
        id: const Uuid().v4(),
        posterId: user.uid,
        posterName: user.displayName ?? 'Unknown',
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text,
        link: _linkController.text,
        city: _selectedCity!,
        area: _selectedArea!,
        createdAt: DateTime.now(),
      );

      await _adService.createRequest(adRequest);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advertisement request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _linkController.clear();
      setState(() {
        _selectedCity = null;
        _selectedArea = null;
        _availableAreas = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting advertisement: $e'),
          backgroundColor: Colors.red,
      ),
    );
  }
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
