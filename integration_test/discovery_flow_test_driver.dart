// integration_test/discovery_flow_test_driver.dart

import 'package:integration_test/integration_test_driver.dart';

/// Test driver for Discovery Page E2E integration tests.
///
/// This file enables running integration tests on physical devices and emulators.
/// It provides the necessary driver configuration for the integration test framework.
///
/// **Usage:**
/// ```bash
/// # Run on connected device
/// flutter drive \
///   --driver=integration_test/discovery_flow_test_driver.dart \
///   --target=integration_test/discovery_flow_test.dart
///
/// # Run on specific device
/// flutter drive \
///   --driver=integration_test/discovery_flow_test_driver.dart \
///   --target=integration_test/discovery_flow_test.dart \
///   -d <device-id>
/// ```
Future<void> main() => integrationDriver();
