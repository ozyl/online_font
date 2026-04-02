// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/services.dart' hide AssetManifest;
import 'package:flutter_test/flutter_test.dart';
import 'package:online_font/src/asset_manifest.dart';

const _fakeAssetManifestBinMessage = <String, Object?>{'fake': 0};
final ByteData _fakeAssetManifestBinEncoded =
    const StandardMessageCodec().encodeMessage(_fakeAssetManifestBinMessage)!;
var _assetManifestLoadCount = 0;

late AssetManifest assetManifest;

void main() {
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
      _assetManifestLoadCount++;
      // The app's `AssetManifest` API reads `AssetManifest.bin` and decodes it
      // using Flutter's standard message codec.
      return Future.value(_fakeAssetManifestBinEncoded);
    });
    // Disable cache so that we can see if the manifest bundle is requested
    // more than once.
    assetManifest = AssetManifest(enableCache: false);
  });

  tearDown(() async {
    _assetManifestLoadCount = 0;
    AssetManifest.reset();
  });

  testWidgets('AssetManifest loads once when called multiple times in parallel',
      (tester) async {
    final manifestJsons = await Future.wait<Map<String, List<String>>?>([
      assetManifest.json()!,
      assetManifest.json()!,
      assetManifest.json()!,
    ]);
    _verifyAssetManifestLoadedOnce();
    manifestJsons.forEach(_verifyAssetManifestContent);
  });

  testWidgets(
      'AssetManifest loads once when called multiple times in parallel then multiple times in succession',
      (tester) async {
    final manifestJsons = await Future.wait<Map<String, List<String>>?>([
      assetManifest.json()!,
      assetManifest.json()!,
      assetManifest.json()!,
    ]);
    _verifyAssetManifestLoadedOnce();
    manifestJsons.forEach(_verifyAssetManifestContent);

    final manifestJson3 = await assetManifest.json();
    final manifestJson4 = await assetManifest.json();
    _verifyAssetManifestLoadedOnce();
    _verifyAssetManifestContent(manifestJson3);
    _verifyAssetManifestContent(manifestJson4);
  });

  testWidgets('AssetManifest loads', (tester) async {
    final manifestJson = await assetManifest.json();
    _verifyAssetManifestLoadedOnce();
    _verifyAssetManifestContent(manifestJson);
  });

  testWidgets(
      'AssetManifest loads once when called multiple times in succession',
      (tester) async {
    final manifestJson1 = await assetManifest.json();
    _verifyAssetManifestLoadedOnce();
    _verifyAssetManifestContent(manifestJson1);

    final manifestJson2 = await assetManifest.json();
    _verifyAssetManifestLoadedOnce();
    _verifyAssetManifestContent(manifestJson2);
  });
}

void _verifyAssetManifestLoadedOnce() {
  expect(_assetManifestLoadCount, 1);
}

void _verifyAssetManifestContent(Map<String, dynamic>? manifestJson) {
  expect(manifestJson!['value'], ['fake']);
}
