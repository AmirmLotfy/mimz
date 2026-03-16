import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/squads/presentation/squad_hub_screen.dart';
import 'package:mimz_app/features/events/presentation/events_screen.dart';
import 'package:mimz_app/features/squads/providers/squad_provider.dart';
import 'package:mimz_app/features/events/providers/events_provider.dart';
import 'package:mimz_app/services/settings_service.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/core/providers.dart';
import 'package:mimz_app/data/models/user.dart';
import 'package:mimz_app/services/auth_service.dart';

import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

// Use a Fake for SettingsService to avoid flaky mocktail stubs for concrete classes
class FakeSettingsService extends Fake implements SettingsService {
  @override
  Future<bool> getNotifications() async => true;
  @override
  Future<bool> getHaptic() async => true;
  @override
  Future<bool> getSound() async => true;
  @override
  Future<bool> getLocationSharing() async => true;
}

// Use a Fake for ApiClient to avoid flaky mocktail stubs for concrete classes
class FakeApiClient extends Fake implements ApiClient {
  @override
  Future<Map<String, dynamic>> getEvents() async => {'events': []};
  @override
  Future<Map<String, dynamic>> getDistrict() async => <String, dynamic>{};
  @override
  Future<Map<String, dynamic>> getProfile() async => MimzUser.demo.toJson();
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  testWidgets('SquadHubScreen renders empty states initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: [
          ...createTestOverrides(
            apiClient: FakeApiClient(),
            authService: mockAuthService,
            settingsService: FakeSettingsService(),
          ),
          squadMissionsProvider.overrideWithValue([]),
          squadMembersProvider.overrideWithValue([]),
          eventsProvider.overrideWithValue([]),
        ],
        child: const SquadHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Initial buttons
    expect(find.text('CREATE SQUAD'), findsOneWidget);
    expect(find.text('JOIN SQUAD'), findsOneWidget);

    // Empty state text
    expect(find.text('No active missions'), findsOneWidget);
    expect(find.text('No members yet'), findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('EventsScreen renders empty state when no events exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: [
          ...createTestOverrides(
            apiClient: FakeApiClient(),
            authService: mockAuthService,
            settingsService: FakeSettingsService(),
          ),
          eventsProvider.overrideWithValue([]),
        ],
        child: const EventsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Events'), findsWidgets);
    expect(find.text('No events scheduled'), findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
