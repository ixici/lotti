import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:lotti/classes/geolocation.dart';
import 'package:lotti/classes/journal_entities.dart';
import 'package:lotti/sync/vector_clock.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum ConflictStatus {
  unprocessed,
  resolved,
}

@DriftDatabase(
  include: {'database.drift'},
)
class JournalDb extends _$JournalDb {
  JournalDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> addJournalDbEntity(JournalDbEntity entry) async {
    return into(journal).insert(entry);
  }

  Future<int> addConflict(Conflict conflict) async {
    return into(conflicts).insert(conflict);
  }

  Future<int?> addJournalEntity(JournalEntity journalEntity) async {
    JournalDbEntity dbEntity = toDbEntity(journalEntity);

    bool exists = (await entityById(dbEntity.id)) != null;
    if (!exists) {
      return addJournalDbEntity(dbEntity);
    } else {
      debugPrint('PersistenceDb already exists: ${dbEntity.id}');
    }
  }

  JournalDbEntity toDbEntity(JournalEntity journalEntity) {
    final DateTime createdAt = journalEntity.meta.createdAt;
    final subtype = journalEntity.maybeMap(
      quantitative: (qd) => qd.data.dataType,
      survey: (SurveyEntry surveyEntry) =>
          surveyEntry.data.taskResult.identifier,
      orElse: () => '',
    );

    Geolocation? geolocation;
    journalEntity.mapOrNull(
      journalAudio: (item) => geolocation = item.geolocation,
      journalImage: (item) => geolocation = item.geolocation,
      journalEntry: (item) => geolocation = item.geolocation,
    );

    String id = journalEntity.meta.id;
    JournalDbEntity dbEntity = JournalDbEntity(
      id: id,
      createdAt: createdAt,
      updatedAt: createdAt,
      dateFrom: journalEntity.meta.dateFrom,
      dateTo: journalEntity.meta.dateTo,
      type: journalEntity.runtimeType.toString(),
      subtype: subtype,
      serialized: json.encode(journalEntity),
      schemaVersion: 0,
      longitude: geolocation?.longitude,
      latitude: geolocation?.latitude,
      geohashString: geolocation?.geohashString,
    );

    return dbEntity;
  }

  JournalEntity fromDbEntity(JournalDbEntity dbEntity) {
    return JournalEntity.fromJson(json.decode(dbEntity.serialized));
  }

  Future<VclockStatus> detectConflict(
    JournalEntity existing,
    JournalEntity updated,
  ) async {
    VectorClock? vcA = existing.meta.vectorClock;
    VectorClock? vcB = updated.meta.vectorClock;

    if (vcA != null && vcB != null) {
      VclockStatus status = VectorClock.compare(vcA, vcB);

      if (status == VclockStatus.concurrent) {
        debugPrint('Conflicting vector clocks: $status');
        DateTime now = DateTime.now();
        await addConflict(Conflict(
          id: updated.meta.id,
          createdAt: now,
          updatedAt: now,
          serialized: jsonEncode(updated),
          schemaVersion: schemaVersion,
          status: ConflictStatus.unprocessed.index,
        ));
      }

      return status;
    }
    return VclockStatus.b_gt_a;
  }

  Future<int> updateJournalEntity(JournalEntity updated) async {
    int rowsAffected = 0;
    JournalDbEntity dbEntity = toDbEntity(updated).copyWith(
      updatedAt: DateTime.now(),
    );

    JournalDbEntity? existingDbEntity = await entityById(dbEntity.id);
    if (existingDbEntity != null) {
      JournalEntity existing = fromDbEntity(existingDbEntity);
      VclockStatus status = await detectConflict(existing, updated);

      if (status == VclockStatus.b_gt_a) {
        rowsAffected = await (update(journal)
              ..where((t) => t.id.equals(dbEntity.id)))
            .write(dbEntity);
      }
    } else {
      rowsAffected = await addJournalDbEntity(dbEntity);
    }
    return rowsAffected;
  }

  Future<List<JournalDbEntity>> latestDbEntities(int limit) async {
    return (select(journal)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.dateFrom,
                  mode: OrderingMode.desc,
                )
          ])
          ..limit(limit))
        .get();
  }

  Future<JournalDbEntity?> entityById(String id) async {
    List<JournalDbEntity> res =
        await (select(journal)..where((t) => t.id.equals(id))).get();
    if (res.isNotEmpty) {
      return res.first;
    }
  }

  Future<List<JournalEntity>> latestJournalEntities(int limit) async {
    List<JournalDbEntity> dbEntities = await latestDbEntities(limit);
    return dbEntities.map(fromDbEntity).toList();
  }

  Future<List<JournalEntity>> filteredJournalEntities({
    required List<String> types,
    required int limit,
  }) async {
    var dbEntities = await filteredJournal(types, 100).get();
    return dbEntities.map(fromDbEntity).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
