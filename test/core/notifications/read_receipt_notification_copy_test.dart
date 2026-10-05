import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hivmeet/core/notifications/read_receipt_notification_copy.dart';
import 'package:hivmeet/core/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalizationService localization;

  setUp(() async {
    if (GetIt.instance.isRegistered<LocalizationService>()) {
      await GetIt.instance.unregister<LocalizationService>();
    }
    localization = LocalizationService();
    GetIt.instance.registerSingleton<LocalizationService>(localization);
    await localization.initialize('fr');
  });

  tearDown(() async {
    if (GetIt.instance.isRegistered<LocalizationService>()) {
      await GetIt.instance.unregister<LocalizationService>();
    }
  });

  test('uses French singular and plural copy without message content', () {
    expect(ReadReceiptNotificationCopy.title(), 'Lecture confirmée');
    expect(
      ReadReceiptNotificationCopy.body({
        'reader_name': 'Marie',
        'message_count': 1,
      }),
      'Marie a lu votre message',
    );
    expect(
      ReadReceiptNotificationCopy.body({
        'reader_name': 'Marie',
        'message_count': 3,
      }),
      'Marie a lu vos 3 messages',
    );
  });

  test('uses English anonymous fallback after a locale change', () async {
    await localization.changeLocale('en');

    expect(ReadReceiptNotificationCopy.title(), 'Read receipt');
    expect(
      ReadReceiptNotificationCopy.body({'message_count': 2}),
      '2 of your messages were read',
    );
  });
}
