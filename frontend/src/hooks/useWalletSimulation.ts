import { useMemo } from 'react';

export function useWalletSimulation(address: string) {
  return useMemo(() => ({
    account: {
      address,
      balance: '0',
    },
  }), [address]);
}
