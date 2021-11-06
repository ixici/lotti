import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail/imap/mailbox.dart';
import 'package:enough_mail/mime_message.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wisely/classes/journal_db_entities.dart';
import 'package:wisely/classes/sync_message.dart';
import 'package:wisely/sync/encryption.dart';
import 'package:wisely/sync/encryption_salsa.dart';
import 'package:wisely/utils/audio_utils.dart';
import 'package:wisely/utils/image_utils.dart';

Future<void> saveAudioAttachment(
  MimeMessage message,
  JournalDbAudio? journalDbAudio,
  JournalDbEntity journalDbEntity,
  String? b64Secret,
) async {
  final transaction = Sentry.startTransaction('saveAudioAttachment()', 'task');
  final attachments =
      message.findContentInfo(disposition: ContentDisposition.attachment);

  for (final attachment in attachments) {
    final MimePart? attachmentMimePart = message.getPart(attachment.fetchId);
    if (attachmentMimePart != null &&
        journalDbAudio != null &&
        b64Secret != null) {
      Uint8List? bytes = attachmentMimePart.decodeContentBinary();
      String filePath = await AudioUtils.getFullAudioPath(journalDbAudio);
      await File(filePath).parent.create(recursive: true);
      File encrypted = File('$filePath.aes');
      debugPrint('saveAttachment $filePath');
      await writeToFile(bytes, encrypted.path);
      await decryptFile(encrypted, File(filePath), b64Secret);
      await AudioUtils.saveAudioNoteJson(journalDbAudio, journalDbEntity);
    }
  }
  await transaction.finish();
}

Future<void> saveImageAttachment(
  MimeMessage message,
  JournalDbImage? journalDbImage,
  JournalDbEntity journalDbEntity,
  String? b64Secret,
) async {
  final transaction = Sentry.startTransaction('saveImageAttachment()', 'task');
  final attachments =
      message.findContentInfo(disposition: ContentDisposition.attachment);

  for (final attachment in attachments) {
    final MimePart? attachmentMimePart = message.getPart(attachment.fetchId);
    if (attachmentMimePart != null &&
        journalDbImage != null &&
        b64Secret != null) {
      Uint8List? bytes = attachmentMimePart.decodeContentBinary();
      String filePath = await getFullImagePath(journalDbImage);
      await File(filePath).parent.create(recursive: true);
      File encrypted = File('$filePath.aes');
      debugPrint('saveAttachment $filePath');
      await writeToFile(bytes, encrypted.path);
      await decryptFile(encrypted, File(filePath), b64Secret);
      await saveJournalImageJson(journalDbImage, journalDbEntity);
    }
  }
  await transaction.finish();
}

Future<SyncMessage?> decryptMessage(
    String? encryptedMessage, MimeMessage message, String? b64Secret) async {
  if (encryptedMessage != null) {
    if (b64Secret != null) {
      String decryptedJson = decryptSalsa(encryptedMessage, b64Secret);
      return SyncMessage.fromJson(json.decode(decryptedJson));
    }
  }
}

String? readMessage(MimeMessage message) {
  message.parse();
  final plainText = message.decodeTextPlainPart();
  String concatenated = '';
  if (plainText != null) {
    final lines = plainText.split('\r\n');
    for (final line in lines) {
      if (line.startsWith('>')) {
        break;
      }
      concatenated = concatenated + line;
    }
    return concatenated.trim();
  }
}

Future<void> writeToFile(Uint8List? data, String filePath) async {
  if (data != null) {
    await File(filePath).writeAsBytes(data);
  } else {
    debugPrint('No bytes for $filePath');
  }
}

Future<GenericImapResult> saveImapMessage(
  ImapClient imapClient,
  String subject,
  String encryptedMessage, {
  File? file,
}) async {
  final transaction = Sentry.startTransaction('saveImapMessage()', 'task');
  Mailbox inbox = await imapClient.selectInbox();
  final builder = MessageBuilder.prepareMultipartAlternativeMessage();
  builder.from = [MailAddress('Sync', 'sender@domain.com')];
  builder.to = [MailAddress('Sync', 'recipient@domain.com')];
  builder.subject = subject;
  builder.addTextPlain(encryptedMessage);

  if (file != null) {
    int fileLength = file.lengthSync();
    if (fileLength > 0) {
      await builder.addFile(
          file, MediaType.fromText('application/octet-stream'));
    }
  }

  final MimeMessage message = builder.buildMimeMessage();
  GenericImapResult res =
      await imapClient.appendMessage(message, targetMailbox: inbox);
  debugPrint(
      'saveImapMessage responseCode ${res.responseCode} details ${res.details}');
  await transaction.finish();
  return res;
}