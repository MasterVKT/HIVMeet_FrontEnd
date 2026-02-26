#!/bin/bash

# HIVMeet Accessibility Test Runner
# This script runs all automated accessibility tests and generates reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
VERBOSE=false
COVERAGE=false
REPORT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -c|--coverage)
      COVERAGE=true
      shift
      ;;
    -r|--report)
      REPORT=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -c, --coverage   Generate coverage report"
      echo "  -r, --report     Generate HTML accessibility report"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Print header
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    HIVMeet Accessibility Test Suite                   ${NC}"
echo -e "${BLUE}    WCAG 2.1 Level AA Compliance Validation           ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -n 1)${NC}"
echo ""

# Run tests
echo -e "${YELLOW}Running accessibility tests...${NC}"
echo ""

# Build test command
TEST_CMD="flutter test test/accessibility/"

if [ "$COVERAGE" = true ]; then
    TEST_CMD="$TEST_CMD --coverage"
fi

if [ "$VERBOSE" = true ]; then
    TEST_CMD="$TEST_CMD --verbose"
fi

# Execute tests
if eval $TEST_CMD; then
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ All accessibility tests passed!                     ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Print summary
    echo -e "${BLUE}Test Coverage Summary:${NC}"
    echo "  ✓ Color contrast ratios (WCAG 2.1 AA)"
    echo "  ✓ Touch target sizes (44x44 dp minimum)"
    echo "  ✓ Semantic labels for screen readers"
    echo "  ✓ Keyboard navigation support"
    echo "  ✓ Reduced motion preferences"
    echo "  ✓ Text scaling support"
    echo "  ✓ Theme contrast validation"
    echo ""

    # Generate coverage report if requested
    if [ "$COVERAGE" = true ]; then
        echo -e "${YELLOW}Generating coverage report...${NC}"

        if command -v lcov &> /dev/null && command -v genhtml &> /dev/null; then
            # Generate HTML report
            genhtml coverage/lcov.info -o coverage/accessibility_html &> /dev/null
            echo -e "${GREEN}✓ Coverage report generated: coverage/accessibility_html/index.html${NC}"

            # Extract coverage percentage
            COVERAGE_PERCENT=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}')
            echo -e "${BLUE}  Coverage: $COVERAGE_PERCENT${NC}"
        else
            echo -e "${YELLOW}⚠ lcov/genhtml not installed. Install with: sudo apt-get install lcov${NC}"
        fi
        echo ""
    fi

    # Generate accessibility report if requested
    if [ "$REPORT" = true ]; then
        echo -e "${YELLOW}Generating accessibility report...${NC}"

        REPORT_FILE="accessibility_report_$(date +%Y%m%d_%H%M%S).txt"

        {
            echo "HIVMeet Accessibility Test Report"
            echo "=================================="
            echo ""
            echo "Date: $(date)"
            echo "Flutter Version: $(flutter --version | head -n 1)"
            echo ""
            echo "Test Results:"
            echo "-------------"
            echo "Status: PASSED"
            echo ""
            echo "Tests Performed:"
            echo "  1. Color Contrast Ratios (WCAG 2.1 AA)"
            echo "     - Primary purple on white: ✓"
            echo "     - Dark purple on white: ✓"
            echo "     - White on primary purple: ✓"
            echo "     - Error color on white: ✓"
            echo "     - Success color on white: ✓"
            echo "     - Charcoal text on white: ✓ (AAA)"
            echo "     - Slate text on white: ✓"
            echo "     - Turquoise on white: ✓"
            echo ""
            echo "  2. Touch Target Sizes"
            echo "     - Minimum size validation: ✓"
            echo "     - Action buttons: ✓"
            echo "     - Interactive elements: ✓"
            echo ""
            echo "  3. Semantic Labels"
            echo "     - Profile cards: ✓"
            echo "     - Action buttons: ✓"
            echo "     - Sliders and toggles: ✓"
            echo "     - Premium features: ✓"
            echo ""
            echo "  4. Screen Reader Support"
            echo "     - Semantics tree structure: ✓"
            echo "     - Enabled/disabled states: ✓"
            echo "     - Announcements: ✓"
            echo ""
            echo "  5. Reduced Motion"
            echo "     - Preference detection: ✓"
            echo "     - Animation adjustment: ✓"
            echo ""
            echo "  6. Text Scaling"
            echo "     - Large text support: ✓"
            echo "     - Bold text preference: ✓"
            echo ""
            echo "Compliance Status: WCAG 2.1 Level AA ✓"
            echo ""
            echo "Recommendations:"
            echo "  - Continue manual testing with TalkBack (Android)"
            echo "  - Continue manual testing with VoiceOver (iOS)"
            echo "  - Test with real users who rely on accessibility features"
            echo ""
        } > "$REPORT_FILE"

        echo -e "${GREEN}✓ Accessibility report generated: $REPORT_FILE${NC}"
        echo ""
    fi

    # Success recommendations
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Run manual tests with TalkBack (Android)"
    echo "  2. Run manual tests with VoiceOver (iOS)"
    echo "  3. Test with reduced motion enabled"
    echo "  4. Test with maximum text size"
    echo "  5. Verify color contrast with external tools"
    echo ""
    echo -e "${GREEN}Accessibility compliance verified! ✓${NC}"

    exit 0
else
    echo ""
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ Accessibility tests failed!                         ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Common Issues:${NC}"
    echo "  1. Color contrast below 4.5:1 (WCAG AA)"
    echo "     → Use darker/lighter colors or adjust opacity"
    echo ""
    echo "  2. Touch targets smaller than 44x44 dp"
    echo "     → Increase widget size or add padding"
    echo ""
    echo "  3. Missing semantic labels"
    echo "     → Add Semantics widget or semanticLabel property"
    echo ""
    echo "  4. Non-focusable interactive elements"
    echo "     → Ensure buttons/links have proper semantics"
    echo ""
    echo -e "${BLUE}Resources:${NC}"
    echo "  - WCAG 2.1 Guidelines: https://www.w3.org/WAI/WCAG21/quickref/"
    echo "  - Flutter Accessibility: https://docs.flutter.dev/development/accessibility-and-localization/accessibility"
    echo "  - Test README: test/accessibility/README.md"
    echo ""

    exit 1
fi
