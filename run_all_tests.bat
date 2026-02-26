@echo off
REM HIVMeet Complete Test Suite Execution Script (Windows)
REM Task: 002-audit-and-implement-discovery-page-spec-compliance
REM Subtask: 6.9 - Execute complete test suite (unit + widget + integration)

echo =========================================
echo HIVMeet Test Suite Execution (Windows)
echo =========================================
echo.

REM Step 1: Verify Flutter version
echo [INFO] Checking Flutter version...
flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter not found or not in PATH
    exit /b 1
)
echo.

REM Step 2: Clean previous build artifacts
echo [INFO] Cleaning previous build artifacts...
call flutter clean
echo.

REM Step 3: Get dependencies
echo [INFO] Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies
    exit /b 1
)
echo.

REM Step 4: Run unit tests
echo [INFO] Running unit tests...
echo =========================================
call flutter test test/domain/usecases/ test/data/models/ test/data/repositories/ test/data/datasources/ --reporter expanded --no-pub
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Unit tests failed
    exit /b 1
)
echo.
echo [INFO] Unit tests passed
echo.

REM Step 5: Run widget tests
echo [INFO] Running widget tests...
echo =========================================
call flutter test test/presentation/widgets/ test/presentation/pages/ test/widget_test/ --reporter expanded --no-pub
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Widget tests failed
    exit /b 1
)
echo.
echo [INFO] Widget tests passed
echo.

REM Step 6: Run BLoC tests
echo [INFO] Running BLoC tests...
echo =========================================
call flutter test test/presentation/blocs/ --reporter expanded --no-pub
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] BLoC tests failed
    exit /b 1
)
echo.
echo [INFO] BLoC tests passed
echo.

REM Step 7: Run accessibility tests
echo [INFO] Running accessibility tests...
echo =========================================
call flutter test test/accessibility/ --reporter expanded --no-pub
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Accessibility tests failed
    exit /b 1
)
echo.
echo [INFO] Accessibility tests passed
echo.

REM Step 8: Run integration tests
echo [INFO] Running integration tests...
echo =========================================
if exist "test\integration_test.dart" (
    call flutter test test/integration_test.dart --reporter expanded --no-pub
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Integration tests failed
        exit /b 1
    )
    echo [INFO] Integration tests passed
) else (
    echo [WARNING] No integration_test.dart found, skipping
)
echo.

REM Step 9: Run complete test suite with coverage
echo [INFO] Running complete test suite with coverage...
echo =========================================
call flutter test --coverage --reporter expanded --no-pub
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Complete test suite failed
    exit /b 1
)
echo.
echo [INFO] Complete test suite passed
echo.

REM Summary
echo =========================================
echo [INFO] ALL TESTS PASSED
echo =========================================
echo.
echo Test Summary:
echo   - Unit tests
echo   - Widget tests
echo   - BLoC tests
echo   - Accessibility tests
echo   - Integration tests
echo.
echo [INFO] Test suite execution complete!
echo Coverage report available at: coverage\lcov.info
echo.
pause
