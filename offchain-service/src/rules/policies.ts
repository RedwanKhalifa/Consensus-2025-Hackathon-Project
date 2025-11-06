import type { Policy } from './types.js';

const rateLimitPolicy: Policy = ({ maxQueriesPerPeriod, queriesUsed }) => {
  if (queriesUsed >= maxQueriesPerPeriod) {
    return { allowed: false, reason: 'rate_limit_exceeded' };
  }
  return { allowed: true, reason: '' };
};

const expiryPolicy: Policy = ({ expiry }) => {
  const now = Date.now() / 1000;
  if (expiry < now) {
    return { allowed: false, reason: 'subscription_expired' };
  }
  return { allowed: true, reason: '' };
};

const geographyPolicy: Policy = ({ geography }) => {
  if (!geography) {
    return { allowed: false, reason: 'missing_geography' };
  }
  return { allowed: true, reason: '' };
};

export const defaultPolicies: Policy[] = [rateLimitPolicy, expiryPolicy, geographyPolicy];
