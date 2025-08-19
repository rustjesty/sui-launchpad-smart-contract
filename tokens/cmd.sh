#!/bin/bash

# SeaPad Token Module Command Script
# This script provides commands for deploying and interacting with token modules

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_NETWORK="testnet"
DEFAULT_GAS_BUDGET="100000000"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "SeaPad Token Module Command Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build                    Build the token modules"
    echo "  test                     Run tests"
    echo "  deploy [NETWORK]         Deploy to specified network (default: testnet)"
    echo "  init-spt                 Initialize SPT token"
    echo "  init-usdt                Initialize USDT test token"
    echo "  mint-spt [TO] [AMOUNT]   Mint SPT tokens to address"
    echo "  mint-usdt [TO] [AMOUNT]  Mint USDT tokens to address"
    echo "  burn-spt [AMOUNT]        Burn SPT tokens"
    echo "  burn-usdt [AMOUNT]       Burn USDT tokens"
    echo "  help                     Show this help message"
    echo ""
    echo "Networks:"
    echo "  testnet                  SUI testnet"
    echo "  mainnet                  SUI mainnet"
    echo "  devnet                   SUI devnet"
    echo ""
    echo "Examples:"
    echo "  $0 build                 # Build modules"
    echo "  $0 deploy testnet        # Deploy to testnet"
    echo "  $0 init-spt              # Initialize SPT token"
    echo "  $0 mint-spt @alice 1000  # Mint 1000 SPT to alice"
    echo ""
    echo "Environment Variables:"
    echo "  PACKAGE_ID               Package ID after deployment"
    echo "  SPT_TREASURY_CAP         SPT treasury capability ID"
    echo "  USDT_TREASURY_CAP        USDT treasury capability ID"
    echo "  UPGRADE_CAP              Upgrade capability ID"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if sui CLI is installed
    if ! command -v sui &> /dev/null; then
        print_error "SUI CLI is not installed. Please install it first:"
        echo "  https://docs.sui.io/build/install"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "Move.toml" ]]; then
        print_error "Move.toml not found. Please run this script from the tokens module directory."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build modules
build_modules() {
    print_status "Building token modules..."
    
    if sui move build; then
        print_success "Modules built successfully"
    else
        print_error "Failed to build modules"
        exit 1
    fi
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    
    if sui move test; then
        print_success "All tests passed"
    else
        print_error "Tests failed"
        exit 1
    fi
}

