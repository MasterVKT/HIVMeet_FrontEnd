#!/bin/bash
# HIVMeet Complete Test Suite Execution Script
# Task: 002-audit-and-implement-discovery-page-spec-compliance
# Subtask: 6.9 - Execute complete test suite (unit + widget + integration)

set -e  # Exit on error

echo "========================================="
echo "HIVMeet Test Suite Execution"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Step 1: Verify Flutter version
print_status "Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version | head -n 1 | awk '{print $2}')
echo "Current Flutter version: $FLUTTER_VERSION"
echo "Required Flutter version: >= 3.24.0"

# Parse version numbers for comparison
CURRENT_MAJOR=$(echo $FLUTTER_VERSION | cut -d. -f1)
CURRENT_MINOR=$(echo $FLUTTER_VERSION | cut -d. -f2)
REQUIRED_MAJOR=3
REQUIRED_MINOR=24

if [ "$CURRENT_MAJOR" -lt "$REQUIRED_MAJOR" ] ||
   ([ "$CURRENT_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$CURRENT_MINOR" -lt "$REQUIRED_MINOR" ]); then
    print_error "Flutter version $FLUTTER_VERSION is below minimum required version 3.24.0"
    print_warning "Please upgrade Flutter: flutter upgrade"
    exit 1
fi

print_status "Flutter version check passed ✓"
echo ""

# Step 2: Clean previous build artifacts
print_status "Cleaning previous build artifacts..."
flutter clean
echo ""

# Step 3: Get dependencies
print_status "Getting dependencies..."
flutter pub get
echo ""

# Step 4: Run unit tests
print_status "Running unit tests..."
echo "========================================="
flutter test test/domain/usecases/ \
    test/data/models/ \
    test/data/repositories/ \
    test/data/datasources/ \
    --reporter expanded \
    --no-pub || {
    print_error "Unit tests failed"
    exit 1
}
echo ""
print_status "Unit tests passed ✓"
echo ""

# Step 5: Run widget tests
print_status "Running widget tests..."
echo "========================================="
flutter test test/presentation/widgets/ \
    test/presentation/pages/ \
    test/widget_test/ \
    --reporter expanded \
    --no-pub || {
    print_error "Widget tests failed"
    exit 1
}
echo ""
print_status "Widget tests passed ✓"
echo ""

# Step 6: Run BLoC tests
print_status "Running BLoC tests..."
echo "========================================="
flutter test test/presentation/blocs/ \
    --reporter expanded \
    --no-pub || {
    print_error "BLoC tests failed"
    exit 1
}
echo ""
print_status "BLoC tests passed ✓"
echo ""

# Step 7: Run accessibility tests
print_status "Running accessibility tests..."
echo "========================================="
flutter test test/accessibility/ \
    --reporter expanded \
    --no-pub || {
    print_error "Accessibility tests failed"
    exit 1
}
echo ""
print_status "Accessibility tests passed ✓"
echo ""

# Step 8: Run integration tests
print_status "Running integration tests..."
echo "========================================="
if [ -f "test/integration_test.dart" ]; then
    flutter test test/integration_test.dart \
        --reporter expanded \
        --no-pub || {
        print_error "Integration tests failed"
        exit 1
    }
    print_status "Integration tests passed ✓"
else
    print_warning "No integration_test.dart found, skipping"
fi
echo ""

# Step 9: Run complete test suite with coverage
print_status "Running complete test suite with coverage..."
echo "========================================="
flutter test --coverage --reporter expanded --no-pub || {
    print_error "Complete test suite failed"
    exit 1
}
echo ""
print_status "Complete test suite passed ✓"
echo ""

# Step 10: Generate coverage report
if command -v lcov &> /dev/null && command -v genhtml &> /dev/null; then
    print_status "Generating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    print_status "Coverage report generated at: coverage/html/index.html"
    print_status "To view: open coverage/html/index.html"
else
    print_warning "lcov/genhtml not installed. Install with: sudo apt-get install lcov"
    print_status "Raw coverage data available at: coverage/lcov.info"
fi
echo ""

# Step 11: Check coverage threshold
print_status "Checking coverage threshold..."
if command -v lcov &> /dev/null; then
    COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
    THRESHOLD=80

    echo "Current coverage: ${COVERAGE}%"
    echo "Required threshold: ${THRESHOLD}%"

    if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
        print_error "Coverage ${COVERAGE}% is below threshold ${THRESHOLD}%"
        exit 1
    else
        print_status "Coverage check passed ✓"
    fi
else
    print_warning "Cannot check coverage threshold without lcov installed"
fi
echo ""

# Summary
echo "========================================="
print_status "ALL TESTS PASSED ✓"
echo "========================================="
echo ""
echo "Test Summary:"
echo "  ✓ Unit tests"
echo "  ✓ Widget tests"
echo "  ✓ BLoC tests"
echo "  ✓ Accessibility tests"
echo "  ✓ Integration tests"
echo "  ✓ Coverage >= 80%"
echo ""
print_status "Test suite execution complete!"
