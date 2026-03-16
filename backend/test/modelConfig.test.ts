import { describe, it, expect } from 'vitest';
import { MODEL_REGISTRY, getModelWithFallback, LIVE_MODEL, ASYNC_MODEL, UTILITY_MODEL } from '../src/config/models.js';

describe('Model Configuration Registry', () => {

  it('should export correct default model IDs', () => {
    expect(LIVE_MODEL).toBeDefined();
    expect(ASYNC_MODEL).toBeDefined();
    expect(UTILITY_MODEL).toBeDefined();
    
    // Check that env overrides are prioritized over fallbacks
    // (In test env, these might be undefined or set to specific defaults)
    const expectedLive = process.env.GEMINI_LIVE_MODEL || 'gemini-2.5-flash-native-audio-preview-12-2025';
    expect(LIVE_MODEL).toBe(expectedLive);
  });

  it('should have fallbacks for all model roles', () => {
    for (const [role, config] of Object.entries(MODEL_REGISTRY)) {
      expect(config.id).toBeDefined();
      expect(config.costTier).toBeDefined();
      // Even if fallback isn't explicitly provided, it should exist in the registry object structure
      expect(config).toHaveProperty('fallback');
    }
  });

  it('getModelWithFallback should return accurate pairs', () => {
    const livePair = getModelWithFallback('LIVE_REALTIME');
    expect(livePair.primary).toBe(LIVE_MODEL);
    expect(livePair.fallback).toBeDefined();

    const asyncPair = getModelWithFallback('ASYNC_CHALLENGE');
    expect(asyncPair.primary).toBe(ASYNC_MODEL);
    expect(asyncPair.fallback).toBeDefined();
    
    const utilityPair = getModelWithFallback('LOW_COST_UTILITY');
    expect(utilityPair.primary).toBe(UTILITY_MODEL);
    expect(utilityPair.fallback).toBeDefined();
    
    // If fallback is omitted in config, it should match primary
    if (MODEL_REGISTRY.LOW_COST_UTILITY.fallback === undefined) {
       expect(utilityPair.fallback).toBe(utilityPair.primary);
    }
  });

  it('should throw on unknown role', () => {
    expect(() => getModelWithFallback('UNKNOWN_ROLE' as any)).toThrow('Unknown model role: UNKNOWN_ROLE');
  });

});
