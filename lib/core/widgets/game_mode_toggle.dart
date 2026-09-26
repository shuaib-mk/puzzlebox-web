import 'package:flutter/material.dart';

enum GameMode { daily, practice }

class GameModeToggle extends StatelessWidget {
  final GameMode mode;
  final ValueChanged<GameMode> onModeChanged;
  final int practiceSolvedCount;

  const GameModeToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.practiceSolvedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Mode Segmented Capsule
          Container(
            height: 42,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeTab(
                  label: 'Daily',
                  isSelected: mode == GameMode.daily,
                  onTap: () => onModeChanged(GameMode.daily),
                ),
                _ModeTab(
                  label: 'Unlimited',
                  isSelected: mode == GameMode.practice,
                  onTap: () => onModeChanged(GameMode.practice),
                ),
              ],
            ),
          ),

          // Practice Session Counter Badge
          if (mode == GameMode.practice)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    'Solved: $practiceSolvedCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.black, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
