# Off-chain Compliance & Oracle Service

This Node.js service connects on-chain state from the Aptos Move modules with device telemetry stored off-chain. It exposes a small API that the dashboard and IoT devices can call to:

- verify that a subscriber still has a valid access token before data is streamed;
- forward compliance decisions (rate limits, subscription expiry, geofencing) back on-chain by executing transactions against the `data_marketplace` module;
- persist payloads and hashes in a storage layer such as IPFS, AWS S3 or Forte infrastructure.

## Features

- Aptos TypeScript SDK integration for reading Move resources and preparing transactions;
- Extensible rules engine, shipped with default rate limiting, expiration and geography policies;
- Express REST API for device publishing and subscriber access checks.

## Getting Started

```bash
cd offchain-service
npm install
npm run dev
```

Environment variables:

- `APTOS_NODE_URL` – target fullnode (defaults to the Aptos public endpoint)
- `CONTRACT_ADDRESS` – address that deployed the Move package
- `PORT` – HTTP port (default `4000`)

The `/streams/:id/access` endpoint will look up the subscription on-chain, evaluate the rules, and return whether the device should stream data. When allowed it prepares a transaction payload for recording the access event that can be submitted by a relayer.
