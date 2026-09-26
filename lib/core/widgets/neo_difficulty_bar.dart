import 'package:flutter/material.dart';

/// Neo-Brutalist Difficulty Selector & Next Control Bar used across all game practice modes.
class NeoDifficultyBar extends StatelessWidget {
  final String currentDifficulty;
  final ValueChanged<String> onDifficultyChanged;
  final VoidCallback onNextPressed;
  final List<String> difficulties;

  const NeoDifficultyBar({
    super.key,
    required this.currentDifficulty,
    required this.onDifficultyChanged,
    required this.onNextPressed,
    this.difficulties = const ['Easy', 'Medium', 'Hard'],
  });

  Color _getDifficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4ADE80); // Lime Green
      case 'medium':
        return const Color(0xFFFACC15); // Yellow
      case 'hard':
        return const Color(0xFFF43F5E); // Rose Pink
      default:
        return const Color(0xFF38BDF8); // Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: difficulties.map((d) {
                  final isSelected = d.toLowerCase() == currentDifficulty.toLowerCase();
                  final diffColor = _getDifficultyColor(d);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PressableScale(
                      onTap: () => onDifficultyChanged(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? diffColor
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black,
                            width: isSelected ? 2.2 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(2.5, 2.5),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: diffColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 1.0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              d,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                color: isSelected
                                    ? Colors.black
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onNextPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2.5, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.skip_next_rounded, size: 18, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PressableScale({super.key, required this.child, required this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
