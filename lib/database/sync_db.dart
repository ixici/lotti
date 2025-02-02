import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lotti/blocs/sync/outbox_state.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'sync_db.g.dart';

@DataClassName('OutboxItem')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(Constant(DateTime.now()))();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(Constant(DateTime.now()))();

  IntColumn get status =>
      integer().withDefault(Constant(OutboxStatus.pending.index))();

  IntColumn get retries => integer().withDefault(const Constant(0))();
  TextColumn get message => text()();
  TextColumn get subject => text()();
  TextColumn get filePath => text().named('file_path').nullable()();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sync.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Outbox])
class SyncDatabase extends _$SyncDatabase {
  SyncDatabase() : super(_openConnection());

  Future<int> updateOutboxItem(OutboxCompanion item) {
    return (update(outbox)..where((t) => t.id.equals(item.id.value)))
        .write(item);
  }

  Future<int> addOutboxItem(OutboxCompanion entry) {
    return into(outbox).insert(entry);
  }

  Future<List<OutboxItem>> get allOutboxItems => select(outbox).get();

  Future<List<OutboxItem>> oldestOutboxItems(int limit) {
    return (select(outbox)
          ..where((t) => t.status.equals(OutboxStatus.pending.index))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<OutboxItem>> watchOutboxItems({
    int limit = 1000,
    List<OutboxStatus> statuses = const [
      OutboxStatus.pending,
      OutboxStatus.error,
      OutboxStatus.sent,
    ],
  }) {
    return (select(outbox)
          ..where(
            (t) => t.status
                .isIn(statuses.map((OutboxStatus status) => status.index)),
          )
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                )
          ])
          ..limit(limit))
        .watch();
  }

  @override
  int get schemaVersion => 1;
}
