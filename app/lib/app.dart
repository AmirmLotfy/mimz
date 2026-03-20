import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_system/tokens.dart';
import 'routing/router.dart';
import 'core/app_lifecycle_observer.dart';
import 'services/push_notification_service.dart';

class MimzApp extends ConsumerWidget {
  const MimzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    setRouterRef(ProviderScope.containerOf(context));
    PushNotificationService.navigatorKey = rootNavigatorKey;
    return MaterialApp.router(
      title: 'Mimz',
      debugShowCheckedModeBanner: false,
      theme: MimzTheme.light,
      darkTheme: MimzTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return AppLifecycleObserver(child: child!);
      },
    );
  }
}
