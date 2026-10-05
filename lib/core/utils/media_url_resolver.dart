import 'package:hivmeet/core/config/app_config.dart';

/// Resolves every media representation emitted during the backend transition.
///
/// REST can return an absolute URL while older records and WebSocket events
/// may contain either `/media/...` or `media/...`.  [Uri.resolveUri] preserves
/// query strings and prevents the accidental `//media` path that broke images
/// on physical devices.
class MediaUrlResolver {
  const MediaUrlResolver._();

  static String? resolve(String? rawUrl) {
    final raw = rawUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.hasScheme) {
      return uri.scheme == 'http' || uri.scheme == 'https'
          ? uri.toString()
          : null;
    }

    final relative = Uri.tryParse(raw.startsWith('/') ? raw : '/$raw');
    if (relative == null) return null;
    return Uri.parse(AppConfig.apiBaseUrl).resolveUri(relative).toString();
  }
}
