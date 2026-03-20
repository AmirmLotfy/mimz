import 'package:flutter_test/flutter_test.dart';
import 'package:mimz_app/features/world/providers/world_provider.dart';

void main() {
  group('parseDistrictResponse', () {
    test('parses wrapped district payload', () {
      final district = parseDistrictResponse({
        'district': {
          'id': 'district_1',
          'name': 'Verdant Reach',
          'sectors': 3,
          'area': '3.3 sq km',
          'structures': <Map<String, dynamic>>[],
          'resources': {'stone': 10, 'glass': 5, 'wood': 20},
          'prestigeLevel': 2,
        },
        'resourceRate': {'stone': 1},
      });

      expect(district.id, 'district_1');
      expect(district.name, 'Verdant Reach');
      expect(district.sectors, 3);
    });

    test('throws if wrapper key is missing', () {
      expect(
        () => parseDistrictResponse({'id': 'wrong_shape'}),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'preserves topic affinity and region metadata from canonical district state',
        () {
      final district = parseDistrictResponse({
        'district': {
          'id': 'district_topics',
          'name': 'Signal Atlas',
          'sectors': 5,
          'area': '5.1 sq km',
          'structures': <Map<String, dynamic>>[],
          'resources': {'stone': 15, 'glass': 8, 'wood': 12},
          'prestigeLevel': 3,
          'regionAnchor': {
            'regionId': 'cairo_grid',
            'label': 'Cairo District Grid',
          },
          'topicAffinities': [
            {
              'topic': 'Architecture',
              'answered': 12,
              'correct': 9,
              'streak': 3,
              'masteryScore': 81,
              'winRate': 0.75,
            },
          ],
        },
      });

      expect(district.regionId, 'cairo_grid');
      expect(district.regionLabel, 'Cairo District Grid');
      expect(district.topicAffinities, hasLength(1));
      expect(district.topicAffinities.first.topic, 'Architecture');
      expect(district.topicAffinities.first.winRate, 0.75);
    });
  });
}
