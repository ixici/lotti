import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotti/blocs/sync/sync_config_cubit.dart';
import 'package:lotti/theme.dart';
import 'package:lotti/widgets/sync/imap_config_status.dart';
import 'package:lotti/widgets/sync/qr_reader_widget.dart';
import 'package:lotti/widgets/sync/qr_widget.dart';

class MobileSyncConfig extends StatelessWidget {
  const MobileSyncConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncConfigCubit, SyncConfigState>(
      builder: (context, SyncConfigState state) {
        return Center(
          child: state.maybeWhen(
            configured: (imapConfig, sharedKey) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 88),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Host: ${imapConfig.host}',
                      style: labelStyleLarger,
                    ),
                    Text(
                      'Port: ${imapConfig.port}',
                      style: labelStyleLarger,
                    ),
                    Text(
                      'IMAP Folder: ${imapConfig.folder}',
                      style: labelStyleLarger,
                    ),
                    Text(
                      'User: ${imapConfig.userName}',
                      style: labelStyleLarger,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        DeleteSyncConfigButton(),
                        SizedBox(width: 16),
                        ImapConfigStatus(showText: false)
                      ],
                    ),
                  ],
                ),
              );
            },
            orElse: () {
              return const EncryptionQrReaderWidget();
            },
          ),
        );
      },
    );
  }
}
