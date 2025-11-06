export interface RuleContext {
  geography: string;
  maxQueriesPerPeriod: number;
  queriesUsed: number;
  expiry: number;
}

export interface PolicyResult {
  allowed: boolean;
  reason: string;
}

export type Policy = (context: RuleContext) => PolicyResult;
