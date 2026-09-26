import 'dart:async';
import 'package:flutter/material.dart';

/// App-wide Neo-Brutalist floating top toast notification card.
class NeoToast {
  static OverlayEntry? _currentEntry;

  /// Shows a clean top notification card with smooth slide animation.
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_rounded,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? theme.colorScheme.primary;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _NeoToastCard(
          message: message,
          icon: icon,
          cardColor: cardColor,
          isDark: isDark,
          duration: duration,
          onDismiss: () {
            entry.remove();
            if (_currentEntry == entry) {
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _NeoToastCard extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color cardColor;
  final bool isDark;
  final Duration duration;
  final VoidCallback onDismiss;

  const _NeoToastCard({
    required this.message,
    required this.icon,
    required this.cardColor,
    required this.isDark,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_NeoToastCard> createState() => _NeoToastCardState();
}
class _NeoToastCardState extends State<_NeoToastCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    _dismissTimer?.cancel();
    if (!_controller.isAnimating && _controller.status == AnimationStatus.dismissed) {
      return;
    }
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 14;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: true,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: IgnorePointer(
                  ignoring: false,
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(3.5, 3.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black, width: 1.8),
                              ),
                              child: Icon(widget.icon, size: 18, color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: widget.isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _dismiss,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: widget.isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
