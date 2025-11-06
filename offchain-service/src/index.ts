import 'dotenv/config';
import express from 'express';

import { AptosMarketplaceClient } from './oracle/aptosClient.js';
import { RulesEngine } from './rules/engine.js';

const app = express();
app.use(express.json());

const port = process.env.PORT ? Number(process.env.PORT) : 4000;

const aptos = new AptosMarketplaceClient({
  nodeUrl: process.env.APTOS_NODE_URL ?? 'https://fullnode.mainnet.aptoslabs.com/v1',
  contractAddress: process.env.CONTRACT_ADDRESS ?? '0xCAFE',
});

const rulesEngine = new RulesEngine();

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', network: aptos.nodeUrl });
});

app.post('/streams/:id/access', async (req, res) => {
  try {
    const streamId = Number(req.params.id);
    const { subscriber, geography, signature } = req.body as {
      subscriber: string;
      geography: string;
      signature: string;
    };

    const subscription = await aptos.getSubscription(subscriber, streamId);
    if (!subscription) {
      return res.status(404).json({ error: 'subscription_not_found' });
    }

    const ruleCheck = rulesEngine.evaluateAccess({
      geography,
      maxQueriesPerPeriod: subscription.max_queries_per_period,
      queriesUsed: subscription.queries_used,
      expiry: Number(subscription.expiry),
    });

    if (!ruleCheck.allowed) {
      return res.status(403).json({ error: 'rules_violation', reasons: ruleCheck.reasons });
    }

    await aptos.recordAccess(signature, streamId);

    res.json({ status: 'granted', expiresAt: subscription.expiry, usage: subscription.queries_used + 1 });
  } catch (error) {
    console.error('access error', error);
    res.status(500).json({ error: 'internal_error' });
  }
});

app.post('/streams/:id/publish', async (req, res) => {
  try {
    const streamId = Number(req.params.id);
    const { payload, hash } = req.body as { payload: unknown; hash: string };
    await aptos.verifyDataHash(streamId, hash);
    // Persist payload to storage provider of choice.
    res.json({ status: 'stored', streamId });
  } catch (error) {
    console.error('publish error', error);
    res.status(500).json({ error: 'internal_error' });
  }
});

app.listen(port, () => {
  console.log(`off-chain service listening on port ${port}`);
});
