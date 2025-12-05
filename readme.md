# Running BookLending Smart Contract on Localhost

This guide will help you deploy and run the BookLending smart contract on your local machine using Ganache.

## Prerequisites

Before you begin, make sure you have installed:
- Node.js (v14 or higher)
- npm or yarn
- Ganache (for local blockchain)

## Installation Steps

### 1. Install Ganache

Choose one of the following options:

#### Option A: Install Ganache CLI (Recommended for command line)
```bash
npm install -g ganache
```

#### Option B: Install Ganache GUI
Download from: https://trufflesuite.com/ganache/

### 2. Install Truffle Dependencies

```bash
cd truffle
npm install
```

## Running the Smart Contract

### Method 1: Quick Start Script (Easiest)

We've created a quick start script that automates everything:

```bash
cd truffle
chmod +x quick-start.sh
./quick-start.sh
```

This script will:
1. Start Ganache on port 8545
2. Compile the contracts
3. Deploy to localhost
4. Save deployment addresses
5. Display all necessary information

### Method 2: Manual Step-by-Step

#### Step 1: Start Ganache

**Using Ganache CLI:**
```bash
ganache --port 8545 --networkId 5777 --deterministic
```

**Using Ganache GUI:**
1. Open Ganache application
2. Click "Quickstart Ethereum"
3. Make sure it's running on port 8545

Keep this terminal window open.

#### Step 2: Compile the Contracts

Open a new terminal window and navigate to the truffle directory:

```bash
cd truffle
npx truffle compile
```

You should see output indicating successful compilation.

#### Step 3: Deploy the Contracts

Deploy to your local Ganache network:

```bash
npx truffle migrate --network development
```

**Expected Output:**
```
========================================
Starting BookLending Platform Deployment
========================================

Network: development
Deployer: 0x...

📚 Step 1: Deploying BookToken...
✅ BookToken deployed at: 0x...

📖 Step 2: Deploying BookLending...
   Using BookToken address: 0x...
✅ BookLending deployed at: 0x...

🔐 Step 3: Transferring BookToken ownership to BookLending...
✅ Ownership transferred successfully

========================================
Deployment Summary
========================================
BookToken Address:     0x...
BookLending Address:   0x...
========================================

📝 Deployment info saved to: deployment-info.json
✨ Deployment completed successfully!
```

#### Step 4: Save the Contract Addresses

The deployment automatically creates a `deployment-info.json` file with all contract addresses.

View the deployment info:
```bash
cat deployment-info.json
```

## Redeploying Contracts

If you need to redeploy (after making changes):

```bash
# Clean build
rm -rf build/

# Recompile
npx truffle compile

# Redeploy with reset
npx truffle migrate --network development --reset
```

## Useful Commands

```bash
# Start Ganache
ganache --port 8545

# Compile contracts
npx truffle compile

# Deploy contracts
npx truffle migrate --network development

# Redeploy (reset)
npx truffle migrate --network development --reset

# Open Truffle console
npx truffle console --network development

# Run tests (if you have test files)
npx truffle test --network development
```

## Network Information

When using Ganache with `--deterministic` flag:

- **Network ID**: 1337 (or custom)
- **Chain ID**: 1337
- **Port**: 8545
- **Host**: 127.0.0.1
- **Default Accounts**: 10 accounts with 100 ETH each

## Additional Resources

- [Truffle Documentation](https://trufflesuite.com/docs/truffle/)
- [Ganache Documentation](https://trufflesuite.com/docs/ganache/)
- [Web3.js Documentation](https://web3js.readthedocs.io/)

## Support

If you encounter any issues:
1. Check this guide's troubleshooting section
2. Review Ganache logs
3. Check Truffle console output
4. Verify all prerequisites are installed
