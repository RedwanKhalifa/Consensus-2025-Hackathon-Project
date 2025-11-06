module iot_marketplace::data_marketplace {
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_framework::aptos_coin;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    use iot_marketplace::device_registry;

    const ENOT_DEVICE_OWNER: u64 = 1;
    const ENOT_REGISTERED: u64 = 2;
    const ENOT_SUBSCRIBED: u64 = 3;
    const ERULE_VIOLATION: u64 = 4;
    const EALREADY_SUBSCRIBED: u64 = 5;

    struct Stream has store, copy, drop {
        id: u64,
        device_owner: address,
        metadata_uri: String,
        price_per_period: u64,
        period_secs: u64,
        max_queries_per_period: u64,
        geography_allowlist: vector<String>,
        revenue_share_bps: u64,
    }

    struct Subscription has store, copy, drop {
        subscriber: address,
        stream_id: u64,
        expiry: u64,
        queries_used: u64,
        geography: String,
        max_queries_per_period: u64,
    }

    struct SubscriptionKey has copy, drop, store {
        subscriber: address,
        stream_id: u64,
    }

    struct Marketplace has key {
        next_stream_id: u64,
        streams: Table<u64, Stream>,
        subscriptions: Table<SubscriptionKey, Subscription>,
        stream_events: EventHandle<StreamEvent>,
        subscription_events: EventHandle<SubscriptionEvent>,
        access_events: EventHandle<AccessEvent>,
    }

    struct StreamEvent has copy, drop, store {
        stream_id: u64,
        device_owner: address,
        price_per_period: u64,
    }

    struct SubscriptionEvent has copy, drop, store {
        subscriber: address,
        stream_id: u64,
        expiry: u64,
    }

    struct AccessEvent has copy, drop, store {
        subscriber: address,
        stream_id: u64,
        timestamp: u64,
        queries_used: u64,
    }

    public entry fun init(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == device_registry::marketplace_address(), error::invalid_argument(ENOT_DEVICE_OWNER));
        assert!(!exists<Marketplace>(admin_addr), error::already_exists(0));
        move_to(admin, Marketplace {
            next_stream_id: 1,
            streams: table::new(),
            subscriptions: table::new(),
            stream_events: event::new_event_handle<StreamEvent>(admin_addr),
            subscription_events: event::new_event_handle<SubscriptionEvent>(admin_addr),
            access_events: event::new_event_handle<AccessEvent>(admin_addr),
        });
    }

    public entry fun create_stream(
        device_owner: &signer,
        metadata_uri: String,
        price_per_period: u64,
        period_secs: u64,
        max_queries_per_period: u64,
        geography_allowlist: vector<String>,
        revenue_share_bps: u64
    ) acquires Marketplace {
        let owner_addr = signer::address_of(device_owner);
        let device = device_registry::get_device(owner_addr);
        assert!(device.active, error::invalid_argument(ENOT_REGISTERED));

        let marketplace = borrow_global_mut<Marketplace>(device_registry::marketplace_address());
        let stream_id = marketplace.next_stream_id;
        marketplace.next_stream_id = stream_id + 1;

        let stream = Stream {
            id: stream_id,
            device_owner: owner_addr,
            metadata_uri,
            price_per_period,
            period_secs,
            max_queries_per_period,
            geography_allowlist,
            revenue_share_bps,
        };

        table::add(&mut marketplace.streams, stream_id, stream);
        event::emit_event(&mut marketplace.stream_events, StreamEvent { stream_id, device_owner: owner_addr, price_per_period });
    }

    public entry fun purchase_subscription(
        subscriber: &signer,
        stream_id: u64,
        geography: String
    ) acquires Marketplace {
        let subscriber_addr = signer::address_of(subscriber);
        let marketplace = borrow_global_mut<Marketplace>(device_registry::marketplace_address());
        let stream = table::borrow(&marketplace.streams, &stream_id);

        assert!(device_registry::get_device(stream.device_owner).active, error::invalid_argument(ENOT_REGISTERED));
        assert!(geography_allowed(&stream.geography_allowlist, &geography), error::invalid_argument(ERULE_VIOLATION));

        let key = SubscriptionKey { subscriber: subscriber_addr, stream_id };
        if (table::contains(&marketplace.subscriptions, &key)) {
            error::abort_code(EALREADY_SUBSCRIBED);
        }

        aptos_coin::transfer(subscriber, stream.device_owner, stream.price_per_period);
        let now = timestamp::now_seconds();
        let expiry = now + stream.period_secs;

        let subscription = Subscription {
            subscriber: subscriber_addr,
            stream_id,
            expiry,
            queries_used: 0,
            geography,
            max_queries_per_period: stream.max_queries_per_period,
        };
        table::add(&mut marketplace.subscriptions, key, subscription);
        event::emit_event(&mut marketplace.subscription_events, SubscriptionEvent { subscriber: subscriber_addr, stream_id, expiry });
    }

    public entry fun renew_subscription(subscriber: &signer, stream_id: u64) acquires Marketplace {
        let subscriber_addr = signer::address_of(subscriber);
        let marketplace = borrow_global_mut<Marketplace>(device_registry::marketplace_address());
        let stream = table::borrow(&marketplace.streams, &stream_id);
        let key = SubscriptionKey { subscriber: subscriber_addr, stream_id };
        let mut subscription = table::borrow_mut(&mut marketplace.subscriptions, &key);

        aptos_coin::transfer(subscriber, stream.device_owner, stream.price_per_period);
        let now = timestamp::now_seconds();
        if (subscription.expiry < now) {
            subscription.expiry = now + stream.period_secs;
        } else {
            subscription.expiry = subscription.expiry + stream.period_secs;
        }
        subscription.queries_used = 0;
        event::emit_event(&mut marketplace.subscription_events, SubscriptionEvent { subscriber: subscriber_addr, stream_id, expiry: subscription.expiry });
    }

    public entry fun record_access(subscriber: &signer, stream_id: u64) acquires Marketplace {
        let subscriber_addr = signer::address_of(subscriber);
        let marketplace = borrow_global_mut<Marketplace>(device_registry::marketplace_address());
        let key = SubscriptionKey { subscriber: subscriber_addr, stream_id };
        if (!table::contains(&marketplace.subscriptions, &key)) {
            error::abort_code(ENOT_SUBSCRIBED);
        }
        let mut subscription = table::borrow_mut(&mut marketplace.subscriptions, &key);
        let now = timestamp::now_seconds();
        if (subscription.expiry < now) {
            error::abort_code(ERULE_VIOLATION);
        }
        if (subscription.queries_used >= subscription.max_queries_per_period) {
            error::abort_code(ERULE_VIOLATION);
        }
        subscription.queries_used = subscription.queries_used + 1;
        event::emit_event(&mut marketplace.access_events, AccessEvent {
            subscriber: subscriber_addr,
            stream_id,
            timestamp: now,
            queries_used: subscription.queries_used,
        });
    }

    public fun get_stream(stream_id: u64): Stream acquires Marketplace {
        let marketplace = borrow_global<Marketplace>(device_registry::marketplace_address());
        *table::borrow(&marketplace.streams, &stream_id)
    }

    public fun get_subscription(subscriber: address, stream_id: u64): Option<Subscription> acquires Marketplace {
        let marketplace = borrow_global<Marketplace>(device_registry::marketplace_address());
        let key = SubscriptionKey { subscriber, stream_id };
        if (table::contains(&marketplace.subscriptions, &key)) {
            option::some(*table::borrow(&marketplace.subscriptions, &key))
        } else {
            option::none()
        }
    }

    fun geography_allowed(allowlist: &vector<String>, geography: &String): bool {
        let len = vector::length(allowlist);
        let mut i = 0;
        while (i < len) {
            if (string::eq(&allowlist[i], geography)) {
                return true;
            };
            i = i + 1;
        }
        false
    }
}
