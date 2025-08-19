/// @title SeaPad Token (SPT)
/// @author SeaPad Team
/// @notice SUI-based token for SeaPad launchpad ecosystem
/// @dev Implements a comprehensive token with minting, burning, and supply management
/// 
/// Key Features:
/// - Standard SUI coin implementation
/// - Minting and burning capabilities
/// - Supply management functions
/// - Treasury cap management
/// - Comprehensive access controls
module seapad::spt {
    use std::ascii::string;
    use std::option;
    use w3libs::payment;
    use sui::balance;
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::transfer::{Self, public_freeze_object};
    use sui::tx_context::{TxContext, sender};
    use sui::url;
    use sui::event;

    // ============ CONSTANTS ============
    
    /// @notice Token symbol
    const SYMBOL: vector<u8> = b"SPT";
    
    /// @notice Token name
    const NAME: vector<u8> = b"SeaPad Token";
    
    /// @notice Token description
    const DESCRIPTION: vector<u8> = b"SeaPad launchpad foundation token for ecosystem governance and rewards";
    
    /// @notice Token decimal places
    const DECIMAL: u8 = 9;
    
    /// @notice Token icon URL
    const ICON_URL: vector<u8> = b"https://seapad.s3.ap-southeast-1.amazonaws.com/uploads/TEST/public/media/images/logo_1679906850804.png";
    
    /// @notice Maximum supply cap (if applicable)
    const MAX_SUPPLY: u64 = 1000000000000000000; // 1 billion tokens with 9 decimals

    // ============ ERRORS ============
    
    /// @notice Error when minting amount exceeds maximum supply
    const ERR_EXCEEDS_MAX_SUPPLY: u64 = 100;
    
    /// @notice Error when minting amount is zero
    const ERR_ZERO_AMOUNT: u64 = 101;
    
    /// @notice Error when burning amount is zero
    const ERR_ZERO_BURN_AMOUNT: u64 = 102;
    
    /// @notice Error when caller doesn't have permission
    const ERR_NO_PERMISSION: u64 = 103;
    
    /// @notice Error when supply decrease amount is invalid
    const ERR_INVALID_SUPPLY_DECREASE: u64 = 104;

    // ============ TYPES ============
    
    /// @notice Witness type for initialization
    struct SPT has drop {}

    // ============ EVENTS ============
    
    /// @notice Emitted when tokens are minted
    struct TokensMinted has copy, drop {
        to: address,
        amount: u64,
        total_supply: u64,
    }
    
    /// @notice Emitted when tokens are burned
    struct TokensBurned has copy, drop {
        from: address,
        amount: u64,
        total_supply: u64,
    }
    
    /// @notice Emitted when supply is increased
    struct SupplyIncreased has copy, drop {
        by: address,
        amount: u64,
        total_supply: u64,
    }
    
    /// @notice Emitted when supply is decreased
    struct SupplyDecreased has copy, drop {
        by: address,
        amount: u64,
        total_supply: u64,
    }
    
    /// @notice Emitted when treasury cap is burned
    struct TreasuryCapBurned has copy, drop {
        by: address,
        timestamp: u64,
    }

    // ============ INITIALIZATION ============
    
    /// @notice Initialize the SPT token
    /// @param witness Witness type for initialization
    /// @param ctx Transaction context
    /// @dev Creates the token with metadata and transfers treasury cap to sender
    fun init(witness: SPT, ctx: &mut TxContext) {
        let (treasury_cap, spt_metadata) = coin::create_currency<SPT>(
            witness,
            DECIMAL,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(url::new_unsafe(string(ICON_URL))),
            ctx
        );

        // Freeze metadata to prevent modifications
        public_freeze_object(spt_metadata);
        
        // Transfer treasury cap to sender
        transfer::public_transfer(treasury_cap, sender(ctx));
    }

    // ============ MINTING FUNCTIONS ============
    
    /// @notice Mint tokens to a specific address
    /// @param treasury_cap Treasury capability for minting
    /// @param to Recipient address
    /// @param amount Amount to mint
    /// @param ctx Transaction context
    /// @dev Only callable by treasury cap owner
    public entry fun mint_to(
        treasury_cap: &mut TreasuryCap<SPT>, 
        to: address, 
        amount: u64, 
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, ERR_ZERO_AMOUNT);
        
        // Check if minting would exceed max supply
        let current_supply = coin::supply_value(treasury_cap);
        assert!(current_supply + amount <= MAX_SUPPLY, ERR_EXCEEDS_MAX_SUPPLY);
        
        // Mint and transfer tokens
        coin::mint_and_transfer(treasury_cap, amount, to, ctx);
        
