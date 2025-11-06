import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Aptos } from '@aptos-labs/ts-sdk';

import { DeviceList } from './components/DeviceList';
import { StreamTable } from './components/StreamTable';
import { useWalletSimulation } from './hooks/useWalletSimulation';

const client = new Aptos({
  network: {
    name: 'custom',
    chainId: 1,
    url: import.meta.env.VITE_FULLNODE_URL ?? 'https://fullnode.mainnet.aptoslabs.com/v1',
  },
});

export function App() {
  const [address] = useState(import.meta.env.VITE_MARKETPLACE_ADDRESS ?? '0xCAFE');
  const wallet = useWalletSimulation(address);

  const { isLoading } = useQuery({
    queryKey: ['marketplace', address],
    queryFn: async () => {
      return client.getAccountResources({ accountAddress: address });
    },
  });

  return (
    <div className="app">
      <header className="app__header">
        <div>
          <h1>IoT Data Marketplace</h1>
          <p>Access real-world IoT data streams with built-in compliance and monetization.</p>
        </div>
        <div className="app__wallet">
          <span className="app__wallet-label">Connected wallet</span>
          <strong>{wallet.account.address}</strong>
        </div>
      </header>

      <main className="app__content">
        <section>
          <h2>Registered Devices</h2>
          <DeviceList accountAddress={address} client={client} isLoading={isLoading} />
        </section>
        <section>
          <h2>Published Streams</h2>
          <StreamTable accountAddress={address} client={client} isLoading={isLoading} />
        </section>
      </main>
    </div>
  );
}
