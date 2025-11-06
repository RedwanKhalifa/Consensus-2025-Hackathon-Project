# IoT Data-as-a-Service Marketplace on Aptos

This repository implements a reference stack for a decentralized marketplace that lets IoT device owners monetize telemetry streams while providing buyers with compliant, rule-governed access. The stack is tailored for the Aptos ecosystem and showcases how Forte-style real-world data assets can be tokenized, governed, and monetized.

## Repository Structure

- `aptos-move/` – Move package with on-chain modules for device registration, staking, stream publishing, and subscription lifecycle management.
- `offchain-service/` – Node.js service that bridges on-chain state with off-chain storage, rule enforcement, and oracle callbacks.
- `frontend/` – React dashboard for device owners and subscribers.

## Key Capabilities

### Device Registry (Move)

- Device owners stake APT to register their hardware and metadata on-chain.
- Admin-managed compliance toggles (pause/resume) and dynamic reputation scoring.
- Deregistration workflow with controlled stake refunds.

### Data Marketplace (Move)

- Registered devices can publish metered data streams with pricing, duration, rate limits, and geography rules.
- Buyers acquire time-bound subscriptions that mint verifiable permissions enforced by the compliance layer.
- Access events are recorded on-chain to keep accounting and usage transparent.

### Compliance + Oracle Layer (Node.js)

- Fetches Move resources to verify subscription state in real time.
- Runs a configurable rules engine to enforce rate limits, expirations, and geofencing before devices transmit data.
- Prepares sponsored Aptos transactions so relayers can attest to usage and settle revenue.

### Dashboard (React)

- Visualizes registered devices, stakes, reputations, and published streams.
- Uses the Aptos TypeScript SDK and TanStack Query for live data fetching.
- Neon, sci-fi inspired UI to highlight key metrics for operators.

## Getting Started

1. **Move Modules**
   ```bash
   cd aptos-move
   aptos move test
   ```
   Deploy using the Aptos CLI once you configure the `iot_marketplace` address.

2. **Off-chain Service**
   ```bash
   cd offchain-service
   npm install
   npm run dev
   ```

3. **Frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

Configure environment variables as described in the individual package READMEs to point to your desired Aptos network and contract addresses.
