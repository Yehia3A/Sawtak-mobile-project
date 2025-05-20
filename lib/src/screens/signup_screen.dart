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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
      return;
    }
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an area')),
      );
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
          // your full-screen background
          Image.asset('assets/signin.jpg', fit: BoxFit.cover),

          // the scrollable form
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                // just the title, no logo asset
                Text(
                  'Sawtak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

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
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child:
                                  _loading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),

                      // simple social icons, no external assets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white70,
                            child: Icon(
                              Icons.facebook,
                              size: 28,
                              color: Color(0xFF1877F2),
                            ),
                          ),
                          SizedBox(width: 16),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white70,
                            child: Icon(
                              Icons.email,
                              size: 28,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        child: const Text(
                          'Already have an account? Log In',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black),
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
      validator: (v) {
        if (hint == 'Confirm Password' && v != _passwordController.text) {
          return 'Passwords do not match';
        }
        if (v == null || v.isEmpty) {
          return 'Enter your ${hint.toLowerCase()}';
        }
        if (hint == 'Email') {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
        }
        if (hint == 'Password' && v.length < 6) {
          return 'Password must be 6+ chars';
        }
        return null;
      },
    );
  }
}
