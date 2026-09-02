import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extension.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // The bar shows 5 destinations, but only 4 are real IndexedStack branches
  // (Game just pushes '/games' as a one-off flow, like starting a quiz) — so
  // UI position and branch index diverge after the Game slot and need mapping.
  static const _branchForUiIndex = {0: 0, 1: 1, 3: 2, 4: 3};
  static const _uiIndexForBranch = {0: 0, 1: 1, 2: 3, 3: 4};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _uiIndexForBranch[navigationShell.currentIndex] ?? 0,
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push('/games');
            return;
          }
          final branchIndex = _branchForUiIndex[index]!;
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.tr('navHome'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: context.tr('navCourses'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt),
            label: context.tr('navGame'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: context.tr('navProgress'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.tr('navProfile'),
          ),
        ],
      ),
    );
  }
}
