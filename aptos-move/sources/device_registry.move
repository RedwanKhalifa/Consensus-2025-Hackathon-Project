module iot_marketplace::device_registry {
    use std::error;
    use std::signer;
    use std::string::{Self, String};

    use aptos_framework::aptos_coin;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    const ENOT_AUTHORIZED: u64 = 1;
    const EALREADY_REGISTERED: u64 = 2;
    const ENOT_REGISTERED: u64 = 3;

    struct Device has copy, drop, store {
        owner: address,
        metadata_uri: String,
        compliance_tags: vector<String>,
        stake: u64,
        active: bool,
        reputation: u64,
    }

    struct DeviceRegistry has key {
        devices: Table<address, Device>,
        registrations: EventHandle<RegistrationEvent>,
        updates: EventHandle<DeviceUpdateEvent>,
    }

    struct RegistrationEvent has copy, drop, store {
        device: address,
        metadata_uri: String,
        stake: u64,
    }

    struct DeviceUpdateEvent has copy, drop, store {
        device: address,
        active: bool,
        reputation: u64,
    }

    public entry fun init(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == marketplace_address(), error::invalid_argument(ENOT_AUTHORIZED));
        assert!(!exists<DeviceRegistry>(admin_addr), error::already_exists(0));
        move_to(admin, DeviceRegistry {
            devices: table::new(),
            registrations: event::new_event_handle<RegistrationEvent>(admin_addr),
            updates: event::new_event_handle<DeviceUpdateEvent>(admin_addr),
        });
    }

    public entry fun register_device(
        device_owner: &signer,
        metadata_uri: String,
        compliance_tags: vector<String>,
        stake_amount: u64
    ) acquires DeviceRegistry {
        let owner_addr = signer::address_of(device_owner);
        let registry = borrow_global_mut<DeviceRegistry>(marketplace_address());

        if (table::contains(&registry.devices, owner_addr)) {
            error::abort_code(EALREADY_REGISTERED);
        }

        aptos_coin::transfer(device_owner, staking_vault_address(), stake_amount);

        let device = Device {
            owner: owner_addr,
            metadata_uri: string::clone(&metadata_uri),
            compliance_tags,
            stake: stake_amount,
            active: true,
            reputation: 0,
        };
        table::add(&mut registry.devices, owner_addr, device);
        event::emit_event(&mut registry.registrations, RegistrationEvent {
            device: owner_addr,
            metadata_uri,
            stake: stake_amount,
        });
    }

    public entry fun pause_device(admin: &signer, device_owner: address) acquires DeviceRegistry {
        assert_admin(admin);
        let registry = borrow_global_mut<DeviceRegistry>(marketplace_address());
        let mut device = table::borrow_mut(&mut registry.devices, device_owner);
        device.active = false;
        event::emit_event(&mut registry.updates, DeviceUpdateEvent { device: device_owner, active: false, reputation: device.reputation });
    }

    public entry fun resume_device(admin: &signer, device_owner: address) acquires DeviceRegistry {
        assert_admin(admin);
        let registry = borrow_global_mut<DeviceRegistry>(marketplace_address());
        let mut device = table::borrow_mut(&mut registry.devices, device_owner);
        device.active = true;
        event::emit_event(&mut registry.updates, DeviceUpdateEvent { device: device_owner, active: true, reputation: device.reputation });
    }

    public entry fun update_reputation(admin: &signer, device_owner: address, delta: u64, is_positive: bool) acquires DeviceRegistry {
        assert_admin(admin);
        let registry = borrow_global_mut<DeviceRegistry>(marketplace_address());
        let mut device = table::borrow_mut(&mut registry.devices, device_owner);
        if (is_positive) {
            device.reputation = device.reputation + delta;
        } else {
            if (device.reputation > delta) {
                device.reputation = device.reputation - delta;
            } else {
                device.reputation = 0;
            }
        };
        event::emit_event(&mut registry.updates, DeviceUpdateEvent { device: device_owner, active: device.active, reputation: device.reputation });
    }

    public entry fun request_deregistration(device_owner: &signer) acquires DeviceRegistry {
        let owner_addr = signer::address_of(device_owner);
        let registry = borrow_global_mut<DeviceRegistry>(marketplace_address());
        if (!table::contains(&registry.devices, owner_addr)) {
            error::abort_code(ENOT_REGISTERED);
        }
        let mut device = table::borrow_mut(&mut registry.devices, owner_addr);
        device.active = false;
        event::emit_event(&mut registry.updates, DeviceUpdateEvent { device: owner_addr, active: false, reputation: device.reputation });
    }

    public entry fun admin_release_stake(admin: &signer, device_owner: address, beneficiary: address) acquires DeviceRegistry {
        assert_admin(admin);
        let registry = borrow_global_mut<DeviceRegistry>(marketplace_address());
        if (!table::contains(&registry.devices, device_owner)) {
            error::abort_code(ENOT_REGISTERED);
        }
        let device = table::remove(&mut registry.devices, device_owner);
        aptos_coin::transfer(admin, beneficiary, device.stake);
    }

    public fun get_device(device_owner: address): Device acquires DeviceRegistry {
        let registry = borrow_global<DeviceRegistry>(marketplace_address());
        table::borrow(&registry.devices, device_owner)
    }

    public(friend) fun staking_vault_address(): address {
        marketplace_address()
    }

    public(friend) fun marketplace_address(): address {
        @iot_marketplace
    }

    fun assert_admin(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == marketplace_address(), error::invalid_argument(ENOT_AUTHORIZED));
    }
}
