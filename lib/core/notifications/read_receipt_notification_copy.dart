import 'package:hivmeet/core/services/localization_service.dart';

/// Localized, content-free text for a Premium read-receipt alert.
class ReadReceiptNotificationCopy {
  const ReadReceiptNotificationCopy._();

  static String title() =>
      LocalizationService.translate('notifications.message_read_title');

  static String body(Map<String, dynamic> data) {
    final count = _positiveInt(data['message_count']) ?? 1;
    final readerName = data['reader_name']?.toString().trim() ?? '';
    final hasReaderName = readerName.isNotEmpty;

    if (count == 1) {
      return LocalizationService.translate(
        hasReaderName
            ? 'notifications.message_read_body_one'
            : 'notifications.message_read_body_one_anonymous',
        params: hasReaderName ? {'name': readerName} : const {},
      );
    }

    return LocalizationService.translate(
      hasReaderName
          ? 'notifications.message_read_body_many'
          : 'notifications.message_read_body_many_anonymous',
      params: {
        if (hasReaderName) 'name': readerName,
        'count': count.toString(),
      },
    );
  }

  static int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      int value => value,
      num value => value.toInt(),
      _ => int.tryParse(value?.toString() ?? ''),
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
