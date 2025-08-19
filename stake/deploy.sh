#!/bin/bash

# SeaPad Staking Module Deployment Script
# This script deploys the staking module to SUI network

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
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
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --network NETWORK    Network to deploy to (testnet, mainnet, devnet) [default: testnet]"
    echo "  -g, --gas-budget BUDGET  Gas budget for deployment [default: 100000000]"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Deploy to testnet with default gas budget"
    echo "  $0 -n mainnet            # Deploy to mainnet"
    echo "  $0 -g 200000000          # Deploy with 200M gas budget"
    echo "  $0 -n mainnet -g 150000000 # Deploy to mainnet with 150M gas budget"
}

# Function to validate network
validate_network() {
    local network=$1
    case $network in
        testnet|mainnet|devnet)
            return 0
            ;;
        *)
            print_error "Invalid network: $network"
            print_error "Valid networks: testnet, mainnet, devnet"
            return 1
            ;;
    esac
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
        print_error "Move.toml not found. Please run this script from the stake module directory."
        exit 1
    fi
    
    # Check if sui client is configured
    if ! sui client active-address &> /dev/null; then
        print_error "SUI client is not configured. Please set up your wallet first:"
        echo "  sui client new-address ed25519"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build the module
build_module() {
    print_status "Building staking module..."
    
    if sui move build; then
        print_success "Module built successfully"
    else
        print_error "Failed to build module"
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

# Function to deploy the module
deploy_module() {
    local network=$1
    local gas_budget=$2
    
    print_status "Deploying to $network network with gas budget $gas_budget..."
    
    # Get current active address
    local active_address=$(sui client active-address)
    print_status "Deploying from address: $active_address"
    
    # Deploy the module
    local deploy_output=$(sui client publish --gas-budget "$gas_budget" --network "$network" --json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "Module deployed successfully!"
        
        # Extract package ID from output
        local package_id=$(echo "$deploy_output" | grep -o '"packageId":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$package_id" ]]; then
            print_success "Package ID: $package_id"
            echo "$package_id" > .deployed_package_id
        fi
        
        # Extract transaction digest
        local tx_digest=$(echo "$deploy_output" | grep -o '"digest":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$tx_digest" ]]; then
            print_success "Transaction Digest: $tx_digest"
            echo "$tx_digest" > .deployed_tx_digest
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

# Function to verify deployment
verify_deployment() {
    local network=$1
    local package_id_file=".deployed_package_id"
    
    if [[ -f "$package_id_file" ]]; then
        local package_id=$(cat "$package_id_file")
        print_status "Verifying deployment for package: $package_id"
        
        # Check if package exists on network
        if sui client object --id "$package_id" --network "$network" &> /dev/null; then
            print_success "Package verified on $network network"
        else
            print_warning "Could not verify package on $network network"
        fi
    else
        print_warning "No package ID found for verification"
    fi
}

# Function to show post-deployment info
show_post_deployment_info() {
    local network=$1
    local package_id_file=".deployed_package_id"
    
    print_status "Deployment completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Initialize the global configuration:"
    echo "   sui client call --package <PACKAGE_ID> --module stake_config --function init"
    echo ""
    echo "2. Set up admin addresses:"
    echo "   sui client call --package <PACKAGE_ID> --module stake_config --function set_emergency_admin_address"
    echo "   sui client call --package <PACKAGE_ID> --module stake_config --function set_treasury_admin_address"
    echo ""
    echo "3. Create your first staking pool:"
    echo "   sui client call --package <PACKAGE_ID> --module stake_entries --function register_pool"
    echo ""
    
    if [[ -f "$package_id_file" ]]; then
        local package_id=$(cat "$package_id_file")
        echo "Package ID: $package_id"
        echo "Network: $network"
        echo ""
        echo "You can view your package on Sui Explorer:"
        echo "https://suiexplorer.com/object/$package_id?network=$network"
    fi
}

# Main execution
main() {
    # Parse command line arguments
    local network="$DEFAULT_NETWORK"
    local gas_budget="$DEFAULT_GAS_BUDGET"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--network)
                network="$2"
                shift 2
                ;;
            -g|--gas-budget)
                gas_budget="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate inputs
    if ! validate_network "$network"; then
        exit 1
    fi
    
    # Check if gas budget is a positive integer
    if ! [[ "$gas_budget" =~ ^[0-9]+$ ]] || [[ "$gas_budget" -le 0 ]]; then
        print_error "Gas budget must be a positive integer"
        exit 1
    fi
    
    # Show deployment configuration
    echo "=========================================="
    echo "SeaPad Staking Module Deployment"
    echo "=========================================="
    echo "Network: $network"
    echo "Gas Budget: $gas_budget"
    echo "=========================================="
    echo ""
    
    # Confirm deployment
    if [[ "$network" == "mainnet" ]]; then
        echo -e "${YELLOW}WARNING: You are about to deploy to MAINNET!${NC}"
        echo "This will cost real SUI tokens."
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deployment cancelled"
            exit 0
        fi
    fi
    
    # Execute deployment steps
    check_prerequisites
    build_module
    run_tests
    deploy_module "$network" "$gas_budget"
    verify_deployment "$network"
    show_post_deployment_info "$network"
}

# Run main function with all arguments
main "$@"
