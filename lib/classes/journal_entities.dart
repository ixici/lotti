import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lotti/classes/entity_definitions.dart';
import 'package:lotti/classes/entry_text.dart';
import 'package:lotti/classes/geolocation.dart';
import 'package:lotti/classes/health.dart';
import 'package:lotti/classes/task.dart';
import 'package:lotti/sync/vector_clock.dart';
import 'package:research_package/model.dart';

part 'journal_entities.freezed.dart';
part 'journal_entities.g.dart';

enum EntryFlag {
  none,
  import,
  followUpNeeded,
}

@freezed
class Metadata with _$Metadata {
  factory Metadata({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime dateFrom,
    required DateTime dateTo,
    List<String>? tags,
    List<String>? tagIds,
    int? utcOffset,
    String? timezone,
    VectorClock? vectorClock,
    DateTime? deletedAt,
    EntryFlag? flag,
    bool? starred,
    bool? private,
  }) = _Metadata;

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);
}

@freezed
class ImageData with _$ImageData {
  factory ImageData({
    required DateTime capturedAt,
    required String imageId,
    required String imageFile,
    required String imageDirectory,
    Geolocation? geolocation,
  }) = _ImageData;

  factory ImageData.fromJson(Map<String, dynamic> json) =>
      _$ImageDataFromJson(json);
}

@freezed
class AudioData with _$AudioData {
  factory AudioData({
    required DateTime dateFrom,
    required DateTime dateTo,
    required String audioFile,
    required String audioDirectory,
    required Duration duration,
    String? transcript,
  }) = _AudioData;

  factory AudioData.fromJson(Map<String, dynamic> json) =>
      _$AudioDataFromJson(json);
}

@freezed
class SurveyData with _$SurveyData {
  factory SurveyData({
    required RPTaskResult taskResult,
    required Map<String, Set<String>> scoreDefinitions,
    required Map<String, int> calculatedScores,
  }) = _SurveyData;

  factory SurveyData.fromJson(Map<String, dynamic> json) =>
      _$SurveyDataFromJson(json);
}

@freezed
class JournalEntity with _$JournalEntity {
  factory JournalEntity.journalEntry({
    required Metadata meta,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = JournalEntry;

  const factory JournalEntity.journalImage({
    required Metadata meta,
    required ImageData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = JournalImage;

  const factory JournalEntity.journalAudio({
    required Metadata meta,
    required AudioData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = JournalAudio;

  const factory JournalEntity.task({
    required Metadata meta,
    required TaskData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = Task;

  const factory JournalEntity.quantitative({
    required Metadata meta,
    required QuantitativeData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = QuantitativeEntry;

  const factory JournalEntity.measurement({
    required Metadata meta,
    required MeasurementData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = MeasurementEntry;

  const factory JournalEntity.workout({
    required Metadata meta,
    required WorkoutData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = WorkoutEntry;

  const factory JournalEntity.habitCompletion({
    required Metadata meta,
    required HabitCompletionData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = HabitCompletionEntry;

  const factory JournalEntity.survey({
    required Metadata meta,
    required SurveyData data,
    EntryText? entryText,
    Geolocation? geolocation,
  }) = SurveyEntry;

  factory JournalEntity.fromJson(Map<String, dynamic> json) =>
      _$JournalEntityFromJson(json);
}
