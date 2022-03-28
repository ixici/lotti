import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lotti/pages/settings/outbox_badge.dart';
import 'package:lotti/routes/router.gr.dart';
import 'package:lotti/theme.dart';
import 'package:lotti/widgets/audio/audio_recording_indicator.dart';
import 'package:lotti/widgets/bottom_nav/flagged_badge_icon.dart';
import 'package:lotti/widgets/bottom_nav/tasks_badge_icon.dart';
import 'package:lotti/widgets/misc/app_bar_version.dart';
import 'package:lotti/widgets/misc/time_recording_indicator.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      lazyLoad: false,
      animationDuration: const Duration(milliseconds: 500),
      appBarBuilder: (context, tabsRouter) => AppBar(
        backgroundColor: AppColors.headerBgColor,
        title: const VersionAppBar(title: 'Lotti'),
        centerTitle: true,
        leading: AutoBackButton(
          color: AppColors.entryTextColor,
        ),
      ),
      builder: (context, child, _) {
        return Container(
          color: AppColors.bodyBgColor,
          height: double.maxFinite,
          width: double.maxFinite,
          child: Stack(
            children: [
              child,
              const TimeRecordingIndicator(),
              const AudioRecordingIndicator(),
            ],
          ),
        );
      },
      backgroundColor: AppColors.bodyBgColor,
      routes: const [
        JournalRouter(),
        FlaggedRouter(),
        TasksRouter(),
        DashboardsRouter(),
        MyDayRouter(),
        SettingsRouter(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.headerBgColor,
          unselectedItemColor: AppColors.bottomNavIconUnselected,
          selectedItemColor: AppColors.bottomNavIconSelected,
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: FlaggedBadgeIcon(),
              label: 'Flagged',
            ),
            BottomNavigationBarItem(
              icon: TasksBadgeIcon(),
              label: 'Tasks',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline),
              label: 'Dashboards',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'My Day',
            ),
            BottomNavigationBarItem(
              icon: OutboxBadgeIcon(
                icon: const Icon(Icons.settings_outlined),
              ),
              label: 'Settings',
            ),
          ],
        );
      },
    );
  }
}