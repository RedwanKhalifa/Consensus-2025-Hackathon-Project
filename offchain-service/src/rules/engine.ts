import type { RuleContext } from './types.js';
import { defaultPolicies } from './policies.js';

export interface RuleEvaluation {
  allowed: boolean;
  reasons: string[];
}

export class RulesEngine {
  evaluateAccess(context: RuleContext): RuleEvaluation {
    const reasons: string[] = [];
    let allowed = true;

    for (const policy of defaultPolicies) {
      const result = policy(context);
      if (!result.allowed) {
        allowed = false;
        reasons.push(result.reason);
      }
    }

    return { allowed, reasons };
  }
}
