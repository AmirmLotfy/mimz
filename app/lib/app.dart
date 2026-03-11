import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_system/tokens.dart';
import 'routing/router.dart';

class MimzApp extends ConsumerWidget {
  const MimzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mimz',
      debugShowCheckedModeBanner: false,
      theme: MimzTheme.light,
      darkTheme: MimzTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
