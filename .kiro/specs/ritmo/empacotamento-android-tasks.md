# Empacotamento Android — Ritmo

Plano para tornar o app instalável/distribuível em Android. Fora do escopo funcional
da spec (é preparação de release), mas necessário para "entregar o app" num dispositivo.

Contexto atual observado:
- `applicationId` / `namespace`: `br.gov.sp.detran.ritmo`.
- `AndroidManifest.xml` do app: template padrão, sem permissões e sem receiver de boot.
- `build.gradle.kts` do app: release ainda assina com a chave de **debug** (TODO do template);
  sem core library desugaring.
- Plugin `flutter_local_notifications` 22.2.0 já declara `POST_NOTIFICATIONS` e `VIBRATE`
  no próprio manifest (merge automático) e **exige core library desugaring**
  (`desugar_jdk_libs:2.1.4`) — sem isso o build de release falha.
- Ritmo usa `AndroidScheduleMode.inexactAllowWhileIdle` → **não** precisa de
  `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`.
- Não há gravação de áudio implementada com pacote de microfone ainda (24.7 usa `just_audio`
  para reprodução; a captação de voz da nota/《revisão》 depende de um gravador — ver tarefa 5).

Validação padrão a cada mudança de código Dart/config: `flutter analyze --no-pub`,
`flutter test --no-pub --concurrency=1`. Build Android exige toolchain Android
(SDK/NDK/JDK) na máquina.

---

## 1. Habilitar core library desugaring (obrigatório p/ notificações)  [BAIXO RISCO]

- [x] 1.1 Ativar desugaring no `android/app/build.gradle.kts`
  - Em `compileOptions { }` adicionar `isCoreLibraryDesugaringEnabled = true`. [FEITO]
  - Adicionar bloco `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`. [FEITO]
  - _Validação:_ `flutter build apk --debug` (ou `--release` após tarefa 4) compila sem erro
    de desugaring. **PENDENTE de verificação:** esta máquina não tem Android SDK
    (`flutter doctor`: "Unable to locate Android SDK"); validar em máquina com toolchain Android.

---

## 2. Permissões e receiver de notificação no manifest  [BAIXO RISCO]

