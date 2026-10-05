import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/logging_config.dart';

void main() {
  test('debugPrint wrapper does not call itself recursively', () {
    final originalDebugPrint = debugPrint;
    addTearDown(() => debugPrint = originalDebugPrint);

    LoggingConfig.init();

    expect(
      () => debugPrint('startup diagnostic for sandbox@example.com'),
      returnsNormally,
    );
  });
}
