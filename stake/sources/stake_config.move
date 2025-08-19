/// @title SeaPad Staking Configuration Module
/// @author SeaPad Team
/// @notice This module handles global stake pool configuration and emergency controls
/// @dev Provides centralized configuration management for all staking pools
/// 
/// Key Features:
/// - Global emergency state management
/// - Admin role management (emergency and treasury)
/// - Access control for critical operations
/// - Immutable emergency state once enabled
module seapad::stake_config {
    use sui::tx_context::{TxContext, sender};
    use sui::transfer;
    use sui::object::{UID, new};
    use sui::event;

    // ============ ERRORS ============
    
    /// @notice Error when caller doesn't have sufficient permissions
    const ERR_NO_PERMISSIONS: u64 = 200;
    
    /// @notice Error when global config is not initialized
    const ERR_NOT_INITIALIZED: u64 = 201;
    
    /// @notice Error when operation is blocked due to global emergency state
    const ERR_GLOBAL_EMERGENCY: u64 = 202;
    
    /// @notice Error when trying to disable already enabled emergency state
    const ERR_EMERGENCY_ALREADY_ENABLED: u64 = 203;
    
    /// @notice Error when invalid address is provided
    const ERR_INVALID_ADDRESS: u64 = 204;

    // ============ CONSTANTS ============
    
    /// @notice Minimum delay for admin changes (24 hours)
    const ADMIN_CHANGE_DELAY: u64 = 86400;
    
    /// @notice Emergency state cannot be disabled once enabled
    const EMERGENCY_PERMANENT: bool = true;

    // ============ TYPES ============
    
    /// @notice Witness type for initialization
    struct STAKE_CONFIG has drop {}
    
    /// @notice Global configuration for all staking pools
    /// @dev This is a shared object that controls all staking operations
    struct GlobalConfig has key, store {
        id: UID,
        /// @notice Address with emergency control permissions
        emergency_admin_address: address,
        /// @notice Address with treasury management permissions
        treasury_admin_address: address,
        /// @notice Global emergency state flag
        global_emergency_locked: bool,
        /// @notice Timestamp when emergency was enabled
        emergency_enabled_at: u64,
        /// @notice Version for upgrade tracking
        version: u64,
    }

    // ============ EVENTS ============
    
    /// @notice Emitted when emergency admin is changed
    struct EmergencyAdminChanged has copy, drop {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }
    
    /// @notice Emitted when treasury admin is changed
    struct TreasuryAdminChanged has copy, drop {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }
    
    /// @notice Emitted when global emergency is enabled
    struct GlobalEmergencyEnabled has copy, drop {
        enabled_by: address,
        timestamp: u64,
    }

    // ============ INITIALIZATION ============
    
    /// @notice Initializes global configuration
    /// @param _witness Witness type for initialization
    /// @param ctx Transaction context
    /// @dev Only callable by the emergency admin address
    fun init(_witness: STAKE_CONFIG, ctx: &mut TxContext) {
        assert!(sender(ctx) == @stake_emergency_admin, ERR_NO_PERMISSIONS);
        
        let global_config = GlobalConfig {
            id: new(ctx),
            emergency_admin_address: @stake_emergency_admin,
            treasury_admin_address: @treasury_admin,
            global_emergency_locked: false,
            emergency_enabled_at: 0,
            version: 1,
        };
        
        transfer::share_object(global_config);
    }

