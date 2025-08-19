# 🔒 SeaPad Staking Module

[![SUI](https://img.shields.io/badge/SUI-Mainnet-blue.svg)](https://sui.io/)
[![Move](https://img.shields.io/badge/Move-Language-orange.svg)](https://move-language.github.io/move/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Advanced Staking and Liquidity Management System for SUI Blockchain**

A comprehensive, production-ready staking system that provides flexible staking pools, reward distribution, and emergency controls for the SUI blockchain ecosystem.

## 🌟 Key Features

### 🏊‍♂️ **Flexible Staking Pools**
- **Multi-token support** for any SUI coin pair
- **Configurable lock periods** with customizable unstaking delays
- **Maximum stake limits** per user to prevent whale dominance
- **Dynamic reward rates** based on pool duration and total rewards

### 💰 **Advanced Reward System**
- **Real-time reward calculation** using accumulated reward per share
- **Automatic reward distribution** proportional to stake amount
- **Compound interest support** for maximizing returns
- **Flexible reward token types** (any SUI coin)

### 🔒 **Security & Emergency Controls**
- **Global emergency state** that can disable all operations
- **Pool-level emergency controls** for individual pool management
- **Emergency unstaking** to protect user funds
- **Role-based access control** for admin operations

### 📊 **Transparent & Auditable**
- **On-chain event emission** for all operations
- **Real-time pool statistics** and user information
- **Comprehensive audit trail** for all transactions
- **Gas-optimized operations** for cost efficiency

## 🏗️ Architecture

```
stake/
├── 📁 sources/
│   ├── stake.move           # Core staking logic and pool management
│   ├── stake_config.move    # Global configuration and emergency controls
│   ├── stake_entries.move   # User-facing entry point functions
│   └── 📁 libs/
│       └── math128.move     # Mathematical utilities for calculations
├── 📁 tests/
│   ├── stake_tests.move     # Comprehensive unit tests
│   └── launchpad_test.move  # Integration tests
└── Move.toml               # Module configuration and dependencies
```

## 🚀 Quick Start

### Prerequisites
- [SUI CLI](https://docs.sui.io/build/install) installed
- SUI wallet with testnet/mainnet tokens
- Basic knowledge of Move language

### Installation

```bash
# Navigate to stake module
cd stake

# Build the module
sui move build

# Run tests
sui move test
```

### Deploy to Testnet

```bash
# Deploy to SUI testnet
sui client publish --gas-budget 100000000 --network testnet
```

## 📖 Usage Examples

### Creating a Staking Pool

```move
// Initialize global configuration first
let global_config = stake_config::init(STAKE_CONFIG {}, ctx);

// Register a new staking pool
let rewards = coin::mint_for_testing<USDT>(1000000, ctx); // 1M USDT rewards
let pool = stake_entries::register_pool<SUI, USDT>(
    rewards,
    86400 * 30, // 30 days duration
    &global_config,
    9,  // SUI decimals
    6,  // USDT decimals
    &clock,
    86400 * 7,  // 7 days lock period
    1000000,    // Max 1M SUI per user
    ctx
);
```

### Staking Tokens

```move
// Stake SUI tokens to earn USDT rewards
let staking_coins = coin::mint_for_testing<SUI>(1000, ctx);
stake_entries::stake<SUI, USDT>(
    &mut pool,
    staking_coins,
    &global_config,
    &clock,
    ctx
);
```

### Harvesting Rewards

```move
// Harvest accumulated rewards
stake_entries::harvest<SUI, USDT>(
    &mut pool,
    &global_config,
    &clock,
    ctx
);
```

### Unstaking Tokens

```move
// Unstake tokens (after lock period)
stake_entries::unstake<SUI, USDT>(
    &mut pool,
    500, // Amount to unstake
    &global_config,
    &clock,
    ctx
);
```

## 🔧 Configuration

### Pool Parameters
- **Duration**: Pool lifetime in seconds
- **Reward Rate**: Rewards per second (calculated from total rewards / duration)
- **Lock Period**: Minimum time tokens must be staked before unstaking
- **Max Stake**: Maximum amount any single user can stake
- **Decimals**: Token decimal places for accurate calculations

### Admin Controls
- **Emergency Admin**: Can enable global emergency state
- **Treasury Admin**: Can withdraw rewards to treasury
- **Pool Emergency**: Individual pool emergency controls

## 🛡️ Security Features

### Access Control
- **Role-based permissions** for admin operations
- **Emergency admin** with global control capabilities
- **Treasury admin** for reward management
- **Input validation** on all public functions

### Emergency Procedures
- **Global emergency state** disables all operations except emergency unstaking
- **Pool-level emergency** for individual pool protection
- **Emergency unstaking** allows users to withdraw funds immediately
- **Immutable emergency state** once enabled

### Mathematical Safety
- **Overflow protection** in all calculations
- **Precision handling** for decimal operations
- **Safe arithmetic** operations with bounds checking
- **Accumulated reward scaling** to prevent precision loss

## 🧪 Testing

### Running Tests

```bash
# Run all tests
sui move test

# Run specific test module
sui move test --filter stake_tests

# Run with coverage
sui move test --coverage
```

### Test Coverage
- ✅ **Unit tests** for all core functions
- ✅ **Integration tests** for cross-module interactions
- ✅ **Edge case testing** for security scenarios
- ✅ **Mathematical accuracy** testing
- ✅ **Emergency scenario** testing

## 📊 Performance & Gas Optimization

### Optimizations
- **Efficient data structures** using SUI tables
- **Batch operations** where possible
- **Minimal storage costs** with optimized structs
- **Gas estimation** tools included

### Gas Costs
- **Pool registration**: ~50,000 gas
- **Staking**: ~30,000 gas
- **Unstaking**: ~40,000 gas
- **Harvesting**: ~35,000 gas

## 🔍 API Reference

### Core Functions

#### Pool Management
- `register_pool<S, R>()` - Create new staking pool
- `deposit_reward_coins<S, R>()` - Add more rewards to pool

#### Staking Operations
- `stake<S, R>()` - Stake tokens to earn rewards
- `unstake<S, R>()` - Unstake tokens (after lock period)
- `harvest<S, R>()` - Collect accumulated rewards

#### Emergency Operations
- `enable_emergency<S, R>()` - Enable pool emergency state
- `emergency_unstake<S, R>()` - Emergency token withdrawal
- `enable_global_emergency()` - Enable global emergency

#### Admin Functions
- `set_emergency_admin_address()` - Change emergency admin
- `set_treasury_admin_address()` - Change treasury admin
- `withdraw_reward_to_treasury<S, R>()` - Treasury reward withdrawal

### View Functions
- `get_pool_info<S, R>()` - Get pool statistics
- `get_user_stake_info<S, R>()` - Get user stake details

## 🚨 Emergency Procedures

### Global Emergency
1. **Emergency admin** calls `enable_global_emergency()`
2. **All operations** except emergency unstaking are disabled
3. **Users can** call `emergency_unstake()` to withdraw funds
4. **State is permanent** and cannot be disabled

### Pool Emergency
1. **Emergency admin** calls `enable_emergency()` on specific pool
2. **Pool operations** are disabled for that pool only
3. **Users can** emergency unstake from affected pool
4. **Other pools** continue normal operation

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](../CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for new functionality
4. Ensure all tests pass (`sui move test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🆘 Support & Community

- **Documentation**: [Wiki](https://github.com/rustjesty/sui-launchpad-smart-contract/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/rustjesty/sui-launchpad-smart-contract/discussions)
- **Issues**: [GitHub Issues](https://github.com/rustjesty/sui-launchpad-smart-contract/issues)
- **Telegram**: [@soljesty](https://t.me/soljesty)

## 🙏 Acknowledgments

- Built on the [SUI blockchain](https://sui.io/)
- Inspired by successful DeFi staking protocols
- Community feedback and contributions
- Security auditors and reviewers

---

**⭐ Star this repository if you find it helpful!**

**🔗 Built with ❤️ for the SUI ecosystem**
