import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );final app = Firebase.app();
debugPrint('· App name: ${app.name}');
debugPrint('· API key: ${app.options.apiKey}');
debugPrint('· Project ID: ${app.options.projectId}');
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase failed to initialize: $e');
  }

  runApp(const MyApp());
}
