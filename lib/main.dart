import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'app/routes.dart';
import 'app/state/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // When deep-launched past the splash (demos, screenshots), treat the session as signed in.
  if (startRoute != Routes.splash) {
    container.read(sessionProvider.notifier).demoLogin();
  }
  runApp(UncontrolledProviderScope(container: container, child: const NaijaMoveDriverApp()));
}
