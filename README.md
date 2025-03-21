# Thaler Protocol - Smart Contract Suite

## Overview
Thaler Protocol is a personal finance platform that helps you achieve your financial goals through smart, structured approaches. We're building tools that make it easier to save, invest, and manage your money effectively.

What we offer now:
- Create savings plans with clear timelines (3, 6, or 12 months)
- Set up automatic monthly deposits
- Save in ETH or other digital currencies
- Smart features to help you stay on track with your goals

We're just getting started! While we're launching with savings features, we have exciting plans to expand into more ways to help you manage and grow your money. Our goal is to make personal finance simpler, safer, and more effective for everyone.

Current Features:
- Create savings pools with fixed durations (3, 6, or 12 months)
- Make regular monthly deposits to build your savings
- Save in either ETH or other tokens
- Smart accountability system for maintaining financial discipline

The protocol is designed to be more than just a savings tool - it's a foundation for building better financial habits and achieving long-term financial goals. We're actively developing new features and integrations to make personal finance more accessible, secure, and effective.

## Features
- **Structured Savings Pools**: Create savings pools with predefined durations (3, 6, or 12 months)
- **Regular Deposit Schedules**: Monthly deposit intervals for consistent savings
- **Multi-Token Support**: Save in ETH or ERC20 tokens
- **Early Withdrawal with Accountability**: Access funds before maturity by making a donation (proven via ZK)
- **Donation System**: Built-in donation mechanism with configurable ratios
- **Flexible Deposit Options**: Support for both initial deposits and recurring deposits

## Understanding Early Withdrawals
The protocol encourages disciplined saving while recognizing that life sometimes requires flexibility. Here's how early withdrawals work:

1. **Normal Withdrawal**: Once your savings pool reaches its end date, you can withdraw all your funds without any additional steps.

2. **Early Withdrawal**: If you need to access your funds before the end date:
   - You'll need to make a donation to a charitable cause
   - The protocol verifies this donation using zero-knowledge proofs (ZK)
   - This creates a "cost" for breaking your savings goal, helping maintain financial discipline
   - The donation amount is proportional to your withdrawal amount

The ZK proof system ensures that:
- The donation was actually made
- The donation meets the minimum required amount
- The person withdrawing is the same person who made the donation

This mechanism helps balance flexibility with accountability, encouraging users to think twice before breaking their savings goals while still providing access when truly needed.

## Project Structure
```
ThalerContracts/
├── src/                    # Source contracts
│   └── ThalerSavingsPool.sol  # Main savings pool contract
├── test/                   # Test files
│   └── Unit/              # Unit tests
│       └── ThalerSavingsPoolTest.t.sol
├── script/                # Deployment and interaction scripts
├── lib/                   # External dependencies
├── thaler_circuits/       # ZK proof circuits
├── server.js             # JSON-RPC server for contract interaction
└── foundry.toml          # Foundry configuration
```

## Technical Details

### Core Components

#### ThalerSavingsPool Contract
- Implements savings pool creation and management
- Handles deposits and withdrawals
- Integrates with ZK proof verification
- Manages donation mechanisms
- Supports both ETH and ERC20 tokens

### Key Features
1. **Savings Pool Creation**
   - Choose from predefined durations (3, 6, or 12 months)
   - Set initial deposit amount
   - Configure recurring deposit amounts
   - Select token type (ETH or ERC20)

2. **Deposit Management**
   - Monthly deposit intervals
   - Support for both ETH and ERC20 tokens
   - Configurable deposit amounts
   - Early withdrawal via ZK proofs

3. **Security Features**
   - ZK proof verification for early withdrawals
   - Owner-only administrative functions
   - Comprehensive input validation
   - Custom error handling for gas optimization

## Setup and Installation

### Prerequisites
- Node.js (v14 or higher)
- Foundry
- Solidity ^0.8.24

### Installation
1. Clone the repository:
```bash
git clone <repository-url>
cd ThalerContracts
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

### Development
1. Run tests:
```bash
forge test
```

2. Deploy contracts:
```bash
forge script script/Deploy.s.sol
```

3. Start the JSON-RPC server:
```bash
node server.js
```

## Testing
The project includes comprehensive unit tests covering:
- Pool creation and management
- Deposit and withdrawal functionality
- ZK proof verification
- Donation mechanism
- Error cases and edge conditions

Run tests with:
```bash
forge test
```

## Security Considerations
- All contracts are thoroughly tested
- ZK proofs ensure secure early withdrawals
- Input validation and error handling
- Gas optimization through custom errors
- Owner-only administrative functions

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
MIT License

## Contact
For questions and support, please open an issue in the repository.