        // Emit event
        event::emit(TokensMinted {
            to,
            amount,
            total_supply: current_supply + amount,
        });
    }

    /// @notice Increase supply by minting tokens to sender
    /// @param treasury_cap Treasury capability for minting
    /// @param value Amount to mint
    /// @param ctx Transaction context
    /// @dev Only callable by treasury cap owner
    public entry fun increase_supply(
        treasury_cap: &mut TreasuryCap<SPT>, 
        value: u64, 
        ctx: &mut TxContext
    ) {
        assert!(value > 0, ERR_ZERO_AMOUNT);
        
        let sender_addr = sender(ctx);
        
        // Check if minting would exceed max supply
        let current_supply = coin::supply_value(treasury_cap);
        assert!(current_supply + value <= MAX_SUPPLY, ERR_EXCEEDS_MAX_SUPPLY);
        
        // Mint tokens to sender
        coin::mint_and_transfer(treasury_cap, value, sender_addr, ctx);
        
        // Emit event
        event::emit(SupplyIncreased {
            by: sender_addr,
            amount: value,
            total_supply: current_supply + value,
        });
    }

    // ============ BURNING FUNCTIONS ============
    
    /// @notice Decrease supply by burning tokens from a collection
    /// @param treasury_cap Treasury capability for supply management
    /// @param coins Collection of coins to burn from
    /// @param value Amount to burn
    /// @param ctx Transaction context
    /// @dev Only callable by treasury cap owner
    public entry fun decrease_supply(
        treasury_cap: &mut TreasuryCap<SPT>,
        coins: vector<Coin<SPT>>,
        value: u64,
        ctx: &mut TxContext
    ) {
        assert!(value > 0, ERR_ZERO_BURN_AMOUNT);
        
        let sender_addr = sender(ctx);
        let current_supply = coin::supply_value(treasury_cap);
        
        // Take coins from collection
        let coins_to_burn = payment::take_from(coins, value, ctx);
        
        // Decrease supply
        let total_supply = coin::supply_mut(treasury_cap);
        balance::decrease_supply(total_supply, coin::into_balance(coins_to_burn));
        
        // Emit event
        event::emit(SupplyDecreased {
            by: sender_addr,
            amount: value,
            total_supply: current_supply - value,
        });
    }

    /// @notice Burn tokens from a collection
    /// @param treasury_cap Treasury capability for burning
    /// @param coins Collection of coins to burn
    /// @param value Amount to burn
    /// @param ctx Transaction context
    /// @dev Only callable by treasury cap owner
    public entry fun burn(
        treasury_cap: &mut TreasuryCap<SPT>,
        coins: vector<Coin<SPT>>,
        value: u64,
        ctx: &mut TxContext
    ) {
        assert!(value > 0, ERR_ZERO_BURN_AMOUNT);
        
        let sender_addr = sender(ctx);
        let current_supply = coin::supply_value(treasury_cap);
        
        // Take coins from collection
        let coins_to_burn = payment::take_from(coins, value, ctx);
        
        // Burn the coins
        coin::burn(treasury_cap, coins_to_burn);
        
        // Emit event
        event::emit(TokensBurned {
            from: sender_addr,
            amount: value,
            total_supply: current_supply - value,
        });
    }

    // ============ TREASURY MANAGEMENT ============
    
    /// @notice Burn treasury cap to permanently disable minting
    /// @param treasury_cap Treasury capability to burn
    /// @param ctx Transaction context
    /// @dev CRITICAL: This action is irreversible and will permanently disable minting
    public entry fun burn_treasury_cap(
        treasury_cap: TreasuryCap<SPT>, 
        ctx: &mut TxContext
    ) {
        let sender_addr = sender(ctx);
        
        // Freeze the treasury cap to prevent further minting
        public_freeze_object(treasury_cap);
        
        // Emit event
        event::emit(TreasuryCapBurned {
            by: sender_addr,
            timestamp: 0, // TODO: Add timestamp from clock
        });
    }

    // ============ VIEW FUNCTIONS ============
    
    /// @notice Get token metadata
    /// @return Tuple of (symbol, name, description, decimals)
    public fun get_token_info(): (vector<u8>, vector<u8>, vector<u8>, u8) {
        (SYMBOL, NAME, DESCRIPTION, DECIMAL)
    }
    
    /// @notice Get maximum supply
    /// @return Maximum supply cap
    public fun get_max_supply(): u64 {
        MAX_SUPPLY
    }

    // ============ TEST FUNCTIONS ============
    
    /// @notice Test-only initialization function
    /// @param ctx Transaction context
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(SPT {}, ctx);
    }
    
    /// @notice Test-only function to get treasury cap for testing
    /// @param ctx Transaction context
    /// @return Treasury capability
    #[test_only]
    public fun get_treasury_cap_for_testing(ctx: &mut TxContext): TreasuryCap<SPT> {
        let (treasury_cap, _) = coin::create_currency<SPT>(
            SPT {},
            DECIMAL,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(url::new_unsafe(string(ICON_URL))),
            ctx
        );
        treasury_cap
    }
}
