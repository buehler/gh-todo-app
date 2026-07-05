import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_nav_rail.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:go_router/go_router.dart';

/// Authenticated shell: top bar + (bottom nav on compact/medium OR side
/// rail on wide) wrapped around the active branch from
/// [StatefulShellRoute.indexedStack].
///
/// The shell intentionally does NOT own a FAB — that concern belongs to the
/// individual branch screens (see `TodosFab` in `RootPage`).
class AppShell extends StatelessWidget {
  static const pageKey = ValueKey('app-shell');

  final StatefulNavigationShell navigationShell;
  final bool hideChromeOnCompact;

  const AppShell({
    required this.navigationShell,
    this.hideChromeOnCompact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final showCompactChrome = !wide && !hideChromeOnCompact;

    return Scaffold(
      key: pageKey,
      backgroundColor: resolveColor(context, ColorTokens.background.$default),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: wide
                ? Row(
                    children: [
                      AppNavRail(
                        currentIndex: navigationShell.currentIndex,
                        onTap: _onTap,
                      ),
                      Expanded(child: navigationShell),
                    ],
                  )
                : navigationShell,
          ),
          // On wide layouts the rail owns branding + identity, so the
          // top bar collapses entirely rather than leaving an empty
          // frosted strip.
          if (showCompactChrome)
            const Positioned(top: 0, left: 0, right: 0, child: AppTopBar()),
          if (showCompactChrome)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomNav(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTap,
              ),
            ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
