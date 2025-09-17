# Hexmora ✨

> *"Hex" (spell) + "Mora" (Latin for delay or pause) - Symbolizing carefully crafted magic*

A gamified smart contract toolkit where developers conjure modular "hexes" — reusable Clarity contract components — and combine them to build complex decentralized finance (DeFi) instruments and dApps.

## 🎮 Overview

Hexmora transforms smart contract development into an engaging, game-like experience. Developers craft programmable "hexes" (contract components) that can be combined to automate governance, tokenomics, and financial flows with deliberate design and controlled execution.

## 🔮 Features

- **Modular Hex System**: Create reusable contract components with defined inputs, outputs, and logic
- **Mana-Based Economy**: Resource management system for hex creation and activation
- **Experience Points**: Gamified progression system rewarding active developers
- **Grimoire Management**: Personal spell book tracking user's hexes and progress  
- **Power Level Scaling**: Dynamic cost calculation based on hex complexity
- **Ownership & Sharing**: Creators maintain control while allowing community usage
- **Usage Analytics**: Track hex popularity and effectiveness
- **🆕 Hex Marketplace**: Buy and sell hexes with STX tokens for decentralized component trading
- **Dynamic Pricing**: Update hex prices and manage listings with full ownership controls
- **Secure Transactions**: Automated STX transfers with experience rewards for marketplace activity

## 🛠️ Technical Architecture

### Core Components

- **Hex Registry**: Central storage for all crafted hexes
- **Component System**: Modular architecture for hex logic and parameters
- **User Grimoire**: Personal progress and resource tracking
- **Ownership Management**: Decentralized hex ownership and permissions
- **Marketplace Engine**: STX-based trading system with listing management

### Key Functions

- `craft-hex`: Create new modular contract components
- `activate-hex`: Execute hex functionality with target parameters  
- `recharge-mana`: Restore resources for continued development
- `toggle-hex-status`: Enable/disable hex availability
- `list-hex-for-sale`: List owned hexes for STX trading
- `buy-hex`: Purchase hexes from marketplace with automatic ownership transfer
- `update-hex-price`: Modify listing prices for active marketplace entries
- `remove-hex-listing`: Remove hexes from marketplace

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testnet interaction with STX balance
- Basic knowledge of Clarity smart contracts

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hexmora.git
   cd hexmora
   ```

2. Initialize Clarinet project:
   ```bash
   clarinet integrate
   ```

3. Run tests:
   ```bash
   clarinet test
   ```

4. Deploy to testnet:
   ```bash
   clarinet deploy --testnet
   ```

## 📖 Usage Examples

### Crafting a Basic Hex

```clarity
(craft-hex 
  "token-mint"
  "Automated token minting with supply controls"
  "defi"
  u5
  (list "amount" "recipient" "max-supply")
  "success-boolean"
  0x1234567890abcdef)
```

### Activating a Hex

```clarity
(activate-hex u1 (list u1000 u2000))
```

### Marketplace Operations

```clarity
;; List hex for sale
(list-hex-for-sale u1 u500000) ;; 0.5 STX

;; Buy a hex
(buy-hex u1)

;; Update price
(update-hex-price u1 u750000) ;; 0.75 STX

;; Remove from marketplace
(remove-hex-listing u1)
```

## 🧪 Testing

Comprehensive test suite covers:
- Hex creation and validation
- Mana economy mechanics  
- Ownership and permissions
- Marketplace transactions and edge cases
- STX transfer security
- Gas optimization scenarios

Run tests with:
```bash
clarinet test
```

## 📊 Smart Contract Security

- **Parameter Validation**: All inputs rigorously validated
- **Access Controls**: Owner-only functions properly secured
- **Error Handling**: Comprehensive error codes and messages
- **Resource Management**: Mana system prevents spam and abuse
- **State Consistency**: Atomic operations ensure data integrity
- **Marketplace Security**: Protected against double-spending, unauthorized sales, and ownership conflicts
- **STX Transfer Safety**: Validated balance checks before transfers

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-hex`)
3. Commit changes (`git commit -m 'Add amazing hex functionality'`)
4. Push branch (`git push origin feature/amazing-hex`)
5. Open Pull Request

## 🌟 Future Roadmap

### Phase 1: Core Enhancement (Q2 2025) ✅
- **✅ Hex Marketplace**: Trading system for buying/selling hexes with STX tokens
- **Combo System**: Chain multiple hexes together for complex automated workflows
- **Guild Mechanics**: Developer teams sharing hexes, resources, and collaborative crafting

### Phase 2: Advanced Features (Q3 2025)
- **Hex Templates**: Pre-built patterns for common DeFi operations and governance structures
- **Oracle Integration**: Real-world data feeds enabling dynamic hex parameters and triggers
- **Achievement System**: Badges and rewards for hex creation milestones and community contributions

### Phase 3: Ecosystem Expansion (Q4 2025)
- **Governance Module**: Community voting on hex standards, upgrades, and protocol changes
- **Cross-Chain Bridges**: Hex compatibility with other blockchain networks and protocols
- **AI-Assisted Crafting**: Smart suggestions for optimal hex combinations and performance optimization

### Phase 4: Analytics & Intelligence (Q1 2026)
- **Hex Analytics Dashboard**: Visual insights into usage patterns, performance metrics, and ROI analysis

*Built with ❤️ for the Stacks ecosystem*