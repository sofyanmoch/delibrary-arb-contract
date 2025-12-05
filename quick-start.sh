#!/bin/bash

# BookLending Quick Start Script
# This script automates the entire local deployment process

set -e  # Exit on error

echo "========================================="
echo "BookLending Quick Start"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if Ganache is installed
echo "Step 1: Checking prerequisites..."
if ! command -v ganache &> /dev/null; then
    print_error "Ganache is not installed"
    echo ""
    echo "Please install Ganache CLI:"
    echo "  npm install -g ganache"
    echo ""
    echo "Or download Ganache GUI from:"
    echo "  https://trufflesuite.com/ganache/"
    exit 1
fi
print_success "Ganache is installed"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    exit 1
fi
print_success "Node.js is installed ($(node --version))"
echo ""

# Install dependencies if needed
echo "Step 2: Installing dependencies..."
if [ ! -d "node_modules" ]; then
    print_info "Installing npm packages..."
    npm install
    print_success "Dependencies installed"
else
    print_success "Dependencies already installed"
fi
echo ""

# Check if Ganache is already running
echo "Step 3: Checking Ganache status..."
if lsof -i :8545 &> /dev/null; then
    print_info "Ganache is already running on port 8545"
    read -p "Do you want to kill it and restart? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Killing existing Ganache process..."
        lsof -ti :8545 | xargs kill -9 2>/dev/null || true
        sleep 2
        print_success "Existing Ganache stopped"
    else
        print_info "Using existing Ganache instance"
        GANACHE_RUNNING=true
    fi
fi

# Start Ganache if not running
if [ -z "$GANACHE_RUNNING" ]; then
    print_info "Starting Ganache..."
    ganache --port 8545 --networkId 5777 --deterministic > ganache.log 2>&1 &
    GANACHE_PID=$!
    sleep 3

    if ps -p $GANACHE_PID > /dev/null; then
        print_success "Ganache started (PID: $GANACHE_PID)"
        echo "  Network ID: 5777"
        echo "  Port: 8545"
        echo "  Host: 127.0.0.1"
        echo "  Logs: ganache.log"
    else
        print_error "Failed to start Ganache"
        echo "Check ganache.log for details"
        exit 1
    fi
fi
echo ""

# Clean previous build
echo "Step 4: Cleaning previous build..."
if [ -d "build" ]; then
    rm -rf build/
    print_success "Previous build cleaned"
else
    print_info "No previous build found"
fi
echo ""

# Compile contracts
echo "Step 5: Compiling contracts..."
npx truffle compile
if [ $? -eq 0 ]; then
    print_success "Contracts compiled successfully"
else
    print_error "Contract compilation failed"
    exit 1
fi
echo ""

# Deploy contracts
echo "Step 6: Deploying contracts to localhost..."
npx truffle migrate --network development --reset
if [ $? -eq 0 ]; then
    print_success "Contracts deployed successfully"
else
    print_error "Contract deployment failed"
    exit 1
fi
echo ""

# Display deployment information
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""

if [ -f "deployment-info.json" ]; then
    print_success "Deployment information saved to deployment-info.json"
    echo ""
    echo "Contract Addresses:"
    echo "-------------------"
    cat deployment-info.json | grep -E "bookToken|bookLending" | sed 's/^/  /'
    echo ""

    # Extract BookLending address
    BOOK_LENDING_ADDRESS=$(cat deployment-info.json | grep "bookLending" | cut -d'"' -f4)

    echo "Next Steps:"
    echo "-----------"
    echo "1. Configure the backend:"
    echo "   cd ../backend"
    echo "   cp .env.example .env"
    echo ""
    echo "2. Add this to backend/.env:"
    echo "   PORT=3000"
    echo "   RPC_URL=http://127.0.0.1:8545"
    echo "   CONTRACT_ADDRESS=$BOOK_LENDING_ADDRESS"
    echo "   NETWORK=development"
    echo ""
    echo "3. Start the backend server:"
    echo "   cd ../backend"
    echo "   npm install"
    echo "   npm start"
    echo ""
    echo "4. Test the API:"
    echo "   curl http://localhost:3000/health"
    echo "   curl http://localhost:3000/api/booklending/total-books"
    echo ""
fi

echo "========================================="
echo "Ganache Information:"
echo "========================================="
echo "Network ID:  5777"
echo "Port:        8545"
echo "Host:        127.0.0.1"
echo "Accounts:    10 (each with 100 ETH)"
echo ""
echo "To stop Ganache:"
if [ -n "$GANACHE_PID" ]; then
    echo "  kill $GANACHE_PID"
fi
echo "  or: lsof -ti :8545 | xargs kill -9"
echo ""

print_success "✨ All done! Your local blockchain is ready."
echo ""
