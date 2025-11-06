import { describe, expect, it } from 'vitest';

import { RulesEngine } from './engine.js';

const engine = new RulesEngine();

describe('RulesEngine', () => {
  it('allows access when all policies pass', () => {
    const result = engine.evaluateAccess({
      geography: 'US',
      maxQueriesPerPeriod: 10,
      queriesUsed: 3,
      expiry: Math.floor(Date.now() / 1000) + 60,
    });
    expect(result.allowed).toBe(true);
    expect(result.reasons).toHaveLength(0);
  });

  it('blocks when rate limit exceeded', () => {
    const result = engine.evaluateAccess({
      geography: 'US',
      maxQueriesPerPeriod: 1,
      queriesUsed: 1,
      expiry: Math.floor(Date.now() / 1000) + 60,
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('rate_limit_exceeded');
  });
});
