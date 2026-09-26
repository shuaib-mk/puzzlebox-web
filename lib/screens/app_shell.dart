import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'unified_stats_screen.dart';
import 'loading_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isLoading = true;
  int index = 0;
  final pages = const [
    HomeScreen(),
    UnifiedStatsScreen(embedded: true),
    SettingsScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return LoadingScreen(
        onFinished: () {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: KeyedSubtree(
          key: ValueKey<int>(index),
          child: pages[index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: const Border(
            top: BorderSide(
              color: Colors.black,
              width: 2.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined, color: isDark ? Colors.white : Colors.black),
              selectedIcon: Icon(Icons.grid_view_rounded, color: isDark ? Colors.white : Colors.black),
              label: 'Play',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: isDark ? Colors.white : Colors.black),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: isDark ? Colors.white : Colors.black),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, color: isDark ? Colors.white : Colors.black),
              selectedIcon: Icon(Icons.tune_rounded, color: isDark ? Colors.white : Colors.black),
              label: 'Settings',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline_rounded, color: isDark ? Colors.white : Colors.black),
              selectedIcon: Icon(Icons.info_rounded, color: isDark ? Colors.white : Colors.black),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}
