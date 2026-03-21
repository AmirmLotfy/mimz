import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/settings/presentation/settings_screen.dart';
import 'package:mimz_app/features/district/presentation/district_detail_screen.dart';
import 'package:mimz_app/features/world/providers/world_provider.dart';
import 'package:mimz_app/services/settings_service.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/services/auth_service.dart';
import 'package:mimz_app/data/models/user.dart';
import 'package:mimz_app/data/models/district.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  Future<void> setNotifications(bool v) async {}
  @override
  Future<void> setHaptic(bool v) async {}
  @override
  Future<void> setSound(bool v) async {}
  @override
  Future<void> setLocationSharing(bool v) async {}
}

// Use a Fake for ApiClient to avoid flaky mocktail stubs for concrete classes
class FakeApiClient extends Fake implements ApiClient {
  @override
  Future<Map<String, dynamic>> getGameState() async => {
        'user': MimzUser.demo.toJson(),
        'district': {
          'id': District.demo.id,
          'ownerId': MimzUser.demo.id,
          'name': District.demo.name,
          'sectors': District.demo.sectors,
          'area': District.demo.area,
          'structures': District.demo.structures
              .map((s) => {'id': s.id, 'name': s.name, 'tier': s.tier})
              .toList(),
          'resources': District.demo.resources.toJson(),
          'prestigeLevel': District.demo.prestigeLevel,
          'influence': District.demo.influence,
          'influenceThreshold': District.demo.influenceThreshold,
          'cells': const [],
          'createdAt': DateTime.now().toIso8601String(),
        },
        'currentMission': 'Build your district',
        'eventZones': const [],
        'streakState': const {'liveStreak': 0, 'dailyStreak': 0, 'bestStreak': 0},
        'structureEffects': const {},
        'structureProgress': const {'unlockedCount': 0, 'totalAvailable': 5, 'readyToBuild': false},
        'notifications': const [],
        'leaderboardSnippets': const [],
        'activeConflicts': const [],
      };

  @override
  Future<Map<String, dynamic>> getDistrict() async => {
        'district': {
          'id': District.demo.id,
          'name': District.demo.name,
          'sectors': District.demo.sectors,
          'area': District.demo.area,
          'structures': District.demo.structures
              .map((s) => {'id': s.id, 'name': s.name, 'tier': s.tier})
              .toList(),
          'resources': District.demo.resources.toJson(),
          'prestigeLevel': District.demo.prestigeLevel,
          'influence': District.demo.influence,
          'influenceThreshold': District.demo.influenceThreshold,
          'cells': const [],
        },
      };
  @override
  Future<Map<String, dynamic>> getProfile() async => MimzUser.demo.toJson();
  @override
  Future<Map<String, dynamic>> getEvents() async => {'events': []};
  @override
  Future<Map<String, dynamic>> bootstrap() async => {'user': MimzUser.demo.toJson()};
}

class FakeDistrictNotifier extends DistrictNotifier {
  FakeDistrictNotifier(Ref ref) : super(ref) {
    updateLocal(District.demo);
  }
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockAuthService();
    when(() => mockAuthService.currentStatus).thenReturn(AuthStatus.authenticated);
    when(() => mockAuthService.statusStream).thenAnswer((_) => Stream.value(AuthStatus.authenticated));
  });

  testWidgets('SettingsScreen renders standard preference fields', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: FakeApiClient(),
          authService: mockAuthService,
          settingsService: FakeSettingsService(),
        ),
        child: const SettingsScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
    
    // Toggles exist
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('DistrictDetailScreen renders HUD and resources', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: FakeApiClient(),
          authService: mockAuthService,
          settingsService: FakeSettingsService(),
        )..add(
            districtProvider.overrideWith((ref) => FakeDistrictNotifier(ref)),
          ),
        child: const DistrictDetailScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your District'), findsOneWidget);
    expect(find.text('RESOURCES'), findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
