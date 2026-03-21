import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TelemetryService.markAppLaunchStarted();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MimzApp()));
}
