import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release signing fails closed without external secrets', () {
    final gradle = File('android/app/build.gradle').readAsStringSync();

    expect(gradle, contains('HIVMEET_ANDROID_KEYSTORE_PATH'));
    expect(gradle, contains('HIVMEET_ANDROID_STORE_PASSWORD'));
    expect(gradle, contains('HIVMEET_ANDROID_KEY_ALIAS'));
    expect(gradle, contains('HIVMEET_ANDROID_KEY_PASSWORD'));
    expect(gradle, contains('requestsReleaseArtifact'));
    expect(gradle, contains('!hasCompleteReleaseSigning'));
    expect(gradle, isNot(contains('signingConfig signingConfigs.debug')));
  });

  test('the committed signing template contains placeholders only', () {
    final template = File('android/key.properties.example').readAsStringSync();

    expect(template, contains('storePassword=<secret-du-keystore>'));
    expect(template, contains('keyPassword=<secret-de-la-cle>'));
    expect(template, isNot(contains('BEGIN PRIVATE KEY')));
  });
}
