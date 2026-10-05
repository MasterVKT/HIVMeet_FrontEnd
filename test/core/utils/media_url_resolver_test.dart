import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/app_config.dart';
import 'package:hivmeet/core/utils/media_url_resolver.dart';

void main() {
  group('MediaUrlResolver', () {
    test('keeps an absolute HTTP URL unchanged', () {
      expect(
        MediaUrlResolver.resolve('https://cdn.example.test/image.jpg'),
        'https://cdn.example.test/image.jpg',
      );
    });

    test('normalizes both supported relative media forms without double slash', () {
      expect(
        MediaUrlResolver.resolve('/media/messages/a.jpg'),
        '${AppConfig.apiBaseUrl}/media/messages/a.jpg',
      );
      expect(
        MediaUrlResolver.resolve('media/messages/a.jpg'),
        '${AppConfig.apiBaseUrl}/media/messages/a.jpg',
      );
    });

    test('rejects a non HTTP scheme', () {
      expect(MediaUrlResolver.resolve('file:///private/photo.jpg'), isNull);
    });
  });
}
