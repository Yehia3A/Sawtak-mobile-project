import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'app.dart';

void main() {
  // Catch all errors that occur in the Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Run the app in a zone to catch all async errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set error handlers for platform channels
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('Platform Error: $error');
        debugPrint('Stack trace: $stack');
        return true;
      };

      // Lock orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Configure system UI
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // Initialize Firebase with error handling
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialized successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ Firebase initialization failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      // Run app with error boundary widget
      runApp(
        const ErrorBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: AppStarter(),
          ),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

// Error boundary widget to catch widget tree errors
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 👈 remove DEBUG banner
      builder: (context, widget) {
        Widget error = const Text('Something went wrong!');
        if (widget is Scaffold || widget is Navigator) {
          error = Scaffold(body: Center(child: error));
        }
        ErrorWidget.builder = (errorDetails) {
          return Center(
            child: Card(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error: ${errorDetails.exception}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        };
        if (widget != null) return widget;
        return error;
      },
      home: child,
    );
  }
}

class AppStarter extends StatelessWidget {
  const AppStarter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 500)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }

        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}
