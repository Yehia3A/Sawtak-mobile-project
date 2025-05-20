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

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _role;
  bool _loading = false;
  String? _selectedCity;
  String? _selectedArea;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
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
        fit: StackFit.expand,
        children: [
          // Background Image with overlay
          Image.asset('assets/signin.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Title
                    const Text(
                      'Sawtak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

<<<<<<< Updated upstream
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(_firstNameController, 'First Name'),
                      const SizedBox(height: 16),
                      _buildField(_lastNameController, 'Last Name'),
                      const SizedBox(height: 16),
                      _buildField(
                        _emailController,
                        'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        _passwordController,
                        'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        _confirmController,
                        'Confirm Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      // role dropdown
                      DropdownButtonFormField<String>(
                        value: _role,
                        hint: const Text('Choose your role'),
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
                          filled: true,
                          fillColor: Colors.white70,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // City Dropdown
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
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white70,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Area Dropdown
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
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white70,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // gradient Sign up button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF2C94C), // gold
                                  Color(0xFF333333), // dark
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
=======
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // First Name Field
                          TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'First Name',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
>>>>>>> Stashed changes
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Last Name Field
                          TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Last Name',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
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
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
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
                          TextFormField(
                            controller: _confirmController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
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

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Phone Number',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.phone,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Role Dropdown
                          DropdownButtonFormField<String>(
                            value: _role,
                            hint: const Text(
                              'Choose your role',
                              style: TextStyle(color: Colors.white70),
                            ),
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
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // City Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            hint: const Text(
                              'Select City',
                              style: TextStyle(color: Colors.white70),
                            ),
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
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Area Dropdown
                          if (_selectedCity != null)
                            DropdownButtonFormField<String>(
                              value: _selectedArea,
                              hint: const Text(
                                'Select Area',
                                style: TextStyle(color: Colors.white70),
                              ),
                              items:
                                  getAreasForCity(_selectedCity!)
                                      .map(
                                        (area) => DropdownMenuItem(
                                          value: area,
                                          child: Text(area),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedArea = value),
                              dropdownColor: Colors.black87,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child:
                                  _loading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black87,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Login Link
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Already have an account? Sign In',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
