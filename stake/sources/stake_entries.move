/// @title SeaPad Staking Entry Points
/// @author SeaPad Team
/// @notice Entry point functions for staking operations
/// @dev Provides user-friendly entry points for all staking operations
/// 
/// Key Features:
/// - Pool registration and management
/// - Staking and unstaking operations
/// - Reward harvesting
/// - Emergency controls
/// - Treasury management
module seapad::stake_entries {
    use seapad::stake;
use seapad::stake_config::{Self, GlobalConfig};
use sui::tx_context::{TxContext, sender};
use sui::coin::{Self, Coin};
use sui::clock::{Self, Clock};
use sui::transfer;
use sui::event;
use sui::object;

    // ============ EVENTS ============
    
    /// @notice Emitted when a pool is registered
    struct PoolRegistered has copy, drop {
        pool_id: address,
        reward_per_sec: u64,
        duration: u64,
        max_stake: u64,
        registered_by: address,
    }
    
    /// @notice Emitted when a user stakes tokens
    struct TokensStaked has copy, drop {
        pool_id: address,
        user: address,
        amount: u64,
        timestamp: u64,
    }
    
    /// @notice Emitted when a user unstakes tokens
    struct TokensUnstaked has copy, drop {
        pool_id: address,
        user: address,
        amount: u64,
        timestamp: u64,
    }
    
    /// @notice Emitted when rewards are harvested
    struct RewardsHarvested has copy, drop {
        pool_id: address,
        user: address,
        amount: u64,
        timestamp: u64,
    }

    // ============ POOL MANAGEMENT ============
    
    /// @notice Register new staking pool with staking coin `S` and reward coin `R`
    /// @param rewards Reward amount in R coins
    /// @param duration Pool life duration in seconds
    /// @param global_config Global configuration object
    /// @param decimalS Decimal places for staking token
    /// @param decimalR Decimal places for reward token
    /// @param clock System clock for timestamp
    /// @param duration_unstake_time_ms Unstaking lock period in milliseconds
    /// @param max_stake_value Maximum stake per user
    /// @param ctx Transaction context
    /// @dev Creates a new staking pool with specified parameters
    public entry fun register_pool<S, R>(
        rewards: Coin<R>,
        duration: u64,
        global_config: &GlobalConfig,
        decimalS: u8,
        decimalR: u8,
        clock: &Clock,
        duration_unstake_time_ms: u64,
        max_stake_value: u64,
        ctx: &mut TxContext
    ) {
        // Validate inputs
        assert!(duration > 0, 1); // Duration must be positive
        assert!(max_stake_value > 0, 2); // Max stake must be positive
        assert!(duration_unstake_time_ms > 0, 3); // Lock period must be positive
        
        let pool_id = stake::register_pool<S, R>(
            rewards,
            duration,
            global_config,
            decimalS,
            decimalR,
            clock::timestamp_ms(clock),
            duration_unstake_time_ms,
            max_stake_value,
            ctx
        );
        
        event::emit(PoolRegistered {
            pool_id,
            reward_per_sec: 0, // Will be calculated in register_pool
            duration,
            max_stake: max_stake_value,
            registered_by: sender(ctx),
        });
    }

    // ============ STAKING OPERATIONS ============
    
