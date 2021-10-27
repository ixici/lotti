import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wisely/blocs/sync/classes.dart';
import 'package:wisely/blocs/sync/encryption_cubit.dart';
import 'package:wisely/blocs/sync/imap_cubit.dart';
import 'package:wisely/classes/sync_message.dart';
import 'package:wisely/sync/encryption.dart';
import 'package:wisely/sync/encryption_salsa.dart';

import 'outbound_queue_state.dart';

class OutboundQueueCubit extends Cubit<OutboundQueueState> {
  late final EncryptionCubit _encryptionCubit;
  late final ImapCubit _imapCubit;
  late final Future<Database> _database;
  late SyncConfig? _syncConfig;
  late String? _b64Secret;

  OutboundQueueCubit({
    required EncryptionCubit encryptionCubit,
    required ImapCubit imapCubit,
  }) : super(OutboundQueueState.initial()) {
    _encryptionCubit = encryptionCubit;
    _imapCubit = imapCubit;
    openDb();
  }

  Future<void> openDb() async {
    String createDbStatement =
        await rootBundle.loadString('assets/sqlite/create_outbound_db.sql');
    emit(OutboundQueueState.loading());

    String dbPath = join(await getDatabasesPath(), 'outbound.db');
    print('OutboundQueueCubit DB Path: ${dbPath}');

    _database = openDatabase(
      dbPath,
      onCreate: (db, version) async {
        List<String> scripts = createDbStatement.split(";");
        scripts.forEach((v) {
          if (v.isNotEmpty) {
            print(v.trim());
            db.execute(v.trim());
          }
        });
      },
      version: 1,
    );
    SyncConfig? syncConfig = await _encryptionCubit.loadSyncConfig();

    if (syncConfig != null) {
      _syncConfig = syncConfig;
      _b64Secret = syncConfig.sharedSecret;
    }
    emit(OutboundQueueState.online());
    _startPolling();
  }

  Future<void> insert(
    String encryptedMessage,
    String subject, {
    String? encryptedFilePath,
  }) async {
    final db = await _database;

    OutboundQueueRecord dbRecord = OutboundQueueRecord(
      encryptedMessage: encryptedMessage,
      encryptedFilePath: encryptedFilePath,
      subject: subject,
      status: OutboundMessageStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.insert(
      'outbound',
      dbRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(
    OutboundQueueRecord prev,
    OutboundMessageStatus status,
  ) async {
    final db = await _database;

    OutboundQueueRecord dbRecord = OutboundQueueRecord(
      encryptedMessage: prev.encryptedMessage,
      subject: prev.subject,
      status: status,
      createdAt: prev.createdAt,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'outbound',
      dbRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void _startPolling() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      print(timer.tick.toString());
    });
  }

  Future<List<OutboundQueueRecord>> entries() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query('outbound');

    return List.generate(maps.length, (i) {
      return OutboundQueueRecord.fromMap(maps[i]);
    });
  }

  Future<void> enqueueSyncMessage(
    SyncMessage syncMessage, {
    File? attachment,
  }) async {
    String jsonString = json.encode(syncMessage);
    String subject = syncMessage.vectorClock.toString();

    if (_b64Secret != null) {
      String encryptedMessage = encryptSalsa(jsonString, _b64Secret);
      if (attachment != null) {
        int fileLength = attachment.lengthSync();
        if (fileLength > 0) {
          File encryptedFile = File('${attachment.path}.aes');
          await encryptFile(attachment, encryptedFile, _b64Secret!);
          await insert(
            encryptedMessage,
            subject,
            encryptedFilePath: encryptedFile.path,
          );
        }
      } else {
        await insert(encryptedMessage, subject);
      }

      await _imapCubit.saveEncryptedImap(
        syncMessage,
        attachment: attachment,
      );
    }
  }
}
