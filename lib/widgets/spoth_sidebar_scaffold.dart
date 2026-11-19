import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/nav_provider.dart';
import 'nav_items.dart';
import 'spoth_sidebar.dart';

class SpothSidebarScaffold extends ConsumerWidget {
  const SpothSidebarScaffold({
    super.key,
    required this.child,
    this.activeTab = MainTab.tempat,
  });

  final Widget child;

  final MainTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 900) {
      return child;
    }

    final tabs = tabsForRole(ref.watch(authNotifierProvider).user);

    var index = tabs.indexOf(activeTab);
    if (index < 0) {
      index = tabs.indexOf(MainTab.tempat);
    }
    if (index < 0) {
      index = 0;
    }

    return Row(
      children: [
        SpothSidebar(
          index: index,
          items: [for (final tab in tabs) kNavItems[tab]!],
          expanded: width >= 1400,
          onChanged: (i) {
            ref.read(mainNavIndexProvider.notifier).setTab(tabs[i]);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
