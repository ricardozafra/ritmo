import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/audio_assets.dart';
import 'tables/change_initiatives.dart';
import 'tables/checkpoint_evals.dart';
import 'tables/checkpoints.dart';
import 'tables/contacts.dart';
import 'tables/cycle_closure_invites.dart';
import 'tables/cycles.dart';
import 'tables/days.dart';
import 'tables/holidays.dart';
import 'tables/manifests.dart';
import 'tables/mentorships.dart';
import 'tables/notification_plans.dart';
import 'tables/pillar_entries.dart';
import 'tables/pillar_waivers.dart';
import 'tables/protocol_alarms.dart';
import 'tables/settings.dart';
import 'tables/study_blocks.dart';
import 'tables/weekly_contact_suggestions.dart';
import 'tables/weekly_reviews.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Settings,
    Days,
    StudyBlocks,
    AudioAssets,
    ChangeInitiatives,
    PillarEntries,
    PillarWaivers,
    ProtocolAlarms,
    Holidays,
    Mentorships,
    Contacts,
    WeeklyContactSuggestions,
    Cycles,
    Checkpoints,
    WeeklyReviews,
    CheckpointEvals,
    CycleClosureInvites,
    Manifests,
    NotificationPlans,
  ],
)
final class RitmoDatabase extends _$RitmoDatabase {
  RitmoDatabase(super.executor);

  /// Banco de produção no diretório privado de suporte do aplicativo.
  factory RitmoDatabase.production({String fileName = 'ritmo.sqlite'}) {
    return RitmoDatabase(
      LazyDatabase(() async {
        final directory = await getApplicationSupportDirectory();
        final file = File(p.join(directory.path, fileName));
        return NativeDatabase.createInBackground(
          file,
          setup: (database) => database.execute('PRAGMA foreign_keys = ON;'),
        );
      }),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX waiver_one_active_per_day '
        'ON pillar_waivers(date) WHERE revoked_at IS NULL',
      );
      await customStatement(
        'CREATE UNIQUE INDEX protocol_one_live_per_generation '
        "ON protocol_alarms(generation_id) WHERE state <> 'invalidated'",
      );
      await customStatement(
        'CREATE INDEX protocol_pending_oldest '
        "ON protocol_alarms(start_date) WHERE state = 'pending'",
      );
      await customStatement(
        'CREATE UNIQUE INDEX cycle_one_active '
        "ON cycles(state) WHERE state = 'active'",
      );
      await customStatement(
        'CREATE UNIQUE INDEX initiative_one_active '
        'ON change_initiatives(active) WHERE active = 1',
      );
      await _seedV1();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
    },
  );

  Future<void> _seedV1() async {
    await batch((batch) {
      batch.insert(settings, const SettingsCompanion());
      batch.insert(
        cycles,
        CyclesCompanion.insert(
          id: 'cycle-seed-v1',
          name: 'Ciclo Junho/2027',
          purposeText:
              'Nível Avançado em Strategic Thinking, Innovative e Change Advocate até Junho/2027 + consolidação de Business Acumen',
          startDate: '2026-01-01',
          endDate: '2027-06-30',
          state: 'active',
        ),
      );
      for (final checkpoint in const [
        (
          id: 'checkpoint-seed-innovative',
          competency: 'IN',
          date: '2026-12-31',
        ),
        (
          id: 'checkpoint-seed-strategic-thinking',
          competency: 'ST',
          date: '2027-02-28',
        ),
        (
          id: 'checkpoint-seed-change-advocate',
          competency: 'CA',
          date: '2027-06-30',
        ),
      ]) {
        batch.insert(
          checkpoints,
          CheckpointsCompanion.insert(
            id: checkpoint.id,
            cycleId: 'cycle-seed-v1',
            competency: checkpoint.competency,
            date: checkpoint.date,
            status: 'pending',
          ),
        );
      }
      for (final competency in const ['ST', 'IN', 'CA']) {
        batch.insert(
          mentorships,
          MentorshipsCompanion.insert(
            id: 'mentorship-$competency',
            competency: competency,
          ),
        );
      }
    });
  }
}
