import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user.serivce.dart';
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
  bool _isLoading = false;
  final UserService _userService = UserService();
  String? _selectedCity;
  String? _selectedArea;
  final _phoneController = TextEditingController();
  bool _is2faEnabled = false;
  bool _is2faLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
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
            _selectedCity = data['city'];
            _selectedArea = data['area'];
            _phoneController.text = (data['phone'] ?? '').replaceFirst('+20', '');
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _userService.updateUser(user.uid, {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'city': _selectedCity,
          'area': _selectedArea,
          'phone': '+20${_phoneController.text.trim()}',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account details updated')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggle2FA(bool value) async {
    setState(() => _is2faLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (value) {
      // Enable 2FA: verify phone
      final phone = '+20${_phoneController.text.trim()}';
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number first.')),
        );
        setState(() => _is2faLoading = false);
        return;
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.linkWithCredential(credential);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'is2faEnabled': true});
          setState(() => _is2faEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA activated successfully.')),
          );
        },
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message ?? e.code}')),
          );
        },
        codeSent: (verificationId, resendToken) async {
          final code = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Enter OTP'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OTP Code'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(controller.text),
                    child: const Text('Verify'),
                  ),
                ],
              );
            },
          );
          if (code != null && code.isNotEmpty) {
            final credential = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: code,
            );
            await user.linkWithCredential(credential);
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'is2faEnabled': true});
            setState(() => _is2faEnabled = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('2FA activated successfully.')),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } else {
      // Disable 2FA
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'is2faEnabled': false});
      setState(() => _is2faEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2FA deactivated.')),
      );
    }
    setState(() => _is2faLoading = false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Enter first name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Enter last name' : null,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+20 ',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your phone number';
                        }
                        if (!RegExp(r'^1[0-9]{9}?$').hasMatch(value)) {
                          return 'Enter a valid Egyptian phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('2FA'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _is2faEnabled,
                          onChanged: _is2faLoading ? null : (val) async {
                            // If phone number changed, require re-verification
                            final user = FirebaseAuth.instance.currentUser;
                            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
                            final data = userDoc.data();
                            final savedPhone = (data?['phone'] ?? '').replaceFirst('+20', '');
                            if (val && _phoneController.text.trim() != savedPhone) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please save your new phone number first.')),
                              );
                              return;
                            }
                            await _toggle2FA(val);
                          },
                        ),
                        if (_is2faLoading) const SizedBox(width: 8),
                        if (_is2faLoading) const CircularProgressIndicator(strokeWidth: 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}