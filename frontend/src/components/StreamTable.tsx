import { useQuery } from '@tanstack/react-query';
import type { Aptos } from '@aptos-labs/ts-sdk';

interface StreamTableProps {
  accountAddress: string;
  client: Aptos;
  isLoading: boolean;
}

export function StreamTable({ accountAddress, client, isLoading }: StreamTableProps) {
  const { data, isLoading: isFetching } = useQuery({
    queryKey: ['streamState', accountAddress],
    queryFn: async () => {
      return client.getAccountResource({
        accountAddress,
        resourceType: `${accountAddress}::data_marketplace::Marketplace`,
      });
    },
  });

  if (isLoading || isFetching) {
    return <div className="card">Loading streams…</div>;
  }

  const streamList = (data as any)?.data?.streams ?? [];

  if (!streamList.length) {
    return <div className="card">No streams published yet.</div>;
  }

  return (
    <div className="card">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Owner</th>
            <th>Price / Period</th>
            <th>Period (s)</th>
            <th>Queries</th>
          </tr>
        </thead>
        <tbody>
          {streamList.map((stream: any) => (
            <tr key={stream.id}>
              <td>{stream.id}</td>
              <td>{stream.device_owner}</td>
              <td>{stream.price_per_period}</td>
              <td>{stream.period_secs}</td>
              <td>{stream.max_queries_per_period}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
