import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/manifest_asset_check.dart';

const canonicalManifest = '''# Pedra

Minha vida é formada pelo que pratico todos os dias.

Cultivo um corpo capaz, uma mente atenta e um trabalho com propósito. Não transformo tropeços em identidade: observo, ajusto e continuo.

Crescer exige disciplina, mas também silêncio, recuperação e respeito aos próprios limites. Meu compromisso é sustentar um ritmo que possa atravessar o tempo.

## IV. O JURAMENTO INTERNO

> Eu escolho presença em vez de automatismo.
> Escolho responsabilidade em vez de desculpas.
> Cada dia é uma oportunidade de praticar quem desejo me tornar.''';

void main() {
  test('canonical manifest asset exists, is integral, and fits the limit', () {
    expect(File(manifestAssetPath).readAsStringSync(), canonicalManifest);
    expect(validateManifestAsset(), lessThanOrEqualTo(1024 * 1024));
  });

  test('fails when the manifest asset does not exist', () {
    expect(
      () => validateManifestAsset('assets/manifesto/missing.md'),
      throwsA(isA<StateError>()),
    );
  });

  test('fails when the manifest asset uses CRLF terminators', () {
    final directory = Directory.systemTemp.createTempSync('ritmo_manifest_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/manifesto.md')
      ..writeAsStringSync(canonicalManifest.replaceAll('\n', '\r\n'));

    expect(() => validateManifestAsset(file.path), throwsA(isA<StateError>()));
  });

  test('fails when UTF-8 content exceeds 1 MiB', () {
    final directory = Directory.systemTemp.createTempSync('ritmo_manifest_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/manifesto.md')
      ..writeAsStringSync(List.filled(524289, 'á').join());

    expect(() => validateManifestAsset(file.path), throwsA(isA<StateError>()));
  });
}