- [x] 2.1 Declarar `RECEIVE_BOOT_COMPLETED` e o boot receiver do plugin  [FEITO]
  - Arquivo: `android/app/src/main/AndroidManifest.xml`.
  - Adicionar, fora de `<application>`: `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`.
  - Dentro de `<application>`, registrar o receiver de reagendamento pós-boot do plugin
    (mantém as notificações de Revisão agendadas após reinício):
    ```xml
    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
      <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
      </intent-filter>
    </receiver>
    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
    ```
  - NÃO declarar `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (Ritmo usa modo inexato).
  - `POST_NOTIFICATIONS` já vem do plugin; a recusa deve manter o app 100% funcional
    (já garantido no gateway).
  - _Validação:_ `flutter build apk --debug` gera manifest final (merged) com o receiver;
    conferir no `app/build/outputs/logs` ou via `flutter build apk` sem erros de merge.

- [x] 2.2 Definir o rótulo do app (label) exibido ao usuário  [FEITO: "Ritmo"]
  - Trocar `android:label="ritmo"` por `"Ritmo"` (ou o nome oficial desejado) no
    `AndroidManifest.xml` do app.
  - _Validação:_ inspeção do manifest.

---

## 3. minSdk/targetSdk e revisão de versão  [MÉDIO RISCO]

- [x] 3.1 Confirmar `minSdk` compatível  [FEITO: minSdk = 23]
  - Fixado `minSdk = 23` (Android 6) no `build.gradle.kts`; `targetSdk` mantido em
    `flutter.targetSdkVersion` (herdado do Flutter, não fixo — decisão do usuário).
  - _Validação:_ **PENDENTE** — build de debug + fumaça em emulador exigem Android SDK
    (ausente nesta máquina).

- [x] 3.2 Definir `versionCode`/`versionName` de release  [FEITO: mantido 1.0.0+1]
  - Mantidos herdados de `flutter.versionCode/versionName` (de `pubspec.yaml` `1.0.0+1`)
    para o primeiro release.

---

## 4. Assinatura de release  [ALTO RISCO / EXIGE AÇÃO DO USUÁRIO — NÃO AUTOMATIZAR CEGO]

> O keystore é um SEGREDO. NÃO versionar `.jks`/`key.properties` no git. O `.gitignore`
> deve cobrir esses arquivos ANTES de criá-los.

- [ ] 4.1 Gerar o keystore de upload (ação do usuário)
  - Comando (usuário executa e guarda a senha em local seguro):
    `keytool -genkey -v -keystore ritmo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ritmo`
  - Guardar `ritmo-upload.jks` FORA do repositório (ou em caminho ignorado).

- [x] (parcial) `.gitignore` protege segredos  [FEITO]
  - Adicionadas regras `android/key.properties`, `**/*.jks`, `**/*.keystore` — verificadas
    com `git check-ignore`.

- [ ] 4.2 Criar `android/key.properties` (não versionado)  [AÇÃO DO USUÁRIO]
  - Conteúdo:
    ```
    storePassword=<senha>
    keyPassword=<senha>
    keyAlias=ritmo
    storeFile=<caminho absoluto p/ ritmo-upload.jks>
    ```
  - O `.gitignore` já cobre este arquivo (não será versionado).

- [x] 4.3 Ligar o signingConfig de release no `android/app/build.gradle.kts`  [FEITO]
  - `build.gradle.kts` agora carrega `rootProject.file("key.properties")`; quando presente,
    cria `signingConfigs.create("release")` e o build type `release` usa essa config; quando
    ausente, recorre à chave de debug (para `flutter run --release` em dev).
  - _Validação:_ **PENDENTE** — `flutter build appbundle --release` com um `key.properties`
    real gera o `.aab` assinado; exige Android SDK + keystore (ação do usuário).

---

## 5. (Dependente de produto) Captação de áudio da nota/《revisão》  [ESCLARECER ESCOPO]

- [ ] 5.1 Confirmar se a GRAVAÇÃO de voz será habilitada no cliente Android
  - A tarefa 24.7 entregou `AudioPolicy`/`AudioRepository` (limites, espaço, atomicidade),
    mas a captação real de microfone depende de um pacote gravador (ex.: `record`) e da
    permissão `RECORD_AUDIO` no manifest + solicitação em runtime.
  - Se a gravação for ativada: adicionar `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`,
    integrar o gravador ao `AudioRepository`, e tratar recusa de permissão mantendo o app funcional.
  - Se a captação ficar para depois: manter apenas reprodução (`just_audio`) e documentar que
    a gravação não está exposta no Android neste release.
  - _Validação:_ teste de fumaça de gravação em dispositivo real (não verificável headless).

---

## 6. Ícone e splash  [BAIXO RISCO / OPCIONAL]

- [ ] 6.1 Substituir o ícone padrão do Flutter
  - Gerar `mipmap` do ícone do Ritmo (manualmente ou via `flutter_launcher_icons`).
  - Ajustar `launch_background.xml`/tema se for personalizar o splash.

---

## Ordem sugerida
1. Tarefas 1 e 2 (desugaring + manifest) — destravam um build de notificações correto.
2. Tarefa 3 (minSdk/versão) — decisão consciente.
3. Tarefa 4 (assinatura) — exige o keystore do usuário; garantir `.gitignore` antes.
4. Tarefa 5 (áudio) — depende de decisão de produto sobre expor gravação.
5. Tarefa 6 (ícone/splash) — polimento.

## Notas
- Build Android requer SDK/NDK/JDK Android instalados; se ausentes nesta máquina, os passos de
  `flutter build` devem ser validados onde a toolchain existir.
- Segredos (keystore, senhas) nunca entram no git.
