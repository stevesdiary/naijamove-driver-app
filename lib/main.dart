import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'app/routes.dart';
import 'app/state/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] Caught driver-app framework error: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint('[FlutterError] Stack: ${details.stack}');
    }
  };

  // Catch unhandled async/platform errors to prevent hard OS termination
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] Caught unhandled driver-app error: $error');
    debugPrint('[PlatformDispatcher] Stack: $stack');
    return true;
  };

  // Graceful fallback for widget build failures
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.amber, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Something went wrong',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                kReleaseMode ? 'Please try again or restart the app.' : details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final container = ProviderContainer();
  // When deep-launched past the splash (demos, screenshots), treat the session as signed in.
  if (startRoute != Routes.splash) {
    container.read(sessionProvider.notifier).demoLogin();
  }
  runApp(UncontrolledProviderScope(container: container, child: const NaijaMoveDriverApp()));
}
