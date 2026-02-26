#!/bin/bash

# run_tests.sh - Helper script to run Discovery Page integration tests
#
# Usage:
#   ./integration_test/run_tests.sh [options]
#
# Options:
#   --help, -h           Show this help message
#   --device, -d <id>    Run on specific device
#   --verbose, -v        Run with verbose output
#   --driver             Run with flutter drive (for physical devices)
#   --all                Run all tests (including skipped ones)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
VERBOSE=""
DEVICE=""
USE_DRIVER=false
RUN_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Discovery Page Integration Tests Runner"
      echo ""
      echo "Usage: ./integration_test/run_tests.sh [options]"
      echo ""
      echo "Options:"
      echo "  -h, --help          Show this help message"
      echo "  -d, --device <id>   Run on specific device"
      echo "  -v, --verbose       Run with verbose output"
      echo "  --driver            Run with flutter drive"
      echo "  --all               Run all tests including skipped ones"
      echo ""
      echo "Examples:"
      echo "  ./integration_test/run_tests.sh"
      echo "  ./integration_test/run_tests.sh -v"
      echo "  ./integration_test/run_tests.sh -d emulator-5554"
      echo "  ./integration_test/run_tests.sh --driver"
      exit 0
      ;;
    -v|--verbose)
      VERBOSE="-v"
      shift
      ;;
    -d|--device)
      DEVICE="-d $2"
      shift 2
      ;;
    --driver)
      USE_DRIVER=true
      shift
      ;;
    --all)
      RUN_ALL=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Discovery Page Integration Tests${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Display Flutter version
echo -e "${YELLOW}Flutter version:${NC}"
flutter --version | head -n 1
echo ""

# List available devices
echo -e "${YELLOW}Available devices:${NC}"
flutter devices
echo ""

# Run tests
if [ "$USE_DRIVER" = true ]; then
    echo -e "${YELLOW}Running tests with flutter drive...${NC}"
    flutter drive \
        --driver=integration_test/discovery_flow_test_driver.dart \
        --target=integration_test/discovery_flow_test.dart \
        $DEVICE \
        $VERBOSE
else
    echo -e "${YELLOW}Running integration tests...${NC}"
    flutter test integration_test/discovery_flow_test.dart \
        $DEVICE \
        $VERBOSE
fi

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${GREEN}======================================${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}✗ Tests failed!${NC}"
    echo -e "${RED}======================================${NC}"
    exit 1
fi
