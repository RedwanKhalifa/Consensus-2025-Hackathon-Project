# Consensus 2025 Hackathon Project

A full-stack reference implementation of an **IoT Data-as-a-Service marketplace on Aptos**.

This project demonstrates how device owners can register IoT devices, publish paid data streams, and monetize subscriber access with an on-chain permission model plus off-chain compliance checks.

## Architecture

The repository is split into three coordinated components:

- **`aptos-move/`** – Move smart contracts for device registration, staking, stream creation, subscriptions, and access recording.
- **`offchain-service/`** – Node.js compliance/oracle service that validates subscriber access and evaluates policy rules before data delivery.
- **`frontend/`** – React + Vite dashboard for viewing devices, streams, and marketplace activity.

## Core Capabilities

### 1) On-chain Device Registry

- Stake-backed device registration.
- Compliance controls (pause/resume).
- Reputation updates.
- Controlled stake release flows.

### 2) On-chain Data Marketplace

- Stream creation with pricing, duration, and policy metadata.
- Time-bound subscription purchase and renewal.
- On-chain access event tracking for transparent accounting.

### 3) Off-chain Compliance + Oracle Layer

- Reads Aptos on-chain state using the Aptos TypeScript SDK.
- Runs policy checks (rate limits, expiry, geofencing).
- Returns allow/deny decisions for telemetry access.
- Prepares payloads/transactions for usage attestation.

### 4) Web Dashboard

- Presents device and stream data in a live interface.
- Uses TanStack Query for refresh/caching.
- Simulated wallet flow for hackathon UX and demos.

## Repository Structure

```text
.
├── aptos-move/          # Move package (smart contracts)
├── offchain-service/    # Node.js compliance & oracle service
└── frontend/            # React dashboard
```

## Prerequisites

- **Node.js 18+** and npm
- **Aptos CLI** (for Move compile/test/deploy)
- Access to an Aptos fullnode (testnet/devnet/local)

## Quick Start

### A) Smart Contracts (Move)

```bash
cd aptos-move
aptos move compile
aptos move test
```

Before deployment, set the package address in `aptos-move/Move.toml`.

### B) Off-chain Service

```bash
cd offchain-service
npm install
npm run dev
```

Common environment variables:

- `APTOS_NODE_URL` (default Aptos endpoint)
- `CONTRACT_ADDRESS` (deployed Move package address)
- `PORT` (default `4000`)

### C) Frontend

```bash
cd frontend
npm install
npm run dev
```

Typical `.env` values:

```env
VITE_FULLNODE_URL=https://fullnode.testnet.aptoslabs.com/v1
VITE_MARKETPLACE_ADDRESS=0x...
```

## Typical Development Flow

1. Update Move modules and run `aptos move test`.
2. Deploy contracts and set the deployed address in both services.
3. Start the off-chain service and confirm access policy evaluation.
4. Start the frontend and verify device/stream/subscription views.

## Package-level Documentation

For deeper usage details, see:

- [`aptos-move/README.md`](aptos-move/README.md)
- [`offchain-service/README.md`](offchain-service/README.md)
- [`frontend/README.md`](frontend/README.md)

## Hackathon Focus

This codebase is optimized for demonstration and iteration speed. For production use, add:

- stronger key management and signer isolation,
- robust authn/authz and API hardening,
- observability, retries, and durable queues,
- comprehensive integration/security testing.
