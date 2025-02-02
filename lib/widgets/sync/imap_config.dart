import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lotti/widgets/sync/imap_config_actions.dart';
import 'package:lotti/widgets/sync/imap_config_form.dart';
import 'package:lotti/widgets/sync/imap_config_mobile.dart';
import 'package:lotti/widgets/sync/imap_config_status.dart';

class ImapConfigWidget extends StatefulWidget {
  const ImapConfigWidget({super.key});

  @override
  State<ImapConfigWidget> createState() => _ImapConfigWidgetState();
}

class _ImapConfigWidgetState extends State<ImapConfigWidget> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isAndroid) {
      return const MobileSyncConfig();
    }

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          ImapConfigForm(),
          SizedBox(height: 32),
          ImapConfigStatus(),
          SizedBox(height: 32),
          ImapConfigActions(),
        ],
      ),
    );
  }
}
