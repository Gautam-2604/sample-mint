module ggcoin::ggcoin {
    use sui::coin::{Self, TreasuryCap};
    use sui::tx_context::{sender, TxContext};
    use sui::transfer;
    use std::option;
    use sui::event;

    struct GGCOIN has drop {}

    struct MintEvent has copy, drop {
        minter: address,
        recipient: address,
        amount: u64,
    }

    fun init(witness: GGCOIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            8, // decimals
            b"GGC",
            b"GGCoin",
            b"Gaming Governance Coin",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, sender(ctx));
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<GGCOIN>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
        
        event::emit(MintEvent {
            minter: sender(ctx),
            recipient,
            amount
        });
    }

    public entry fun burn(
        treasury_cap: &mut TreasuryCap<GGCOIN>,
        coin: coin::Coin<GGCOIN>
    ) {
        coin::burn(treasury_cap, coin);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(GGCOIN {}, ctx)
    }
}

#[test_only]
module ggcoin::ggcoin_tests {
    use sui::test_scenario as ts;
    use sui::coin::TreasuryCap;
    use ggcoin::ggcoin::{Self, GGCOIN, init_for_testing};

    #[test]
    fun test_mint() {
        let admin = @0xA;
        let user = @0xB;
        
        let scenario = ts::begin(admin);
        {
            init_for_testing(ts::ctx(&mut scenario));
        };

        ts::next_tx(&mut scenario, admin);
        {
            let cap = ts::take_from_sender<TreasuryCap<GGCOIN>>(&mut scenario);
            ggcoin::mint(&mut cap, 100000000, user, ts::ctx(&mut scenario));
            ts::return_to_sender(&mut scenario, cap);
        };

        ts::end(scenario);
    }
}