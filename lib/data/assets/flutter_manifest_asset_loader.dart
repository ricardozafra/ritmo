import 'package:flutter/services.dart';

import '../../domain/manifest/manifest_service.dart';

/// Carrega o manifesto Markdown empacotado no bundle Flutter.
final class FlutterManifestAssetLoader implements ManifestAssetLoader {
  FlutterManifestAssetLoader({
    AssetBundle? bundle,
    this.assetPath = defaultAssetPath,
    this.assetVersion = defaultAssetVersion,
  }) : _bundle = bundle ?? rootBundle;

  static const String defaultAssetPath = 'assets/manifesto/manifesto.md';
  static const String defaultAssetVersion = 'manifest-v1';

  final AssetBundle _bundle;
  final String assetPath;
  final String assetVersion;

  @override
  Future<ManifestAsset> load() async => ManifestAsset(
    contentMarkdown: await _bundle.loadString(assetPath),
    version: assetVersion,
  );
}
