import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lotti/classes/entry_text.dart';
import 'package:lotti/get_it.dart';
import 'package:lotti/logic/persistence_logic.dart';
import 'package:lotti/services/nav_service.dart';
import 'package:lotti/utils/screenshots.dart';

class DesktopMenuWrapper extends StatelessWidget {
  DesktopMenuWrapper(
    this.body, {
    super.key,
  });

  final PersistenceLogic _persistenceLogic = getIt<PersistenceLogic>();
  final Widget body;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return body;
    }

    return PlatformMenuBar(
      body: body,
      menus: <MenuItem>[
        const PlatformMenu(
          label: 'Lotti',
          menus: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about,
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.servicesSubmenu,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.hide,
                ),
              ],
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit,
            ),
          ],
        ),
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'New Entry',
              onSelected: () async {
                final linkedId = await getIdFromSavedRoute();
                if (linkedId != null) {
                  await _persistenceLogic.createTextEntry(
                    EntryText(plainText: ''),
                    linkedId: linkedId,
                    started: DateTime.now(),
                  );
                } else {
                  pushNamedRoute('/journal/create/$linkedId');
                }
              },
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                meta: true,
              ),
            ),
            PlatformMenu(
              label: 'New ...',
              menus: [
                PlatformMenuItem(
                  label: 'Task',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyT,
                    meta: true,
                  ),
                  onSelected: () async {
                    final linkedId = await getIdFromSavedRoute();
                    pushNamedRoute('/tasks/create/$linkedId');
                  },
                ),
                PlatformMenuItem(
                  label: 'Screenshot',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyS,
                    meta: true,
                    alt: true,
                  ),
                  onSelected: () async {
                    await takeScreenshotWithLinked();
                  },
                ),
              ],
            ),
          ],
        ),
        const PlatformMenu(
          label: 'Edit',
          menus: [],
        ),
        const PlatformMenu(
          label: 'View',
          menus: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.toggleFullScreen,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow,
            ),
          ],
        ),
      ],
    );
  }
}
