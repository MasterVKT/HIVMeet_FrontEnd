import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/utils/log_service.dart';

void main() {
  test('redacts PII while retaining pseudonymous correlation', () {
    const raw = 'Authenticated user=alice@example.com '
        'id=8b1a9953-c461-4f36-9c2b-2a2f9c379f10 '
        'display_name=Alice location=Douala latitude=4.0511 '
        'photo_url=https://cdn.example.test/private/alice.jpg?token=secret '
        'callback=https://api.example.test/payment/result '
        'phone=+237699887766';

    final redacted = PrivacyLogSanitizer.sanitize(raw);

    for (final secret in <String>[
      'alice@example.com',
      '8b1a9953-c461-4f36-9c2b-2a2f9c379f10',
      'Alice',
      'Douala',
      '4.0511',
      '/private/alice.jpg',
      '/payment/result',
      '+237699887766',
    ]) {
      expect(redacted, isNot(contains(secret)));
    }
    expect(redacted, contains('<email:redacted>'));
    expect(redacted, contains('<id:'));
    expect(redacted, contains('<url:api.example.test>'));
  });

  test('redacts a bare JWT / Bearer token even without a field-name prefix',
      () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.'
        'dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
    final redacted = PrivacyLogSanitizer.sanitize('Authorization: Bearer $jwt');

    expect(redacted, isNot(contains(jwt)));
    expect(redacted, contains('<token:redacted>'));
  });

  test('uses the same pseudonym for the same UUID', () {
    const id = '8b1a9953-c461-4f36-9c2b-2a2f9c379f10';
    final redacted = PrivacyLogSanitizer.sanitize('$id then $id');
    final pseudonyms = RegExp(r'<id:[0-9a-f]+>')
        .allMatches(redacted)
        .map((match) => match.group(0))
        .toList();

    expect(pseudonyms, hasLength(2));
    expect(pseudonyms.first, pseudonyms.last);
  });
}
