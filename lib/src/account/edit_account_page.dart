import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.service.dart';
import '../data/egypt_locations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _selectedCity;
  String? _selectedArea;
  bool _is2faEnabled = false;
  bool _is2faLoading = false;
  bool _isVerificationPending = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      final isPending = await _authService.isEmailVerificationPending(
        user!.email!,
      );
      if (mounted) {
        setState(() => _isVerificationPending = isPending);
      }
    }
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _firstNameController.text = data['firstName'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _emailController.text = user.email ?? '';
            _selectedCity = data['city'];
            _selectedArea = data['area'];
            _is2faEnabled = data['is2faEnabled'] ?? false;
            _phoneController.text = data['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'city': _selectedCity,
          'area': _selectedArea,
              'phone': _phoneController.text,
        });
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggle2FA(bool value) async {
    // If trying to disable 2FA, handle it first
    if (!value) {
      try {
        setState(() => _is2faLoading = true);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Clean up any pending verification
          if (_isVerificationPending && user.email != null) {
            await FirebaseFirestore.instance
                .collection('emailVerification')
                .doc(user.email)
                .delete();
          }
          
          // Disable 2FA
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'is2faEnabled': false,
            'twoFactorMethod': null,
            'verifiedEmail': null,
          });
          
          setState(() {
            _is2faEnabled = false;
            _isVerificationPending = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('2FA has been disabled')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error disabling 2FA: $e')));
        }
      } finally {
        setState(() => _is2faLoading = false);
      }
      return;
    }

    // Handle enabling 2FA
    if (_isVerificationPending) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please verify your email to enable 2FA. Check your inbox and click the verification link.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Enable 2FA
    try {
      setState(() => _is2faLoading = true);
      
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        throw Exception('No email address available');
      }

      // Send verification email (no password needed for activation)
      await _authService.sendEmailVerification(email, isLogin: false);
      
      // Update verification pending status
      setState(() => _isVerificationPending = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent. Please check your inbox and click the verification link.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Start polling for verification
      _authService
          .pollEmailVerification(email)
          .listen(
        (isVerified) {
          if (isVerified && mounted) {
            setState(() {
              _isVerificationPending = false;
              _is2faEnabled = true;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified and 2FA has been enabled!'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        onError: (e) {
          print('Error polling verification status: $e');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error enabling 2FA: $e')));
      }
      setState(() => _isVerificationPending = false);
    } finally {
      setState(() => _is2faLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body:
          _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                    colors: [Colors.amber.shade50, Colors.white],
                  ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              enabled: false,
                            ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty) return 'Required';
                                  if (!RegExp(r'^\d{11}$').hasMatch(trimmed))
                                    return 'Phone must be exactly 11 digits';
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              value: _selectedCity,
                              hint: const Text('Select City'),
                                items:
                                    getAllCities()
                                        .map(
                                          (city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(city),
                                          ),
                                        )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCity = value;
                                  _selectedArea = null;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'City',
                                prefixIcon: const Icon(Icons.location_city),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedArea,
                              hint: const Text('Select Area'),
                                items:
                                    (_selectedCity != null &&
                                            _selectedCity!.isNotEmpty)
                                        ? getAreasForCity(_selectedCity!)
                                            .map(
                                              (area) => DropdownMenuItem(
                                        value: area,
                                        child: Text(area),
                                              ),
                                            )
                                            .toList()
                                  : [],
                                onChanged:
                                    (value) =>
                                        setState(() => _selectedArea = value),
                              decoration: InputDecoration(
                                labelText: 'Area',
                                prefixIcon: const Icon(Icons.map_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Two-Factor Authentication',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Enable email-based two-factor authentication for enhanced security.',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          height: 1.5,
                                        ),
                                      ),
                                      if (_isVerificationPending)
                                        Container(
                                            margin: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.orange.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'Verification pending. Check your email.',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _is2faEnabled,
                                    onChanged:
                                        _is2faLoading ? null : _toggle2FA,
                                  activeColor: Colors.amber,
                                ),
                              ],
                            ),
                            if (_is2faLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                            child:
                                _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
