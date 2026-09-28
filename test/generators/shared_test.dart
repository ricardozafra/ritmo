import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import 'shared.dart';

void main() {
  group('RitmoGlados', () {
    test('fixa ao menos 100 execuções e uma semente reproduzível', () {
      final first = RitmoGlados.ci();
      final second = RitmoGlados.ci();

      expect(first.numRuns, 100);
      expect(first.random.nextInt(1 << 31), second.random.nextInt(1 << 31));
      expect(() => RitmoGlados.ci(runs: 99), throwsArgumentError);
    });
  });

  group('geradores compartilhados', () {
    test('todos produzem valores válidos com a API glados fixada', () {
      final random = Random(7);
      const size = 100;

      expect(anyOperationalDate(random, size).value, isA<OperationalDate>());
      expect(anyInstant(random, size).value.civilInstant.isUtc, isTrue);
      expect(
        anySettings(random, size).value.dayCloseTime.minutesFromMidnight,
        inInclusiveRange(0, 240),
      );
      expect(anyTimeline(random, size).value.days, isNotEmpty);
      expect(anyDayState(random, size).value.effectiveResult, isNotNull);
      expect(
        anyPillarState(random, size).value.completed.length,
        inInclusiveRange(0, 3),
      );
      expect(anyStudyBlockSeq(random, size).value, isNotEmpty);
      expect(anyUnicodeText(random, size).value.boundary, 500);
      expect(anyMarkdown(random, size).value, isNotEmpty);
      expect(anyContactList(random, size).value, isA<List<ContactFixture>>());
      expect(anyDeviceZone(random, size).value.zoneId, isNotEmpty);
      expect(anyFailurePoint(random, size).value.writeIndex, isNonNegative);
    });

    test('datas incluem bordas semanais, mensais e anuais', () {
      final random = Random(11);
      final values = [
        for (var i = 0; i < 400; i++) anyOperationalDate(random, 100).value,
      ];

      expect(values.any((date) => date.weekday == DateTime.monday), isTrue);
      expect(values.any((date) => date.weekday == DateTime.friday), isTrue);
      expect(values.any((date) => date.isWeekend), isTrue);
      expect(values.any((date) => date.day == 1), isTrue);
      expect(values.any((date) => date.month == 12 && date.day == 31), isTrue);
    });

    test('configurações geradas satisfazem RF-05.3 e RA-01.1', () {
      final random = Random(13);
      for (var i = 0; i < 100; i++) {
        final calendar = anySettings(random, 100).value;
        expect(
          calendar.dayCloseTime.minutesFromMidnight,
          inInclusiveRange(0, 4 * 60),
        );
        expect(calendar.nightOffset, greaterThan(Duration.zero));
        expect(
          calendar.nightOffset,
          lessThanOrEqualTo(OperationalCalendar.operationalDayLength),
        );
      }
    });

    test('instantes caem exatamente sobre a borda anunciada', () {
      final random = Random(17);
      for (var i = 0; i < 200; i++) {
        final fixture = anyInstant(random, 100).value;
        final calendar = fixture.calendar;
        final owner = calendar.operationalDateOf(fixture.civilInstant);
        switch (fixture.edge) {
          case TemporalEdge.beforeDayClose:
            expect(owner, fixture.date);
          case TemporalEdge.atDayClose:
          case TemporalEdge.afterDayClose:
            expect(owner, fixture.date.next);
          case TemporalEdge.atNightEnd:
            expect(
              fixture.civilInstant,
              calendar.blockDeadline(fixture.date).toCivilDateTime(),
            );
          case TemporalEdge.civilMidnight:
            expect(fixture.civilInstant.hour, 0);
            expect(fixture.civilInstant.minute, 0);
        }
      }
    });

    test('linhas do tempo atravessam fim de semana e terminam abertas', () {
      final random = Random(29);
      for (var i = 0; i < 100; i++) {
        final timeline = anyTimeline(random, 100).value;

        expect(timeline.days.any((day) => day.isMute), isTrue);
        expect(timeline.days.last.isClosed, isFalse);
        for (final day in timeline.days) {
          expect(day.isWorkday, !day.isMute);
          expect(day.isMute, day.muteCause != null);
          if (day.date.isWeekend) {
            expect(day.muteCause, FixtureMuteCause.weekend);
          }
        }
        // Datas contíguas e crescentes.
        for (var index = 1; index < timeline.days.length; index++) {
          expect(timeline.days[index].date, timeline.days[index - 1].date.next);
        }
      }
    });

    test('texto Unicode orbita n-1, n e n+1 em runes', () {
      final generator = unicodeTextAround(12);
      final random = Random(19);
      final lengths = <int>{
        for (var i = 0; i < 200; i++)
          generator(random, 100).value.text.runes.length,
      };

      expect(lengths, containsAll(<int>[11, 12, 13]));
    });

    test('estados de dia preservam as combinações válidas do design', () {
      final random = Random(23);
      for (var i = 0; i < 100; i++) {
        final state = anyDayState(random, 100).value;
        expect(
          state.effectiveResult == FixtureDayResult.mute,
          state.muteCause != null,
        );
        expect(
          state.baseResult == FixtureDayResult.sealed,
          state.sealTimestamp != null,
        );
        if (state.muteCause == FixtureMuteCause.holiday) {
          expect(state.previousResult, isNotNull);
        }
        if (state.muteCause == FixtureMuteCause.weekend) {
          expect(state.date.isWeekend, isTrue);
        }
      }
    });
  });

  group('dobras compartilhadas', () {
    test('FakeClock avança sem consultar relógio ou fuso do aparelho', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1));
      clock.advance(const Duration(hours: 2));

      expect(clock.now, DateTime.utc(2026, 1, 1, 2));
      expect(clock.deviceZoneDiverges, isFalse);
      clock.deviceZoneId = 'Asia/Tokyo';
      expect(clock.deviceZoneDiverges, isTrue);
    });

    test('FakeClock deriva a data operacional pelo day_close_time', () {
      // 02:59 de 06/01 ainda pertence à data operacional 05/01 (fechamento 03h).
      final clock = FakeClock(DateTime.utc(2026, 1, 6, 2, 59));
      expect(clock.operationalDate, OperationalDate(2026, 1, 5));
      expect(clock.civilMoment.time, const LocalTimeOfDay(2, 59));

      clock.advanceToOperationalClose();
      expect(clock.now, DateTime.utc(2026, 1, 6, 3));
      expect(clock.operationalDate, OperationalDate(2026, 1, 6));
    });

    test('InMemoryDatabase executa SQL drift sem arquivo real', () async {
      final database = await InMemoryDatabase.open();
      addTearDown(database.close);

      final rows = await database.select('SELECT 1 AS value', const []);
      expect(rows.single['value'], 1);
      expect(database.schemaVersion, 1);
    });

    test('InMemoryDatabase persiste schema, CHECK e chave estrangeira', () async {
      final database = await InMemoryDatabase.open();
      addTearDown(database.close);

      await database.execute(
        'CREATE TABLE days (operational_date TEXT NOT NULL PRIMARY KEY);',
      );
      await database.execute(
        'CREATE TABLE study_blocks ('
        'id TEXT NOT NULL PRIMARY KEY, '
        'operational_date TEXT NOT NULL REFERENCES days(operational_date), '
        'duration_minutes INTEGER NOT NULL CHECK (duration_minutes >= 0));',
      );
      await database.insert('INSERT INTO days VALUES (?);', const ['2026-01-05']);
      await database.insert('INSERT INTO study_blocks VALUES (?, ?, ?);', const [
        'block-1',
        '2026-01-05',
        45,
      ]);

      final rows = await database.select(
        'SELECT duration_minutes FROM study_blocks WHERE id = ?;',
        const ['block-1'],
      );
      expect(rows.single['duration_minutes'], 45);

      // CHECK rejeita duração negativa.
      await expectLater(
        database.insert('INSERT INTO study_blocks VALUES (?, ?, ?);', const [
          'block-2',
          '2026-01-05',
          -1,
        ]),
        throwsA(anything),
      );

      // PRAGMA foreign_keys ativo: data operacional inexistente é rejeitada.
      await expectLater(
        database.insert('INSERT INTO study_blocks VALUES (?, ?, ?);', const [
          'block-3',
          '2026-01-06',
          10,
        ]),
        throwsA(anything),
      );
    });

    test('InMemoryDatabase desfaz a transação inteira em caso de falha', () async {
      final database = await InMemoryDatabase.open();
      addTearDown(database.close);

      await database.execute('CREATE TABLE notes (id TEXT NOT NULL);');

      await expectLater(
        database.transaction((tx) async {
          await tx.runInsert('INSERT INTO notes VALUES (?);', const ['a']);
          throw StateError('falha simulada antes do commit');
        }),
        throwsStateError,
      );

      expect(await database.select('SELECT id FROM notes;'), isEmpty);

      await database.transaction(
        (tx) => tx.runInsert('INSERT INTO notes VALUES (?);', const ['b']),
      );
      expect(
        (await database.select('SELECT id FROM notes;')).single['id'],
        'b',
      );
    });

    test('RecordingNotificationGateway registra e cancela por chave', () async {
      final gateway = RecordingNotificationGateway();
      await gateway.schedule(
        key: 'daily:2026-01-05',
        scheduledFor: DateTime.utc(2026, 1, 5, 12),
      );
      await gateway.cancel('daily:2026-01-05');

      expect(gateway.scheduled, isEmpty);
      expect(gateway.cancelledKeys, ['daily:2026-01-05']);
    });

    test(
      'FakeFileStore respeita capacidade e não deixa escrita parcial',
      () async {
        final store = FakeFileStore(capacityBytes: 3);
        await store.write('ok', [1, 2, 3]);

        await expectLater(
          store.write('overflow', [4]),
          throwsA(isA<StorageFailure>()),
        );
        expect(store.read('ok'), [1, 2, 3]);
        expect(store.exists('overflow'), isFalse);
        expect(store.freeBytes, 0);
      },
    );

    test(
      'FakeAudioGateway simula reprodução, gravação e falta de espaço',
      () async {
        final audio = FakeAudioGateway(availableRecordingBytes: 8);
        await audio.playLocal('assets/audio/briefing.mp3');
        audio.advance(const Duration(seconds: 1));
        await audio.complete();

        expect(audio.playedAssets, ['assets/audio/briefing.mp3']);
        expect(audio.position, const Duration(seconds: 1));
        expect(audio.state, FakeAudioState.completed);
        await expectLater(
          audio.startRecording(requiredBytes: 9),
          throwsA(isA<AudioFailure>()),
        );
      },
    );
  });
}
