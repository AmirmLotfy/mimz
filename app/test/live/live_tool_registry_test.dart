import 'package:flutter_test/flutter_test.dart';
import 'package:mimz/features/live/domain/live_tool_registry.dart';

void main() {
  group('LiveTools', () {
    test('all contains exactly 15 tools', () {
      expect(LiveTools.all.length, 15);
    });

    test('isKnown returns true for valid tools', () {
      expect(LiveTools.isKnown('grade_answer'), isTrue);
      expect(LiveTools.isKnown('start_live_round'), isTrue);
      expect(LiveTools.isKnown('unlock_structure'), isTrue);
    });

    test('isKnown returns false for unknown tools', () {
      expect(LiveTools.isKnown('hack_server'), isFalse);
      expect(LiveTools.isKnown(''), isFalse);
    });
  });
}
