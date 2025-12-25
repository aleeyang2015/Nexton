import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app services
  await AppInitializer.initialize();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
