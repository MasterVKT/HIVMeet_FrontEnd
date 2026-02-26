# Test Execution Scripts - Quick Start Guide

This directory contains comprehensive test execution scripts for the HIVMeet Discovery page implementation.

## ⚠️ Prerequisites

Before running tests, ensure:
1. **Flutter SDK >= 3.24.0** is installed
2. **Git** is accessible in your PATH
3. All dependencies are installed (`flutter pub get`)

## 🚀 Quick Start

### Windows (Recommended)

```cmd
# Open Command Prompt or PowerShell (NOT Git Bash)
run_all_tests.bat
```

### Linux / macOS / WSL

```bash
chmod +x run_all_tests.sh
./run_all_tests.sh
```

## 📋 What Gets Tested

The scripts execute tests in this order:

1. ✅ **Unit Tests** - Domain layer use cases, data models, repositories
2. ✅ **Widget Tests** - UI components, pages, buttons, cards, modals
3. ✅ **BLoC Tests** - State management (Discovery, Matches, Chat, Conversations)
4. ✅ **Accessibility Tests** - WCAG 2.1 AA compliance
5. ✅ **Integration Tests** - Full user flows
6. ✅ **Coverage Report** - Generates coverage data and validates >= 80% threshold

## 📊 Expected Output

```
=========================================
HIVMeet Test Suite Execution
=========================================

[INFO] Checking Flutter version...
Current Flutter version: 3.24.0
Required Flutter version: >= 3.24.0
[INFO] Flutter version check passed ✓

[INFO] Cleaning previous build artifacts...
[INFO] Getting dependencies...
[INFO] Running unit tests...
=========================================
[... test output ...]
[INFO] Unit tests passed ✓

[INFO] Running widget tests...
[... continues through all test categories ...]

=========================================
[INFO] ALL TESTS PASSED ✓
=========================================

Test Summary:
  ✓ Unit tests
  ✓ Widget tests
  ✓ BLoC tests
  ✓ Accessibility tests
  ✓ Integration tests
  ✓ Coverage >= 80%
```

## ❌ Known Issues

### Issue: "Unable to find git in your PATH"

**Cause**: Flutter cannot locate git executable (common in Git Bash on Windows)

**Solution**: Use Windows Command Prompt or PowerShell instead of Git Bash

```cmd
# In Command Prompt or PowerShell
cd D:\Projets\HIVMeet\hivmeet\.auto-claude\worktrees\tasks\002-audit-and-implement-discovery-page-spec-compliance
run_all_tests.bat
```

### Issue: "Flutter SDK version solving failed"

**Cause**: Flutter version is below 3.24.0

**Solution**: Upgrade Flutter

```bash
flutter channel stable
flutter upgrade
flutter --version  # Verify >= 3.24.0
```

## 📁 Coverage Reports

After successful test execution, coverage reports are available at:

- **Raw data**: `coverage/lcov.info`
- **HTML report**: `coverage/html/index.html` (if lcov/genhtml installed)

### View HTML Coverage Report

**Linux/macOS**:
```bash
open coverage/html/index.html
```

**Windows**:
```cmd
start coverage\html\index.html
```

## 🔍 Troubleshooting

### Tests Fail

1. **Read the error message** carefully
2. **Identify the category**:
   - Test bug → Fix test logic
   - Code bug → Fix implementation
   - Environment → Check dependencies
   - Flaky test → Make deterministic
3. **Run specific test file**:
   ```bash
   flutter test test/path/to/failing_test.dart --reporter expanded
   ```
4. **Fix and verify**:
   ```bash
   # Run multiple times to ensure determinism
   flutter test test/path/to/failing_test.dart
   flutter test test/path/to/failing_test.dart
   flutter test test/path/to/failing_test.dart
   ```

### Coverage Below 80%

1. **Check which files are uncovered**:
   - View `coverage/html/index.html`
   - Look for red/yellow highlighted code
2. **Refer to test roadmap**:
   - See `TEST_IMPLEMENTATION_ROADMAP.md` for missing tests
   - See `COVERAGE_REPORT.md` for coverage analysis
3. **Implement missing tests** following existing patterns

### Script Permissions (Linux/macOS)

```bash
chmod +x run_all_tests.sh
```

## 📚 Documentation

- **TEST_EXECUTION_BLOCKER.md** - Detailed blocker documentation and resolution guide
- **COVERAGE_REPORT.md** - Coverage analysis from subtask 6.8
- **TEST_IMPLEMENTATION_ROADMAP.md** - Detailed test implementation plan
- **.claude/rules/testing.md** - Project testing standards

## 🤝 Contributing

When adding new tests:

1. Follow existing patterns in `test/` directory
2. Use `mocktail` for mocking
3. Use `bloc_test` for BLoC tests
4. Use `flutter_test` for widget tests
5. Ensure tests are deterministic (no DateTime.now(), no real network calls)
6. Run full suite before committing: `./run_all_tests.sh`

## 📞 Support

If tests continue to fail after following this guide:

1. Check the error logs carefully
2. Review `TEST_EXECUTION_BLOCKER.md` for known issues
3. Ensure Flutter SDK is updated (`flutter upgrade`)
4. Verify all dependencies are installed (`flutter pub get`)
5. Try running in a clean environment (CI/CD pipeline)

---

**Last Updated**: 2026-02-26
**Task**: 002-audit-and-implement-discovery-page-spec-compliance
**Subtask**: 6.9
**Status**: Ready for execution (pending environment configuration)
