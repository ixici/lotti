import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lotti/utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'editor_db.g.dart';

@DriftDatabase(
  include: {'editor_db.drift'},
)
class EditorDb extends _$EditorDb {
  EditorDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> logInsight(Insight insight) async {
    return into(insights).insert(insight);
  }

  Future<void> captureEvent(
    dynamic event, {
    String domain = '',
    InsightLevel level = InsightLevel.info,
    InsightType type = InsightType.log,
  }) async {
    logInsight(Insight(
      id: uuid.v1(),
      createdAt: DateTime.now().toIso8601String(),
      domain: domain,
      message: event.toString(),
      level: level.name.toUpperCase(),
      type: type.name.toUpperCase(),
    ));
  }

  Stream<List<Insight>> watchInsights({
    int limit = 1000,
  }) {
    return latestEditorState(limit).watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'insights_db.sqlite'));
    return NativeDatabase(file);
  });
}
