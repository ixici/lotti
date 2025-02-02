import 'package:flutter/material.dart';
import 'package:flutter_sliding_tutorial/flutter_sliding_tutorial.dart';
import 'package:lotti/pages/settings/sync/tutorial_utils.dart';
import 'package:lotti/widgets/sync/imap_config.dart';

class SyncAssistantConfigSlide extends StatelessWidget {
  const SyncAssistantConfigSlide(
    this.page,
    this.pageCount,
    this.notifier, {
    super.key,
  });

  final int page;
  final int pageCount;
  final ValueNotifier<double> notifier;

  @override
  Widget build(BuildContext context) {
    return SlidingPage(
      page: page,
      notifier: notifier,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SyncAssistantHeaderWidget(
            index: page,
            pageCount: pageCount,
          ),
          Align(
            child: SlidingContainer(
              child: const ImapConfigWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