# Function to deploy modules
deploy_modules() {
    local network=${1:-$DEFAULT_NETWORK}
    local gas_budget=${2:-$DEFAULT_GAS_BUDGET}
    
    print_status "Deploying to $network network with gas budget $gas_budget..."
    
    # Get current active address
    local active_address=$(sui client active-address)
    print_status "Deploying from address: $active_address"
    
    # Deploy the modules
    local deploy_output=$(sui client publish --gas-budget "$gas_budget" --network "$network" --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "Modules deployed successfully!"
        
        # Extract package ID from output
        local package_id=$(echo "$deploy_output" | grep -o '"packageId":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$package_id" ]]; then
            print_success "Package ID: $package_id"
            echo "export PACKAGE_ID=$package_id" > .env
        fi
        
        # Extract transaction digest
        local tx_digest=$(echo "$deploy_output" | grep -o '"digest":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$tx_digest" ]]; then
            print_success "Transaction Digest: $tx_digest"
            echo "export TX_DIGEST=$tx_digest" >> .env
        fi
        
        # Show transaction details
        print_status "Transaction details:"
        sui client tx-block --digest "$tx_digest" --network "$network"
        
    else
        print_error "Deployment failed:"
        echo "$deploy_output"
        exit 1
    fi
}

# Function to initialize SPT token
init_spt() {
    print_status "Initializing SPT token..."
    
    if [[ -z "$PACKAGE_ID" ]]; then
        print_error "PACKAGE_ID not set. Please deploy first or set PACKAGE_ID environment variable."
        exit 1
    fi
    
    local output=$(sui client call \
        --package "$PACKAGE_ID" \
        --module spt \
        --function init \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "SPT token initialized successfully!"
        
        # Extract treasury cap ID
        local treasury_cap=$(echo "$output" | grep -o '"objectId":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [[ -n "$treasury_cap" ]]; then
            print_success "SPT Treasury Cap ID: $treasury_cap"
            echo "export SPT_TREASURY_CAP=$treasury_cap" >> .env
        fi
        
    else
        print_error "Failed to initialize SPT token:"
        echo "$output"
        exit 1
    fi
}

# Function to initialize USDT test token
init_usdt() {
    print_status "Initializing USDT test token..."
    
    if [[ -z "$PACKAGE_ID" ]]; then
        print_error "PACKAGE_ID not set. Please deploy first or set PACKAGE_ID environment variable."
        exit 1
    fi
    
    local output=$(sui client call \
        --package "$PACKAGE_ID" \
        --module usdt_test \
        --function init \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "USDT test token initialized successfully!"
        
        # Extract treasury cap ID
        local treasury_cap=$(echo "$output" | grep -o '"objectId":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [[ -n "$treasury_cap" ]]; then
            print_success "USDT Treasury Cap ID: $treasury_cap"
            echo "export USDT_TREASURY_CAP=$treasury_cap" >> .env
        fi
        
    else
        print_error "Failed to initialize USDT test token:"
        echo "$output"
        exit 1
    fi
}

# Function to mint SPT tokens
mint_spt() {
    local to_address=$1
    local amount=$2
    
    if [[ -z "$to_address" || -z "$amount" ]]; then
        print_error "Usage: $0 mint-spt <TO_ADDRESS> <AMOUNT>"
        exit 1
    fi
    
    if [[ -z "$PACKAGE_ID" || -z "$SPT_TREASURY_CAP" ]]; then
        print_error "PACKAGE_ID or SPT_TREASURY_CAP not set. Please initialize first."
        exit 1
    fi
    
    print_status "Minting $amount SPT tokens to $to_address..."
    
    local output=$(sui client call \
        --package "$PACKAGE_ID" \
        --module spt \
        --function mint_to \
        --args "$SPT_TREASURY_CAP" "$to_address" "$amount" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "SPT tokens minted successfully!"
    else
        print_error "Failed to mint SPT tokens:"
        echo "$output"
        exit 1
    fi
}

# Function to mint USDT tokens
mint_usdt() {
    local to_address=$1
    local amount=$2
    
    if [[ -z "$to_address" || -z "$amount" ]]; then
        print_error "Usage: $0 mint-usdt <TO_ADDRESS> <AMOUNT>"
        exit 1
    fi
    
    if [[ -z "$PACKAGE_ID" || -z "$USDT_TREASURY_CAP" ]]; then
        print_error "PACKAGE_ID or USDT_TREASURY_CAP not set. Please initialize first."
        exit 1
    fi
    
    print_status "Minting $amount USDT tokens to $to_address..."
    
    local output=$(sui client call \
        --package "$PACKAGE_ID" \
        --module usdt_test \
        --function mint_to \
        --args "$USDT_TREASURY_CAP" "$to_address" "$amount" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "USDT tokens minted successfully!"
    else
        print_error "Failed to mint USDT tokens:"
        echo "$output"
        exit 1
    fi
}

# Function to burn SPT tokens
burn_spt() {
    local amount=$1
    
    if [[ -z "$amount" ]]; then
        print_error "Usage: $0 burn-spt <AMOUNT>"
        exit 1
    fi
    
    if [[ -z "$PACKAGE_ID" || -z "$SPT_TREASURY_CAP" ]]; then
        print_error "PACKAGE_ID or SPT_TREASURY_CAP not set. Please initialize first."
        exit 1
    fi
    
    print_status "Burning $amount SPT tokens..."
    
    # Note: This is a simplified version. In practice, you'd need to provide actual coins
    print_warning "This is a simplified burn function. You need to provide actual coins to burn."
    
    local output=$(sui client call \
        --package "$PACKAGE_ID" \
        --module spt \
        --function burn \
        --args "$SPT_TREASURY_CAP" "[]" "$amount" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "SPT tokens burned successfully!"
    else
        print_error "Failed to burn SPT tokens:"
        echo "$output"
        exit 1
    fi
}

# Function to burn USDT tokens
burn_usdt() {
    local amount=$1
    
    if [[ -z "$amount" ]]; then
        print_error "Usage: $0 burn-usdt <AMOUNT>"
        exit 1
    fi
    
    if [[ -z "$PACKAGE_ID" || -z "$USDT_TREASURY_CAP" ]]; then
        print_error "PACKAGE_ID or USDT_TREASURY_CAP not set. Please initialize first."
        exit 1
    fi
    
    print_status "Burning $amount USDT tokens..."
    
    # Note: This is a simplified version. In practice, you'd need to provide actual coins
    print_warning "This is a simplified burn function. You need to provide actual coins to burn."
    
    local output=$(sui client call \
        --package "$PACKAGE_ID" \
        --module usdt_test \
        --function burn \
        --args "$USDT_TREASURY_CAP" "[]" "$amount" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "USDT tokens burned successfully!"
    else
        print_error "Failed to burn USDT tokens:"
        echo "$output"
        exit 1
    fi
}

# Function to load environment variables
load_env() {
    if [[ -f ".env" ]]; then
        print_status "Loading environment variables from .env file..."
        source .env
    fi
}

# Main execution
main() {
    # Load environment variables
    load_env
    
    # Check prerequisites
    check_prerequisites
    
    # Parse command
    case $1 in
        build)
            build_modules
            ;;
        test)
            run_tests
            ;;
        deploy)
            deploy_modules "$2" "$3"
            ;;
        init-spt)
            init_spt
            ;;
        init-usdt)
            init_usdt
            ;;
        mint-spt)
            mint_spt "$2" "$3"
            ;;
        mint-usdt)
            mint_usdt "$2" "$3"
            ;;
        burn-spt)
            burn_spt "$2"
            ;;
        burn-usdt)
            burn_usdt "$2"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
