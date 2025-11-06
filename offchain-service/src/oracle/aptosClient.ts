import { Aptos, Network, type InputGenerateTransactionOptions } from '@aptos-labs/ts-sdk';

export interface AptosMarketplaceClientOptions {
  nodeUrl: string;
  contractAddress: string;
}

export class AptosMarketplaceClient {
  private readonly client: Aptos;
  readonly nodeUrl: string;
  private readonly contractAddress: string;

  constructor(options: AptosMarketplaceClientOptions) {
    this.client = new Aptos({ network: Network.CUSTOM, fullnode: options.nodeUrl });
    this.nodeUrl = options.nodeUrl;
    this.contractAddress = options.contractAddress;
  }

  async getSubscription(subscriber: string, streamId: number) {
    const resourceType = `${this.contractAddress}::data_marketplace::Marketplace`;
    try {
      const resource = await this.client.getAccountResource({
        accountAddress: this.contractAddress,
        resourceType,
      });
      const subscriptions = (resource as any).data.subscriptions.handle as string;
      const keyType = `${this.contractAddress}::data_marketplace::SubscriptionKey`;
      const valueType = `${this.contractAddress}::data_marketplace::Subscription`;
      return await this.client.getTableItem<{ subscriber: string; stream_id: string }, any>({
        handle: subscriptions,
        data: {
          key_type: keyType,
          value_type: valueType,
          key: { subscriber, stream_id: streamId.toString() },
        },
      });
    } catch (error) {
      console.warn('subscription lookup failed', error);
      return null;
    }
  }

  async recordAccess(signature: string, streamId: number) {
    const payload: InputGenerateTransactionOptions = {
      sender: this.contractAddress,
      data: {
        function: `${this.contractAddress}::data_marketplace::record_access`,
        typeArguments: [],
        functionArguments: [signature, streamId],
      },
    };
    // In production we would submit the transaction using a sponsored account or aggregator.
    return payload;
  }

  async verifyDataHash(streamId: number, expectedHash: string) {
    console.log('verify hash', streamId, expectedHash);
  }
}
