import 'package:flutter/material.dart';
import '../models/advertisement_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';
import '../data/egypt_locations.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui';

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
  final _linkController = TextEditingController();

  String? _selectedCity;
  String? _selectedArea;
  List<String> _availableAreas = [];

  final _adService = AdvertisementService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeLocations();
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
      _selectedArea = null; // Reset area when city changes
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCity == null || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both city and area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = AdvertisementRequest(
      id: const Uuid().v4(),
      posterId: _authService.currentUser?.uid ?? '',
      posterName: _authService.currentUser?.displayName ?? 'Unknown',
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text,
      city: _selectedCity!,
      area: _selectedArea!,
      link: _linkController.text,
      createdAt: DateTime.now(),
    );

    try {
      await _adService.createRequest(request);
      _formKey.currentState!.reset();
      setState(() {
        _selectedCity = null;
        _selectedArea = null;
        _availableAreas = [];
      });
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
          // Background image
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header with icon
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Advertisement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Reach customers near you',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Form Container with frosted glass effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image URL field
                              _buildInputField(
                                'Image URL *',
                                _imageUrlController,
                                prefixIcon: Icons.image,
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
                                prefixIcon: Icons.title,
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
                                prefixIcon: Icons.description,
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // City Dropdown with improved styling
                              _buildDropdownField(
                                value: _selectedCity,
                                hint: 'Select City *',
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

                              const SizedBox(height: 16),
                              // Area Dropdown with improved styling
                              _buildDropdownField(
                                value: _selectedArea,
                                hint: 'Select Area *',
                                items: _availableAreas,
                                icon: Icons.map,
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedArea = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select an area';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),
                              // Link field
                              _buildInputField(
                                'Link (Facebook, Menu, etc.)',
                                _linkController,
                                prefixIcon: Icons.link,
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
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.post_add),
                                      SizedBox(width: 8),
                                      Text(
                                        'Post Advertisement',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/check_ads'),
        heroTag: 'advertiser_check_ads_fab',
        icon: const Icon(Icons.list),
        label: const Text('Your Ads'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black87),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon:
              prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.grey[600])
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        icon: Icon(icon),
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
