# Aptos Move Modules

The Move package defines the smart-contract layer for the IoT Data-as-a-Service marketplace. Two primary modules are exposed:

- `device_registry` handles device staking, reputation, and lifecycle management.
- `data_marketplace` manages stream definitions, subscription purchases, renewals, and access tracking.

## Quickstart

```bash
aptos move test
aptos move compile
```

Set the `iot_marketplace` address inside `Move.toml` to the deploying account before publishing.

## Module Summary

### `device_registry`

- `init(admin)` publishes the registry resource under the marketplace address.
- `register_device` transfers stake from the device owner and publishes metadata/compliance tags.
- `pause_device`, `resume_device`, and `update_reputation` let admins enforce compliance.
- `admin_release_stake` releases the bonded stake to a beneficiary during deregistration.

### `data_marketplace`

- `create_stream` attaches pricing, duration, rate limits, and geofencing metadata to a device.
- `purchase_subscription`, `renew_subscription`, and `record_access` mint time-limited permissions enforced by the compliance layer.
- Exposes read-only helpers for dashboards and off-chain automation.
