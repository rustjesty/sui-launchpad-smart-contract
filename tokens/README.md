# 🪙 SeaPad Token Module

[![SUI](https://img.shields.io/badge/SUI-Mainnet-blue.svg)](https://sui.io/)
[![Move](https://img.shields.io/badge/Move-Language-orange.svg)](https://move-language.github.io/move/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Token Creation and Management System for SUI Blockchain**

A comprehensive, production-ready token system that provides flexible token creation, minting, burning, and supply management for the SUI blockchain ecosystem.

## 🌟 Key Features

### 🪙 **SeaPad Token (SPT)**
- **Ecosystem token** for SeaPad launchpad platform
- **Governance capabilities** for platform decisions
- **Reward distribution** for staking and participation
- **9 decimal precision** for high accuracy
- **Maximum supply cap** of 1 billion tokens

### 💰 **USDT Test Token**
- **Test implementation** of USDT for development
- **6 decimal precision** matching real USDT
- **Large supply cap** for testing scenarios
- **Standard USDT interface** compatibility
- **Development and testing** purposes only

### 🔧 **Advanced Token Management**
- **Flexible minting** with supply controls
- **Secure burning** mechanisms
- **Supply management** functions
- **Treasury cap** administration
- **Event emission** for transparency

### 🛡️ **Security & Compliance**
- **Access control** for all operations
- **Supply validation** and overflow protection
- **Input validation** on all functions
- **Audit-ready** code structure
- **Emergency controls** for critical operations

## 🏗️ Architecture

```
tokens/
├── 📁 sources/
│   ├── spt.move           # SeaPad Token implementation
│   └── usdt_test.move     # USDT Test Token implementation
├── 📁 audit.202305/       # Audit reports and documentation
├── Move.toml              # Module configuration and dependencies
├── cmd.sh                 # Deployment and interaction commands
└── README.md              # This documentation
```

## 🚀 Quick Start

### Prerequisites
- [SUI CLI](https://docs.sui.io/build/install) installed
- SUI wallet with testnet/mainnet tokens
- Basic knowledge of Move language

### Installation

```bash
# Navigate to tokens module
cd tokens

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

### Creating SeaPad Token (SPT)

```move
// Initialize SPT token
let spt_witness = SPT {};
spt::init(spt_witness, ctx);

// Get treasury cap (transferred to sender during init)
let treasury_cap = get_treasury_cap_for_testing(ctx);

// Mint tokens to specific address
spt::mint_to(&mut treasury_cap, @alice, 1000000000, ctx); // 1 SPT with 9 decimals

// Increase supply (mint to sender)
spt::increase_supply(&mut treasury_cap, 500000000, ctx); // 0.5 SPT
```

### Creating USDT Test Token

```move
// Initialize USDT test token
let usdt_witness = USDT_TEST {};
usdt_test::init(usdt_witness, ctx);

// Get treasury cap
let usdt_treasury_cap = get_treasury_cap_for_testing(ctx);

// Mint USDT tokens
usdt_test::mint_to(&mut usdt_treasury_cap, @bob, 1000000, ctx); // 1 USDT with 6 decimals

// Increase supply
usdt_test::increase_supply(&mut usdt_treasury_cap, 500000, ctx); // 0.5 USDT
```

### Burning Tokens

```move
// Burn tokens from collection
let coins_to_burn = vector::empty<Coin<SPT>>();
vector::push_back(&mut coins_to_burn, coin::mint_for_testing<SPT>(100000000, ctx));

spt::burn(&mut treasury_cap, coins_to_burn, 100000000, ctx);

// Decrease supply
let coins_to_decrease = vector::empty<Coin<USDT_TEST>>();
vector::push_back(&mut coins_to_decrease, coin::mint_for_testing<USDT_TEST>(500000, ctx));

usdt_test::decrease_supply(&mut usdt_treasury_cap, coins_to_decrease, 500000, ctx);
```

### Treasury Management

```move
// Burn treasury cap to permanently disable minting
spt::burn_treasury_cap(treasury_cap, ctx);
```

## 🔧 Configuration

### Token Parameters

#### SeaPad Token (SPT)
- **Symbol**: SPT
- **Name**: SeaPad Token
- **Decimals**: 9
- **Max Supply**: 1,000,000,000 SPT
- **Description**: SeaPad launchpad foundation token for ecosystem governance and rewards

#### USDT Test Token
- **Symbol**: USDT
- **Name**: Tether USD Test
- **Decimals**: 6
- **Max Supply**: 1,000,000,000,000 USDT
- **Description**: Test USDT token for SeaPad development and testing purposes

### Access Controls
- **Treasury Cap Owner**: Can mint, burn, and manage supply
- **Token Holders**: Can transfer and use tokens
- **No Public Minting**: All minting requires treasury cap

## 🛡️ Security Features

### Access Control
- **Treasury cap ownership** required for minting
- **Input validation** on all public functions
- **Supply cap enforcement** to prevent inflation
- **Zero amount protection** for minting/burning

### Supply Management
- **Maximum supply limits** for both tokens
- **Supply validation** before minting operations
- **Safe burning** mechanisms with event emission
- **Treasury cap burning** for permanent supply control

### Mathematical Safety
- **Overflow protection** in all calculations
- **Precision handling** for decimal operations
- **Supply tracking** with accurate accounting
- **Event emission** for audit trails

## 🧪 Testing

### Running Tests

```bash
# Run all tests
sui move test

# Run specific test module
sui move test --filter spt_tests

# Run with coverage
sui move test --coverage
```

### Test Coverage
- ✅ **Unit tests** for all core functions
- ✅ **Minting and burning** operations
- ✅ **Supply management** functions
- ✅ **Error handling** scenarios
- ✅ **Access control** validation

## 📊 Performance & Gas Optimization

### Optimizations
- **Efficient data structures** for token operations
- **Minimal storage costs** with optimized structs
- **Batch operations** where possible
- **Gas estimation** tools included

### Gas Costs
- **Token initialization**: ~50,000 gas
- **Minting**: ~30,000 gas
- **Burning**: ~25,000 gas
- **Supply management**: ~35,000 gas

## 🔍 API Reference

### SeaPad Token (SPT)

#### Core Functions
- `init()` - Initialize SPT token
- `mint_to()` - Mint tokens to specific address
- `increase_supply()` - Increase supply by minting to sender
- `burn()` - Burn tokens from collection
- `decrease_supply()` - Decrease supply by burning
- `burn_treasury_cap()` - Permanently disable minting

#### View Functions
- `get_token_info()` - Get token metadata
- `get_max_supply()` - Get maximum supply cap

### USDT Test Token

#### Core Functions
- `init()` - Initialize USDT test token
- `mint_to()` - Mint tokens to specific address
- `increase_supply()` - Increase supply by minting to sender
- `burn()` - Burn tokens from collection
- `decrease_supply()` - Decrease supply by burning

#### View Functions
- `get_token_info()` - Get token metadata
- `get_max_supply()` - Get maximum supply cap

## 🚨 Emergency Procedures

### Treasury Cap Management
1. **Treasury cap owner** can mint tokens within supply limits
2. **Supply validation** prevents exceeding maximum supply
3. **Treasury cap burning** permanently disables minting
4. **No recovery** possible after treasury cap is burned

### Supply Controls
1. **Maximum supply** enforced on all minting operations
2. **Supply decrease** functions for deflationary scenarios
3. **Event emission** for all supply changes
4. **Audit trail** maintained for all operations

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
- Inspired by successful token standards
- Community feedback and contributions
- Security auditors and reviewers

---

**⭐ Star this repository if you find it helpful!**

**🔗 Built with ❤️ for the SUI ecosystem**
