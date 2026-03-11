import { describe, it, expect } from 'vitest';
import { calculateScore, calculateComboBonus, canAfford, getPrestigeLevel } from '../src/services/gameService.js';

describe('Scoring Logic', () => {
  it('awards base points for correct easy answer', () => {
    const result = calculateScore(true, 0, 'easy');
    expect(result.points).toBe(75);
    expect(result.newStreak).toBe(1);
  });

  it('awards base points for correct medium answer', () => {
    const result = calculateScore(true, 0, 'medium');
    expect(result.points).toBe(100);
  });

  it('awards base points for correct hard answer', () => {
    const result = calculateScore(true, 0, 'hard');
    expect(result.points).toBe(150);
  });

  it('awards zero for incorrect answer', () => {
    const result = calculateScore(false, 5, 'hard');
    expect(result.points).toBe(0);
    expect(result.newStreak).toBe(0);
  });

  it('includes streak bonus', () => {
    const result = calculateScore(true, 3, 'medium');
    expect(result.streakBonus).toBeGreaterThan(0);
    expect(result.points).toBeGreaterThan(100);
  });

  it('caps streak bonus at max', () => {
    const result5 = calculateScore(true, 5, 'medium');
    const result50 = calculateScore(true, 50, 'medium');
    // With maxStreakBonus = 10, streak 50 should be capped
    expect(result50.streakBonus).toBeLessThanOrEqual(result5.streakBonus * 3);
  });
});

describe('Combo Bonus', () => {
  it('calculates bonus XP', () => {
    const result = calculateComboBonus(3, 1.5);
    expect(result.bonusXp).toBeGreaterThan(0);
  });

  it('grants materials proportional to streak', () => {
    const low = calculateComboBonus(2, 1);
    const high = calculateComboBonus(5, 1);
    expect(high.bonusMaterials.stone).toBeGreaterThan(low.bonusMaterials.stone);
  });
});

describe('Resource Affordability', () => {
  it('can afford when resources are sufficient', () => {
    expect(canAfford(
      { stone: 200, glass: 100, wood: 150 },
      { stone: 100, glass: 50, wood: 80 },
    )).toBe(true);
  });

  it('cannot afford when any resource is insufficient', () => {
    expect(canAfford(
      { stone: 200, glass: 10, wood: 150 },
      { stone: 100, glass: 50, wood: 80 },
    )).toBe(false);
  });
});

describe('Prestige Level', () => {
  it('returns level 1 for low XP', () => {
    expect(getPrestigeLevel(0)).toBe(1);
    expect(getPrestigeLevel(2999)).toBe(1);
  });

  it('returns level 10 for high XP', () => {
    expect(getPrestigeLevel(50000)).toBe(10);
    expect(getPrestigeLevel(999999)).toBe(10);
  });

  it('returns intermediate levels', () => {
    expect(getPrestigeLevel(3000)).toBe(2);
    expect(getPrestigeLevel(8000)).toBe(4);
    expect(getPrestigeLevel(15000)).toBe(6);
  });
});