    /// @notice Stake an amount of `Coin<S>` to the pool
    /// @param pool The pool to stake in
    /// @param coins Coins to stake
    /// @param global_config Global configuration object
    /// @param clock System clock for timestamp
    /// @param ctx Transaction context
    /// @dev Stakes tokens and starts earning rewards
    public entry fun stake<S, R>(
        pool: &mut stake::StakePool<S, R>,
        coins: Coin<S>,
        global_config: &GlobalConfig,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let user = sender(ctx);
        let amount = coin::value(&coins);
        
        assert!(amount > 0, 4); // Amount must be positive
        
        stake::stake<S, R>(pool, coins, global_config, clock::timestamp_ms(clock), ctx);
        
        event::emit(TokensStaked {
            pool_id: object::id(pool),
            user,
            amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    /// @notice Unstake an amount of `Coin<S>` from a pool
    /// @param pool The pool to unstake from
    /// @param stake_amount Amount of S coins to unstake
    /// @param global_config Global configuration object
    /// @param clock System clock for timestamp
    /// @param ctx Transaction context
    /// @dev Unstakes tokens and transfers them to user
    public entry fun unstake<S, R>(
        pool: &mut stake::StakePool<S, R>,
        stake_amount: u64,
        global_config: &GlobalConfig,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let user = sender(ctx);
        
        assert!(stake_amount > 0, 5); // Amount must be positive
        
        let coins = stake::unstake<S, R>(pool, stake_amount, global_config, clock::timestamp_ms(clock), ctx);
        transfer::public_transfer(coins, user);
        
        event::emit(TokensUnstaked {
            pool_id: object::id(pool),
            user,
            amount: stake_amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    /// @notice Collect user rewards from the pool
    /// @param pool The pool to harvest from
    /// @param global_config Global configuration object
    /// @param clock System clock for timestamp
    /// @param ctx Transaction context
    /// @dev Harvests accumulated rewards and transfers them to user
    public entry fun harvest<S, R>(
        pool: &mut stake::StakePool<S, R>,
        global_config: &GlobalConfig,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let user = sender(ctx);
        
        let rewards = stake::harvest<S, R>(pool, global_config, clock::timestamp_ms(clock), ctx);
        let reward_amount = coin::value(&rewards);
        
        transfer::public_transfer(rewards, user);
        
        event::emit(RewardsHarvested {
            pool_id: object::id(pool),
            user,
            amount: reward_amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ============ REWARD MANAGEMENT ============
    
    /// @notice Deposit more reward coins to the pool
    /// @param pool The pool to deposit rewards to
    /// @param reward_coins Reward coins to deposit
    /// @param global_config Global configuration object
    /// @param clock System clock for timestamp
    /// @param ctx Transaction context
    /// @dev Extends pool duration by depositing additional rewards
    public entry fun deposit_reward_coins<S, R>(
        pool: &mut stake::StakePool<S, R>,
        reward_coins: Coin<R>,
        global_config: &GlobalConfig,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&reward_coins);
        assert!(amount > 0, 6); // Amount must be positive
        
        stake::deposit_reward_coins<S, R>(pool, reward_coins, global_config, clock::timestamp_ms(clock), ctx);
    }

    /// @notice Withdraw rewards to treasury
    /// @param pool The pool to withdraw from
    /// @param amount Amount to withdraw
    /// @param global_config Global configuration object
    /// @param clock System clock for timestamp
    /// @param ctx Transaction context
    /// @dev Only callable by treasury admin
    public entry fun withdraw_reward_to_treasury<S, R>(
        pool: &mut stake::StakePool<S, R>,
        amount: u64,
        global_config: &GlobalConfig,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let treasury_addr = sender(ctx);
        assert!(treasury_addr == stake_config::get_treasury_admin_address(global_config), 7); // Only treasury admin
        
        let rewards = stake::withdraw_to_treasury<S, R>(
            pool,
            amount,
            global_config,
            clock::timestamp_ms(clock),
            ctx
        );
        
        transfer::public_transfer(rewards, treasury_addr);
    }

    // ============ EMERGENCY OPERATIONS ============
    
    /// @notice Enable emergency state for a pool
    /// @param pool The pool to enable emergency for
    /// @param global_config Global configuration object
    /// @param ctx Transaction context
    /// @dev Only callable by emergency admin, cannot be disabled
    public entry fun enable_emergency<S, R>(
        pool: &mut stake::StakePool<S, R>,
        global_config: &GlobalConfig,
        ctx: &mut TxContext
    ) {
        let caller = sender(ctx);
        assert!(caller == stake_config::get_emergency_admin_address(global_config), 8); // Only emergency admin
        
        stake::enable_emergency<S, R>(pool, global_config, ctx);
    }

    /// @notice Emergency unstake all user tokens
    /// @param pool The pool to emergency unstake from
    /// @param global_config Global configuration object
    /// @param ctx Transaction context
    /// @dev Only callable in emergency state
    public entry fun emergency_unstake<S, R>(
        pool: &mut stake::StakePool<S, R>,
        global_config: &GlobalConfig,
        ctx: &mut TxContext
    ) {
        let user = sender(ctx);
        
        let stake_coins = stake::emergency_unstake<S, R>(pool, global_config, ctx);
        let amount = coin::value(&stake_coins);
        
        transfer::public_transfer(stake_coins, user);
        
        event::emit(TokensUnstaked {
            pool_id: object::id(pool),
            user,
            amount,
            timestamp: 0, // Emergency operations don't use clock
        });
    }

    // ============ ADMIN OPERATIONS ============
    
    /// @notice Enable global emergency state
    /// @param global_config Global configuration object
    /// @param ctx Transaction context
    /// @dev Only callable by emergency admin
    public entry fun enable_global_emergency(
        global_config: &mut GlobalConfig,
        ctx: &mut TxContext
    ) {
        let caller = sender(ctx);
        assert!(caller == stake_config::get_emergency_admin_address(global_config), 9); // Only emergency admin
        
        stake_config::enable_global_emergency(global_config, ctx);
    }

    /// @notice Set new treasury admin address
    /// @param global_config Global configuration object
    /// @param new_address New treasury admin address
    /// @param ctx Transaction context
    /// @dev Only callable by current treasury admin
    public entry fun set_treasury_admin_address(
        global_config: &mut GlobalConfig,
        new_address: address,
        ctx: &mut TxContext
    ) {
        let caller = sender(ctx);
        assert!(caller == stake_config::get_treasury_admin_address(global_config), 10); // Only treasury admin
        assert!(new_address != @0x0, 11); // Invalid address
        
        stake_config::set_treasury_admin_address(global_config, new_address, ctx);
    }

    /// @notice Set new emergency admin address
    /// @param global_config Global configuration object
    /// @param new_address New emergency admin address
    /// @param ctx Transaction context
    /// @dev Only callable by current emergency admin
    public entry fun set_emergency_admin_address(
        global_config: &mut GlobalConfig,
        new_address: address,
        ctx: &mut TxContext
    ) {
        let caller = sender(ctx);
        assert!(caller == stake_config::get_emergency_admin_address(global_config), 12); // Only emergency admin
        assert!(new_address != @0x0, 13); // Invalid address
        
        stake_config::set_emergency_admin_address(global_config, new_address, ctx);
    }

    // ============ VIEW FUNCTIONS ============
    
    /// @notice Get pool information
    /// @param pool The pool to get info for
    /// @return Tuple of (total_staked, reward_per_sec, end_timestamp, emergency_locked)
    public fun get_pool_info<S, R>(pool: &stake::StakePool<S, R>): (u64, u64, u64, bool) {
        stake::get_pool_info<S, R>(pool)
    }
    
    /// @notice Get user stake information
    /// @param pool The pool to check
    /// @param user User address
    /// @return Tuple of (staked_amount, earned_reward, unlock_time)
    public fun get_user_stake_info<S, R>(pool: &stake::StakePool<S, R>, user: address): (u64, u64, u64) {
        stake::get_user_stake_info<S, R>(pool, user)
    }
}
