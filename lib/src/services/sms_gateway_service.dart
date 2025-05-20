import 'package:http/http.dart' as http;
import 'dart:math';

class SMSGatewayService {
  static const String _apiEndpoint = 'YOUR_SMS_GATEWAY_ENDPOINT';
  static const String _apiKey = 'YOUR_API_KEY';

  // Generate OTP
  String _generateOTP() {
    return (100000 + Random().nextInt(900000)).toString(); // 6-digit OTP
  }

  // Send OTP via SMS gateway
  Future<String?> sendOTP(String phoneNumber) async {
    final otp = _generateOTP();
    
    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: {
          'to': phoneNumber,
          'message': 'Your verification code is: $otp',
        },
      );

      if (response.statusCode == 200) {
        return otp; // Store this securely or hash it
      }
      return null;
    } catch (e) {
      print('Error sending SMS: $e');
      return null;
    }
  }

  // Verify OTP
  bool verifyOTP(String storedOTP, String userInputOTP) {
    return storedOTP == userInputOTP;
  }
} 