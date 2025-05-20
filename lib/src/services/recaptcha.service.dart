import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class RecaptchaService {
  static const String _recaptchaId = 'recaptcha';
  
  static Future<String?> verify() async {
    if (!kIsWeb) return null;
    
    try {
      // Ensure the reCAPTCHA container exists
      var container = html.document.getElementById(_recaptchaId);
      if (container == null) {
        debugPrint('reCAPTCHA container not found, creating one...');
        container = html.DivElement()
          ..id = _recaptchaId
          ..className = 'g-recaptcha';
        html.document.body?.appendChild(container);
      }

      // Execute reCAPTCHA verification
      final response = await js.context.callMethod('grecaptcha.execute') as String?;
      if (response == null || response.isEmpty) {
        debugPrint('reCAPTCHA verification failed: Empty response');
        return null;
      }
      return response;
    } catch (e) {
      if (e.toString().contains('Invalid site key')) {
        debugPrint('reCAPTCHA error: Invalid site key. Please check your reCAPTCHA configuration in Firebase Console.');
        debugPrint('Make sure you have enabled Phone Authentication in Firebase Console.');
      } else if (e.toString().contains('grecaptcha is not defined')) {
        debugPrint('reCAPTCHA error: reCAPTCHA script not loaded properly.');
      } else {
        debugPrint('reCAPTCHA error: $e');
      }
      return null;
    }
  }

  static void reset() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('grecaptcha.reset');
    } catch (e) {
      debugPrint('Error resetting reCAPTCHA: $e');
    }
  }

  static bool get isAvailable => kIsWeb;
} 