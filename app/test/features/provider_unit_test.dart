import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mimz_app/features/world/providers/world_provider.dart';
import 'package:mimz_app/core/providers.dart';
import 'package:mimz_app/data/models/district.dart';

void main() {
  group('World Providers Unit Tests', () {
    test('districtProvider parses demo state correctly on initialization', () {
      final container = ProviderContainer();

      final districtState = container.read(districtProvider);
      expect(districtState.isLoading, isFalse);
      expect(districtState.valueOrNull, isNotNull);
      expect(districtState.valueOrNull?.name, equals('Verdant Reach'));

      container.dispose();
    });
  });
}
