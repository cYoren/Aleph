import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/reading')) return 1;
    if (location.startsWith('/bookmarks')) return 2;
    if (location.startsWith('/search')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/reading');
        break;
      case 2:
        context.go('/bookmarks');
        break;
      case 3:
        context.go('/search');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final destinations = [
      (Icons.home_outlined, Icons.home, l10n.home),
      (Icons.menu_book_outlined, Icons.menu_book, l10n.books),
      (Icons.bookmark_outline, Icons.bookmark, l10n.bookmarks),
      (Icons.search_outlined, Icons.search, l10n.search),
      (Icons.settings_outlined, Icons.settings, l10n.settings),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final selected = _calculateSelectedIndex(context);
        if (constraints.maxWidth < 720) {
          return Scaffold(
            body: widget.child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: [
                for (final (icon, selectedIcon, label) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selectedIcon),
                    label: label,
                  ),
              ],
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: NavigationRail(
                    minWidth: 112,
                    scrollable: true,
                    selectedIndex: selected,
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                    indicatorColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    onDestinationSelected: (index) =>
                        _onItemTapped(index, context),
                    destinations: [
                      for (final (icon, selectedIcon, label) in destinations)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(selectedIcon),
                          label: SizedBox(
                            width: 88,
                            child: Text(label, textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, content) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(content.maxWidth, content.maxHeight),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
