import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mimz_app/design_system/tokens.dart';

/// Wraps a test widget with necessary providers and theming.
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;

  const TestAppWrapper({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        title: 'Mimz Test',
        theme: MimzTheme.light,
        debugShowCheckedModeBanner: false,
        // Wraps child in a Scaffold by default to prevent Material widget requirement errors
        home: child is Scaffold ? child : Scaffold(body: child),
      ),
    );
  }
}
