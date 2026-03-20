import 'package:flutter_test/flutter_test.dart';
import 'package:mimz_app/features/world/providers/world_provider.dart';

void main() {
  group('World Providers Unit Tests', () {
    test('parseDistrictResponse parses backend-wrapped payload', () {
      final district = parseDistrictResponse({
        'district': {
          'id': 'district_test',
          'name': 'Verdant Reach',
          'sectors': 2,
          'area': '2.2 sq km',
          'structures': <Map<String, dynamic>>[],
          'resources': {'stone': 0, 'glass': 0, 'wood': 0},
          'prestigeLevel': 1,
        },
      });
      expect(district.name, 'Verdant Reach');
      expect(district.sectors, 2);
    });
  });
}
