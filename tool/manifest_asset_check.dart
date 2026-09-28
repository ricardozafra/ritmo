import 'dart:convert';
import 'dart:io';

import 'package:ritmo/core/limits.dart';

const manifestAssetPath = 'assets/manifesto/manifesto.md';

int validateManifestAsset([String path = manifestAssetPath]) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Manifest asset not found: $path');
  }

  final content = file.readAsStringSync(encoding: utf8);
  final utf8Length = utf8.encode(content).length;
  if (utf8Length > Limits.manifestMaxUtf8Bytes) {
    throw StateError(
      'Manifest asset has $utf8Length UTF-8 bytes; '
      'maximum is ${Limits.manifestMaxUtf8Bytes}.',
    );
  }

  // RF-09.1: o asset é empacotado com terminadores LF. Um checkout que
  // reintroduza CRLF altera os bytes do texto canônico, portanto falha aqui
  // em vez de degradar silenciosamente a integridade do manifesto.
  if (content.contains('\r')) {
    throw StateError(
      'Manifest asset must use LF line terminators; found CR in $path.',
    );
  }

  return utf8Length;
}

void main(List<String> arguments) {
  final path = arguments.isEmpty ? manifestAssetPath : arguments.single;
  try {
    final size = validateManifestAsset(path);
    stdout.writeln('manifest_asset_check: $path is valid ($size UTF-8 bytes).');
  } on Object catch (error) {
    stderr.writeln('manifest_asset_check: $error');
    exitCode = 1;
  }
}