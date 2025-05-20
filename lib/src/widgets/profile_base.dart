import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/user.serivce.dart';
import '../data/egypt_locations.dart';
import 'dart:async';
import 'dart:developer' show log;

enum UserType { citizen, govAdmin, advertiser }

class ProfileBase extends HookConsumerWidget {
  final UserType userType;
  final String title;
  final IconData profileIcon;

  const ProfileBase({
    super.key,
    required this.userType,
    required this.title,
    required this.profileIcon,
  });

  List<String> get egyptCities => getAllCities();
  Map<String, List<String>> get egyptAreas => getAreasMap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final isLoading = useState(false);
    final isEditing = useState(false);
    final is2faEnabled = useState(false);
    final is2faLoading = useState(false);
    final isVerificationPending = useState(false);
    final showPassword = useState(false);
    
    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final currentPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    
    final selectedCity = useState<String?>(null);
    final selectedArea = useState<String?>(null);

    useEffect(() {
      _loadUserDetails(
        isLoading: isLoading,
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        emailController: emailController,
        selectedCity: selectedCity,
        selectedArea: selectedArea,
        is2faEnabled: is2faEnabled,
        isVerificationPending: isVerificationPending,
      );
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          if (!isEditing.value)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => isEditing.value = true,
            ),
          if (isEditing.value)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => isEditing.value = false,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade50,
              Colors.white,
            ],
          ),
        ),
        child: isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        profileIcon,
                        size: 100,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 24),
                      _buildPersonalInfoSection(
                        context: context,
                        isEditing: isEditing.value,
                        firstNameController: firstNameController,
                        lastNameController: lastNameController,
                        emailController: emailController,
                      ),
                      const SizedBox(height: 24),
                      if (isEditing.value) ...[
                        _buildPasswordSection(
                          context: context,
                          showPassword: showPassword,
                          currentPasswordController: currentPasswordController,
                          newPasswordController: newPasswordController,
                          confirmPasswordController: confirmPasswordController,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (userType != UserType.advertiser) ...[
                        _buildLocationSection(
                          context: context,
                          isEditing: isEditing.value,
                          selectedCity: selectedCity,
                          selectedArea: selectedArea,
                        ),
                        const SizedBox(height: 24),
                      ],
                      _buildSecuritySection(
                        context: context,
                        is2faEnabled: is2faEnabled,
                        is2faLoading: is2faLoading,
                        onToggle2FA: () => _toggle2FA(
                          context: context,
                          is2faEnabled: is2faEnabled,
                          is2faLoading: is2faLoading,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isEditing.value)
                        ElevatedButton(
                          onPressed: isLoading.value
                              ? null
                              : () => _saveChanges(
                                    context: context,
                                    formKey: formKey,
                                    isLoading: isLoading,
                                    isEditing: isEditing,
                                    firstNameController: firstNameController,
                                    lastNameController: lastNameController,
                                    currentPasswordController:
                                        currentPasswordController,
                                    newPasswordController: newPasswordController,
                                    selectedCity: selectedCity.value,
                                    selectedArea: selectedArea.value,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _deleteAccount(context),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPersonalInfoSection({
    required BuildContext context,
    required bool isEditing,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController emailController,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              enabled: isEditing,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'First name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              enabled: isEditing,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Last name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              enabled: false,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection({
    required BuildContext context,
    required ValueNotifier<bool> showPassword,
    required TextEditingController currentPasswordController,
    required TextEditingController newPasswordController,
    required TextEditingController confirmPasswordController,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => showPassword.value = !showPassword.value,
                ),
              ),
              obscureText: !showPassword.value,
              validator: (value) {
                if (value?.isEmpty ?? true) return null;
                if (value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => showPassword.value = !showPassword.value,
                ),
              ),
              obscureText: !showPassword.value,
              validator: (value) {
                if (value?.isEmpty ?? true) return null;
                if (value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => showPassword.value = !showPassword.value,
                ),
              ),
              obscureText: !showPassword.value,
              validator: (value) {
                if (value?.isEmpty ?? true) return null;
                if (value != newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection({
    required BuildContext context,
    required bool isEditing,
    required ValueNotifier<String?> selectedCity,
    required ValueNotifier<String?> selectedArea,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCity.value,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              items: egyptCities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: isEditing
                  ? (value) {
                      selectedCity.value = value;
                      selectedArea.value = null;
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedArea.value,
              decoration: const InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
              ),
              items: selectedCity.value != null
                  ? egyptAreas[selectedCity.value]?.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Text(area),
                      );
                    }).toList()
                  : [],
              onChanged: isEditing
                  ? (value) {
                      selectedArea.value = value;
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection({
    required BuildContext context,
    required ValueNotifier<bool> is2faEnabled,
    required ValueNotifier<bool> is2faLoading,
    required VoidCallback onToggle2FA,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enable email-based two-factor authentication for enhanced security.',
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (is2faLoading.value)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: is2faEnabled.value,
                    onChanged: (_) => onToggle2FA(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserDetails({
    required ValueNotifier<bool> isLoading,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController emailController,
    required ValueNotifier<String?> selectedCity,
    required ValueNotifier<String?> selectedArea,
    required ValueNotifier<bool> is2faEnabled,
    required ValueNotifier<bool> isVerificationPending,
  }) async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data();
        if (data != null) {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          emailController.text = user.email ?? '';
          selectedCity.value = data['city'];
          selectedArea.value = data['area'];
          is2faEnabled.value = data['is2faEnabled'] ?? false;

          // Check for pending verification
          if (user.email != null) {
            final verificationDoc = await FirebaseFirestore.instance
                .collection('emailVerification')
                .doc(user.email)
                .get();
            isVerificationPending.value = verificationDoc.exists;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveChanges({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isEditing,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController currentPasswordController,
    required TextEditingController newPasswordController,
    required String? selectedCity,
    required String? selectedArea,
  }) async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updates = <String, dynamic>{
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
        };

        if (userType != UserType.advertiser) {
          updates['city'] = selectedCity;
          updates['area'] = selectedArea;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updates);

        if (currentPasswordController.text.isNotEmpty &&
            newPasswordController.text.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPasswordController.text,
          );
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(newPasswordController.text);

          currentPasswordController.clear();
          newPasswordController.clear();
        }

        isEditing.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _toggle2FA({
    required BuildContext context,
    required ValueNotifier<bool> is2faEnabled,
    required ValueNotifier<bool> is2faLoading,
  }) async {
    is2faLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (is2faEnabled.value) {
          // Disabling 2FA
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'is2faEnabled': false,
            'twoFactorMethod': null,
            'verifiedEmail': null,
          });

          // Clean up any pending verification
          if (user.email != null) {
            await FirebaseFirestore.instance
                .collection('emailVerification')
                .doc(user.email)
                .delete();
          }

          is2faEnabled.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('2FA has been disabled')),
            );
          }
        } else {
          // Enabling 2FA
          final email = user.email;
          if (email == null || email.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please add an email to your account first'),
                ),
              );
            }
            return;
          }

          // Generate verification code
          final verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
          
          // Store verification data
          await FirebaseFirestore.instance
              .collection('emailVerification')
              .doc(email)
              .set({
            'code': verificationCode,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });

          // Send verification email
          try {
            await FirebaseAuth.instance.currentUser?.sendEmailVerification();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please check your email for verification instructions',
                  ),
                ),
              );
            }

            // Start verification check timer
            Timer.periodic(const Duration(seconds: 5), (timer) async {
              if (!context.mounted) {
                timer.cancel();
                return;
              }

              try {
                // Reload user to get latest email verification status
                await user.reload();
                final updatedUser = FirebaseAuth.instance.currentUser;
                
                if (updatedUser?.emailVerified ?? false) {
                  timer.cancel();
                  
                  // Update user profile with 2FA enabled
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'is2faEnabled': true,
                    'twoFactorMethod': 'email',
                    'verifiedEmail': email,
                  });

                  // Clean up verification record
                  await FirebaseFirestore.instance
                      .collection('emailVerification')
                      .doc(email)
                      .delete();

                  is2faEnabled.value = true;
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('2FA has been enabled successfully'),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error checking email verification: $e');
              }
            });
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error sending verification email: $e'),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling 2FA: $e')),
        );
      }
    } finally {
      is2faLoading.value = false;
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await UserService().deleteUser(user.uid);
          await user.delete();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/welcome');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting account: $e')),
            );
          }
        }
      }
    }
  }
} 