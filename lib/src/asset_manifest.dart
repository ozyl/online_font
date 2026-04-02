import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' as services;

/// A class to obtain and memoize the app's asset manifest.
///
/// Used to check whether a font is provided as an asset.
class AssetManifest {
  AssetManifest({this.enableCache = true});

  static Future<Map<String, List<String>>?>? _jsonFuture;

  /// Whether the rootBundle should cache the asset manifest.
  ///
  /// Enabled by default. Should only be disabled during tests.
  final bool enableCache;

  Future<Map<String, List<String>>?>? json() {
    _jsonFuture ??= _loadAssetManifestJson();
    return _jsonFuture;
  }

  Future<Map<String, List<String>>?> _loadAssetManifestJson() async {
    try {
      if (!enableCache) {
        // Ensure we don't reuse any cached manifest bytes across retries.
        // (The asset path differs by Flutter version/build pipeline.)
        try {
          services.rootBundle.evict('AssetManifest.json');
        } catch (_) {}
        try {
          services.rootBundle.evict('AssetManifest.bin');
        } catch (_) {}
      }

      final assetManifest = await services.AssetManifest.loadFromAssetBundle(
        services.rootBundle,
      );
      // Our consumers only iterate over `manifest.values`, so we can safely
      // place all assets under a single key.
      return <String, List<String>>{'value': assetManifest.listAssets()};
    } catch (e) {
      try {
        services.rootBundle.evict('AssetManifest.json');
      } catch (_) {}
      try {
        services.rootBundle.evict('AssetManifest.bin');
      } catch (_) {}
      rethrow;
    }
  }

  @visibleForTesting
  static void reset() => _jsonFuture = null;
}