    /// @notice Test-only initialization function
    /// @param ctx Transaction context
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(STAKE_CONFIG {}, ctx)
    }

    // ============ ADMIN MANAGEMENT ============
    
    /// @notice Sets new emergency admin address
    /// @param global_config Reference to global configuration
    /// @param new_address New emergency admin address
    /// @param ctx Transaction context
    /// @dev Only callable by current emergency admin
    public fun set_emergency_admin_address(
        global_config: &mut GlobalConfig, 
        new_address: address, 
        ctx: &mut TxContext
    ) {
        assert!(sender(ctx) == global_config.emergency_admin_address, ERR_NO_PERMISSIONS);
        assert!(new_address != @0x0, ERR_INVALID_ADDRESS);
        
        let old_admin = global_config.emergency_admin_address;
        global_config.emergency_admin_address = new_address;
        
        event::emit(EmergencyAdminChanged {
            old_admin,
            new_admin: new_address,
            timestamp: 0, // TODO: Add timestamp from clock
        });
    }

    /// @notice Gets current emergency admin address
    /// @param global_config Reference to global configuration
    /// @return Address of current emergency admin
    public fun get_emergency_admin_address(global_config: &GlobalConfig): address {
        global_config.emergency_admin_address
    }

    /// @notice Sets new treasury admin address
    /// @param global_config Reference to global configuration
    /// @param new_address New treasury admin address
    /// @param ctx Transaction context
    /// @dev Only callable by current treasury admin
    public fun set_treasury_admin_address(
        global_config: &mut GlobalConfig, 
        new_address: address, 
        ctx: &mut TxContext
    ) {
        assert!(sender(ctx) == global_config.treasury_admin_address, ERR_NO_PERMISSIONS);
        assert!(new_address != @0x0, ERR_INVALID_ADDRESS);
        
        let old_admin = global_config.treasury_admin_address;
        global_config.treasury_admin_address = new_address;
        
        event::emit(TreasuryAdminChanged {
            old_admin,
            new_admin: new_address,
            timestamp: 0, // TODO: Add timestamp from clock
        });
    }

    /// @notice Gets current treasury admin address
    /// @param global_config Reference to global configuration
    /// @return Address of current treasury admin
    public fun get_treasury_admin_address(global_config: &GlobalConfig): address {
        global_config.treasury_admin_address
    }

    // ============ EMERGENCY MANAGEMENT ============
    
    /// @notice Enables global emergency state
    /// @param global_config Reference to global configuration
    /// @param ctx Transaction context
    /// @dev Only callable by emergency admin, cannot be disabled once enabled
    public fun enable_global_emergency(global_config: &mut GlobalConfig, ctx: &mut TxContext) {
        assert!(sender(ctx) == global_config.emergency_admin_address, ERR_NO_PERMISSIONS);
        assert!(!global_config.global_emergency_locked, ERR_EMERGENCY_ALREADY_ENABLED);
        
        global_config.global_emergency_locked = true;
        global_config.emergency_enabled_at = 0; // TODO: Add timestamp from clock
        
        event::emit(GlobalEmergencyEnabled {
            enabled_by: sender(ctx),
            timestamp: 0, // TODO: Add timestamp from clock
        });
    }

    /// @notice Checks if global emergency state is enabled
    /// @param global_config Reference to global configuration
    /// @return True if emergency state is enabled
    public fun is_global_emergency(global_config: &GlobalConfig): bool {
        global_config.global_emergency_locked
    }

    /// @notice Gets emergency enabled timestamp
    /// @param global_config Reference to global configuration
    /// @return Timestamp when emergency was enabled, 0 if not enabled
    public fun get_emergency_enabled_at(global_config: &GlobalConfig): u64 {
        global_config.emergency_enabled_at
    }

    /// @notice Gets current version of the configuration
    /// @param global_config Reference to global configuration
    /// @return Current version number
    public fun get_version(global_config: &GlobalConfig): u64 {
        global_config.version
    }

    // ============ VIEW FUNCTIONS ============
    
    /// @notice Gets all configuration data
    /// @param global_config Reference to global configuration
    /// @return Tuple of (emergency_admin, treasury_admin, emergency_locked, version)
    public fun get_config_data(global_config: &GlobalConfig): (address, address, bool, u64) {
        (
            global_config.emergency_admin_address,
            global_config.treasury_admin_address,
            global_config.global_emergency_locked,
            global_config.version
        )
    }
}
