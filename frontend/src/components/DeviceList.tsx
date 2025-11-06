import { useQuery } from '@tanstack/react-query';
import type { Aptos } from '@aptos-labs/ts-sdk';

interface DeviceListProps {
  accountAddress: string;
  client: Aptos;
  isLoading: boolean;
}

export function DeviceList({ accountAddress, client, isLoading }: DeviceListProps) {
  const { data, isLoading: isFetching } = useQuery({
    queryKey: ['devices', accountAddress],
    queryFn: async () => {
      return client.getAccountResource({
        accountAddress,
        resourceType: `${accountAddress}::device_registry::DeviceRegistry`,
      });
    },
  });

  if (isLoading || isFetching) {
    return <div className="card">Loading devices…</div>;
  }

  const devices = (data as any)?.data?.devices ?? [];

  if (!devices.length) {
    return <div className="card">No devices registered yet.</div>;
  }

  return (
    <div className="card">
      <table>
        <thead>
          <tr>
            <th>Owner</th>
            <th>Metadata URI</th>
            <th>Stake</th>
            <th>Status</th>
            <th>Reputation</th>
          </tr>
        </thead>
        <tbody>
          {devices.map((device: any) => (
            <tr key={device.owner}>
              <td>{device.owner}</td>
              <td>
                <a href={device.metadata_uri} target="_blank" rel="noreferrer">
                  view
                </a>
              </td>
              <td>{device.stake}</td>
              <td>{device.active ? 'Active' : 'Paused'}</td>
              <td>{device.reputation}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
