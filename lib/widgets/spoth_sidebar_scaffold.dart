import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/nav_provider.dart';
import 'spoth_sidebar.dart';

class SpothSidebarScaffold extends ConsumerWidget {
  const SpothSidebarScaffold({
    super.key,
    required this.child,
    this.activeNavIndex = 1,
  });

  final Widget child;

  final int activeNavIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 900) {
      return child;
    }

    return Row(
      children: [
        SpothSidebar(
          index: activeNavIndex,
          expanded: width >= 1100,
          onChanged: (i) {
            ref.read(mainNavIndexProvider.notifier).setTab(i);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
