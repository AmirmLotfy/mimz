import { describe, it, expect } from 'vitest';
import { STRUCTURE_CATALOG } from '../src/models/types.js';

describe('Structure Catalog', () => {
  it('contains exactly 5 structures', () => {
    expect(STRUCTURE_CATALOG.length).toBe(5);
  });

  it('all structures have required fields', () => {
    for (const s of STRUCTURE_CATALOG) {
      expect(s.id).toBeTruthy();
      expect(s.name).toBeTruthy();
      expect(s.description).toBeTruthy();
      expect(['common', 'rare', 'master']).toContain(s.tier);
      expect(s.cost.stone).toBeGreaterThanOrEqual(0);
      expect(s.cost.glass).toBeGreaterThanOrEqual(0);
      expect(s.cost.wood).toBeGreaterThanOrEqual(0);
      expect(s.prestigeValue).toBeGreaterThan(0);
      expect(s.requirements.minSectors).toBeGreaterThan(0);
      expect(s.requirements.minXp).toBeGreaterThanOrEqual(0);
    }
  });

  it('has unique IDs', () => {
    const ids = STRUCTURE_CATALOG.map(s => s.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('includes Library, Observatory, Archive, Park Pavilion, Maker Hub', () => {
    const names = STRUCTURE_CATALOG.map(s => s.name);
    expect(names).toContain('Library');
    expect(names).toContain('Observatory');
    expect(names).toContain('Archive');
    expect(names).toContain('Park Pavilion');
    expect(names).toContain('Maker Hub');
  });

  it('master tier costs more than common', () => {
    const common = STRUCTURE_CATALOG.find(s => s.tier === 'common')!;
    const master = STRUCTURE_CATALOG.find(s => s.tier === 'master')!;
    expect(master.cost.stone).toBeGreaterThan(common.cost.stone);
    expect(master.prestigeValue).toBeGreaterThan(common.prestigeValue);
  });
});
