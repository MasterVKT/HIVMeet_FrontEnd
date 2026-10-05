import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android registers only the payment result custom link', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:scheme="hivmeet"'));
    expect(manifest, contains('android:host="payment"'));
    expect(manifest, contains('android:path="/result"'));
    expect(manifest, contains('flutter_deeplinking_enabled'));
  });

  test('iOS registers the payment scheme through app_links', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>hivmeet</string>'));
    expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>'));
    expect(plist, contains('<false/>'));
  });
}
