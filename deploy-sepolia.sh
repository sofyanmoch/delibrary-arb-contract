#!/bin/bash

# Deploy to Arbitrum Sepolia Script

set -e

echo "========================================="
echo "Arbitrum Sepolia Deployment"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

# Check .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    echo "Please create .env file with PRIVATE_KEY"
    exit 1
fi

print_success ".env file found"

# Check balance
print_step "Step 1: Checking wallet balance..."
node check-balance.js

echo ""
read -p "Do you want to proceed with deployment? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Clean build
print_step "Step 2: Cleaning previous build..."
rm -rf build/
print_success "Build cleaned"

# Compile contracts
print_step "Step 3: Compiling contracts..."
npx truffle compile

if [ $? -eq 0 ]; then
    print_success "Contracts compiled successfully"
else
    print_error "Compilation failed"
    exit 1
fi

# Deploy to Arbitrum Sepolia
print_step "Step 4: Deploying to Arbitrum Sepolia..."
echo ""
echo "⚠️  This will deploy to TESTNET (Arbitrum Sepolia)"
echo "Network: Arbitrum Sepolia (Chain ID: 421614)"
echo ""

npx truffle migrate --network arbitrumSepolia

if [ $? -eq 0 ]; then
    echo ""
    print_success "✨ Deployment completed successfully!"
    echo ""

    # Save deployment info
    if [ -f "deployment-info.json" ]; then
        cp deployment-info.json deployment-sepolia.json
        print_success "Deployment info saved to deployment-sepolia.json"
    fi

    echo ""
    echo "========================================="
    echo "Next Steps:"
    echo "========================================="
    echo "1. Check deployment-sepolia.json for contract addresses"
    echo "2. Verify contracts on Arbiscan:"
    echo "   https://sepolia.arbiscan.io/"
    echo "3. Update frontend configuration"
    echo "4. Update backend .env with new contract address"
    echo ""
else
    print_error "Deployment failed"
    exit 1
fi
