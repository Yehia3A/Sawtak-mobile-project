import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user.serivce.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController();
  final _cityController = TextEditingController();
  String _userRole = '';
  bool _is2FAEnabled = false;
  bool _isLoading = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _userService.getUserDoc(user.uid);
        if (doc != null) {
          setState(() {
            _firstNameController.text = doc['firstName'] ?? '';
            _lastNameController.text = doc['lastName'] ?? '';
            _cityController.text = doc['city'] ?? '';
            _userRole = doc['role'] ?? 'Citizen';
            _roleController.text = _userRole;
            // Password is intentionally left blank for security
            _passwordController.text = '';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading user details: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        // Update Firestore data
        final updates = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'city': _cityController.text.trim(),
        };

        await _userService.updateUser(user.uid, updates);

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text.trim());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account details updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating account: $e')),
          );
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name (editable)
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'First name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Last Name (editable)
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Last name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password (editable)
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role (read-only)
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // City (editable)
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'City is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2FA Toggle (disabled placeholder)
                    ListTile(
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text('Coming soon'),
                      trailing: Switch(
                        value: _is2FAEnabled,
                        onChanged: null, // Disabled for now
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _isLoading ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}