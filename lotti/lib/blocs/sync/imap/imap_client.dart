import 'package:enough_mail/enough_mail.dart';
import 'package:lotti/classes/config.dart';
import 'package:lotti/database/insights_db.dart';
import 'package:lotti/main.dart';
import 'package:lotti/services/sync_config_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<ImapClient?> createImapClient() async {
  final SyncConfigService _syncConfigService = getIt<SyncConfigService>();
  final InsightsDb _insightsDb = getIt<InsightsDb>();
  SyncConfig? syncConfig = await _syncConfigService.getSyncConfig();
  final transaction = Sentry.startTransaction('createImapClient()', 'task');

  try {
    if (syncConfig != null) {
      ImapConfig imapConfig = syncConfig.imapConfig;
      ImapClient imapClient = ImapClient(isLogEnabled: false);

      await imapClient.connectToServer(
        imapConfig.host,
        imapConfig.port,
        isSecure: true,
      );
      await imapClient.login(imapConfig.userName, imapConfig.password);
      await imapClient.selectInbox();

      imapClient.eventBus.on<ImapEvent>().listen((ImapEvent imapEvent) async {
        _insightsDb.captureEvent(imapEvent, domain: 'IMAP_CLIENT');
      });

      return imapClient;
    } else {
      throw Exception('missing IMAP config');
    }
  } catch (e, stackTrace) {
    await Sentry.captureException(e, stackTrace: stackTrace);
  }
  await transaction.finish();
}
