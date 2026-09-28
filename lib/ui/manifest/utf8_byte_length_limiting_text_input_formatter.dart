import 'dart:convert';

import 'package:flutter/services.dart';

/// Limita uma edição pelo tamanho UTF-8 sem descartar texto válido existente.
///
/// Quando uma inserção ou substituição ultrapassa [maxBytes], o formatter
/// preserva o prefixo e o sufixo não alterados e aceita somente os code points
/// da parte inserida que ainda cabem. Nenhum par substituto UTF-16 é cortado.
final class Utf8ByteLengthLimitingTextInputFormatter
    extends TextInputFormatter {
  Utf8ByteLengthLimitingTextInputFormatter({
    required this.maxBytes,
    this.onLimitExceeded,
  }) {
    if (maxBytes < 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'não pode ser negativo');
    }
  }

  final int maxBytes;
  final VoidCallback? onLimitExceeded;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (utf8.encode(newValue.text).length <= maxBytes) return newValue;

    onLimitExceeded?.call();

    final oldRunes = oldValue.text.runes.toList(growable: false);
    final newRunes = newValue.text.runes.toList(growable: false);
    var prefixLength = 0;
    final shortestLength = oldRunes.length < newRunes.length
        ? oldRunes.length
        : newRunes.length;
    while (prefixLength < shortestLength &&
        oldRunes[prefixLength] == newRunes[prefixLength]) {
      prefixLength++;
    }

    var suffixLength = 0;
    while (suffixLength < oldRunes.length - prefixLength &&
        suffixLength < newRunes.length - prefixLength &&
        oldRunes[oldRunes.length - suffixLength - 1] ==
            newRunes[newRunes.length - suffixLength - 1]) {
      suffixLength++;
    }

    final prefixRunes = newRunes.take(prefixLength).toList(growable: false);
    final suffixRunes = suffixLength == 0
        ? const <int>[]
        : newRunes.skip(newRunes.length - suffixLength).toList(growable: false);
    final fixedBytes = _utf8Length(prefixRunes) + _utf8Length(suffixRunes);

    // Um valor antigo vindo do banco já respeita o limite. Esta salvaguarda
    // mantém o conteúdo anterior caso um chamador injete estado inválido.
    if (fixedBytes > maxBytes) return oldValue;

    final insertedEnd = newRunes.length - suffixLength;
    final acceptedInsertion = <int>[];
    var remainingBytes = maxBytes - fixedBytes;
    for (final rune
        in newRunes.skip(prefixLength).take(insertedEnd - prefixLength)) {
      final runeBytes = _utf8LengthOfRune(rune);
      if (runeBytes > remainingBytes) break;
      acceptedInsertion.add(rune);
      remainingBytes -= runeBytes;
    }

    final prefix = String.fromCharCodes(prefixRunes);
    final insertion = String.fromCharCodes(acceptedInsertion);
    final suffix = String.fromCharCodes(suffixRunes);
    final acceptedText = '$prefix$insertion$suffix';

    return TextEditingValue(
      text: acceptedText,
      selection: TextSelection.collapsed(
        offset: prefix.length + insertion.length,
      ),
      composing: TextRange.empty,
    );
  }
}

int _utf8Length(Iterable<int> runes) =>
    runes.fold<int>(0, (total, rune) => total + _utf8LengthOfRune(rune));

int _utf8LengthOfRune(int rune) {
  if (rune <= 0x7F) return 1;
  if (rune <= 0x7FF) return 2;
  if (rune <= 0xFFFF) return 3;
  return 4;
}
