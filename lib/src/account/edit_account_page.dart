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
      final isPending = await _authService.isEmailVerificationPending(user!.email!);
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
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _firstNameController.text = data['firstName'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _emailController.text = user.email ?? '';
            _selectedCity = data['city'];
            _selectedArea = data['area'];
            _is2faEnabled = data['is2faEnabled'] ?? false;
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
        });
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (_isVerificationPending) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email to enable 2FA. Check your inbox and click the verification link.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (!value) {
      // Disable 2FA
      try {
        setState(() => _is2faLoading = true);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'is2faEnabled': false,
            'twoFactorMethod': null,
            'verifiedEmail': null,
          });
          setState(() => _is2faEnabled = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('2FA has been disabled')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error disabling 2FA: $e')),
          );
        }
      } finally {
        setState(() => _is2faLoading = false);
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
            content: Text('Verification email sent. Please check your inbox and click the verification link.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Start polling for verification
      _authService.pollEmailVerification(email).listen(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enabling 2FA: $e')),
        );
      }
      setState(() => _isVerificationPending = false);
    } finally {
      setState(() => _is2faLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      enabled: false, // Email can't be changed here
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: const Text('Select City'),
                      items: getAllCities()
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                          _selectedArea = null;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      hint: const Text('Select Area'),
                      items: (_selectedCity != null && _selectedCity!.isNotEmpty)
                          ? getAreasForCity(_selectedCity!).map((area) => DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              )).toList()
                          : [],
                      onChanged: (value) => setState(() => _selectedArea = value),
                      decoration: const InputDecoration(labelText: 'Area'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Two-Factor Authentication (Email)'),
                              if (_isVerificationPending)
                                const Text(
                                  'Verification pending. Check your email.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _is2faEnabled || _isVerificationPending,
                          onChanged: _is2faLoading ? null : _toggle2FA,
                        ),
                      ],
                    ),
                    if (_is2faLoading)
                      const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}