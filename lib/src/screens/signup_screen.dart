import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.service.dart';
import '../services/user.serivce.dart';
import '../data/egypt_locations.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _role;
  bool _loading = false;
  String? _selectedCity;
  String? _selectedArea;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final AnimationController _aniController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _aniController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _aniController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _aniController, curve: Curves.easeOutCubic),
    );

    _aniController.forward();
  }

  @override
  void dispose() {
    _aniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a role')));
      return;
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a city')));
      return;
    }
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an area')));
      return;
    }
    setState(() => _loading = true);
    try {
      // 1) Sign up with Firebase Auth
      final cred = await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      debugPrint('🟢 Signed up: ${cred.user?.uid}');

      // 2) Create Firestore user doc
      await UserService().createUserDoc(
        cred.user!.uid,
        _emailController.text.trim(),
        _role!,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _passwordController.text.trim(),
        city: _selectedCity!,
        area: _selectedArea!,
      );

      // 3) Navigate to the root
      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                        const SizedBox(height: 40),
                        // Logo and Title
                        Center(
            child: Column(
              children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logo.jpg',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Create Account',
                                style: TextStyle(
                    color: Colors.white,
                                  fontSize: 32,
                    fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join our community',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                  ),
                ),
                const SizedBox(height: 40),
                        // First Name Field
                        _buildFormField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                        // Last Name Field
                        _buildFormField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                        // Email Field
                        _buildFormField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                      ),
                      const SizedBox(height: 16),
                        // Password Field
                        _buildFormField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                      ),
                      const SizedBox(height: 16),
                        // Confirm Password Field
                        _buildFormField(
                          controller: _confirmController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                      ),
                      const SizedBox(height: 16),
                        // Role Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                        value: _role,
                            hint: Text(
                              'Choose your role',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                            value: 'Citizen',
                            child: Text('Citizen'),
                          ),
                          DropdownMenuItem(
                            value: 'Gov Admin',
                            child: Text('Gov Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'Advertiser',
                            child: Text('Advertiser'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _role = v),
                        decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.work_outline,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                            vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // City Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                            hint: Text(
                              'Select City',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
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
                              prefixIcon: Icon(
                                Icons.location_city_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                            vertical: 16,
                              ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Area Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                        value: _selectedArea,
                            hint: Text(
                              'Select Area',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
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
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                            vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sign Up Button
                      SizedBox(
                          height: 44,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: _loading ? null : _submit,
                              child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                      Color(0xFF42A5F5), // Blue
                                      Color(0xFF7E57C2), // Purple
                                      Color(0xFFE040FB), // Pink
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                              child:
                                  _loading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                        color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                      )
                                      : const Text(
                                            'Sign Up',
                                        style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                        // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                      TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                              context,
                              '/login',
                                );
                              },
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
      controller: controller,
        validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          suffixIcon: suffix,
          border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
          vertical: 16,
          ),
        ),
      ),
    );
  }
}
