import { describe, it, expect } from 'vitest';
import { TOOL_SCHEMAS, KNOWN_TOOLS } from '../src/modules/live/toolSchemas.js';

describe('Tool Registry', () => {
  it('contains exactly 15 tools', () => {
    expect(KNOWN_TOOLS.length).toBe(15);
  });

  it('matches expected tool names', () => {
    const expected = [
      'start_onboarding', 'save_user_profile', 'get_current_district',
      'start_live_round', 'grade_answer', 'award_territory',
      'apply_combo_bonus', 'grant_materials', 'end_round',
      'start_vision_quest', 'validate_vision_result', 'unlock_structure',
      'join_squad_mission', 'contribute_squad_progress', 'get_event_state',
    ];
    expect(KNOWN_TOOLS.sort()).toEqual(expected.sort());
  });

  it('validates grade_answer with valid args', () => {
    const schema = TOOL_SCHEMAS['grade_answer'];
    const result = schema.safeParse({ answer: 'Paris', isCorrect: true, confidence: 0.9 });
    expect(result.success).toBe(true);
  });

  it('rejects grade_answer with missing answer', () => {
    const schema = TOOL_SCHEMAS['grade_answer'];
    const result = schema.safeParse({ isCorrect: true });
    expect(result.success).toBe(false);
  });

  it('validates award_territory with bounds', () => {
    const schema = TOOL_SCHEMAS['award_territory'];
    expect(schema.safeParse({ sectors: 3 }).success).toBe(true);
    expect(schema.safeParse({ sectors: 10 }).success).toBe(false);
    expect(schema.safeParse({ sectors: 0 }).success).toBe(false);
  });

  it('validates grant_materials with max limits', () => {
    const schema = TOOL_SCHEMAS['grant_materials'];
    expect(schema.safeParse({ stone: 100, glass: 50, wood: 80 }).success).toBe(true);
    expect(schema.safeParse({ stone: 600 }).success).toBe(false);
  });

  it('validates unlock_structure requires structureId', () => {
    const schema = TOOL_SCHEMAS['unlock_structure'];
    expect(schema.safeParse({ structureId: 'library' }).success).toBe(true);
    expect(schema.safeParse({}).success).toBe(false);
  });

  it('all schemas have valid default parsing', () => {
    for (const [name, schema] of Object.entries(TOOL_SCHEMAS)) {
      // All schemas should at least parse with some valid data
      const result = schema.safeParse(
        name === 'grade_answer' ? { answer: 'test' } :
        name === 'validate_vision_result' ? { objectIdentified: 'test' } :
        name === 'unlock_structure' ? { structureId: 'test' } :
        name === 'join_squad_mission' ? { missionId: 'test' } :
        name === 'contribute_squad_progress' ? { missionId: 'test', amount: 5 } :
        name === 'get_event_state' ? { eventId: 'test' } :
        {}
      );
      expect(result.success, `Schema ${name} failed`).toBe(true);
    }
  });
});
