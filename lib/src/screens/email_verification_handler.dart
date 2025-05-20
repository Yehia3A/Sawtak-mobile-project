import 'package:flutter/material.dart';
import '../services/auth.service.dart';

class EmailVerificationHandler extends StatefulWidget {
  final String link;
  
  const EmailVerificationHandler({
    super.key,
    required this.link,
  });

  @override
  State<EmailVerificationHandler> createState() => _EmailVerificationHandlerState();
}

class _EmailVerificationHandlerState extends State<EmailVerificationHandler> {
  bool _processing = true;
  String _message = 'Verifying your email...';
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _handleVerification();
  }

  Future<void> _handleVerification() async {
    try {
      final success = await AuthService().handleVerificationLink(widget.link);
      
      setState(() {
        _processing = false;
        _success = success;
        _message = success 
          ? 'Email verified successfully! You can now return to the app.'
          : 'Failed to verify email. Please try again.';
      });

      if (success) {
        // Give user time to read the success message
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _success = false;
        _message = 'Error verifying email: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_processing)
                const CircularProgressIndicator()
              else
                Icon(
                  _success ? Icons.check_circle : Icons.error,
                  color: _success ? Colors.green : Colors.red,
                  size: 64,
                ),
              const SizedBox(height: 24),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 