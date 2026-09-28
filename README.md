# ritmo

Aplicativo Flutter local-first para acompanhamento do cumprimento diário.

## Validação

Execute antes de enviar alterações:

```shell
flutter analyze
dart run tool/clock_lint.dart
flutter test
```

`clock_lint.dart` encerra com código diferente de zero quando encontra
`DateTime.now()` em código de produção fora de
`lib/domain/time/operational_clock.dart`, podendo ser usado diretamente na CI.
