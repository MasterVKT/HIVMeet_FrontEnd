import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hivmeet/core/kyc/kyc_access_controller.dart';

class DefaultKycMediaCacheCleaner implements KycMediaCacheCleaner {
  @override
  Future<void> clearPrivateMedia() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await DefaultCacheManager().emptyCache();
  }
}
