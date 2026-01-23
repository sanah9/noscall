#!/bin/bash

# Test runner script
# Usage: ./scripts/run_tests.sh [unit|widget|integration|all]

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_info "Running Flutter analyzer..."
flutter analyze

# Get test type parameter
TEST_TYPE=${1:-all}

case $TEST_TYPE in
    unit)
        print_info "Running unit tests..."
        flutter test test/unit/ --coverage
        ;;
    widget)
        print_info "Running widget tests..."
        flutter test test/widget/ --coverage
        ;;
    integration)
        print_info "Running integration tests..."
        flutter test test/integration/ --coverage
        ;;
    all)
        print_info "Running all tests..."
        flutter test --coverage
        
        # Generate coverage report
        if command -v genhtml &> /dev/null; then
            print_info "Generating coverage report..."
            genhtml coverage/lcov.info -o coverage/html
            print_info "Coverage report generated: coverage/html/index.html"
        else
            print_warning "genhtml is not installed, skipping coverage report generation"
            print_warning "Install: brew install lcov (macOS) or apt-get install lcov (Linux)"
        fi
        ;;
    *)
        print_error "Unknown test type: $TEST_TYPE"
        echo "Usage: $0 [unit|widget|integration|all]"
        exit 1
        ;;
esac

print_info "✅ Tests completed!"
