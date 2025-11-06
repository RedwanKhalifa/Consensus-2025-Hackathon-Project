# IoT Marketplace Dashboard

React + Vite dashboard that surfaces device registrations, marketplace streams, and subscription activity coming from the Aptos Move contracts.

## Highlights

- Connects to the Aptos TypeScript SDK to fetch on-chain resources.
- Uses TanStack Query for caching and automatic refresh of state.
- Dark, neon-inspired UI to highlight device and stream metrics.

## Quickstart

```bash
cd frontend
npm install
npm run dev
```

Set environment variables in a `.env` file if needed:

```
VITE_FULLNODE_URL=https://fullnode.testnet.aptoslabs.com/v1
VITE_MARKETPLACE_ADDRESS=0x...
```
