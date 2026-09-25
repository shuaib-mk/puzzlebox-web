import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/widgets/puzzle_pal.dart';

/// A Neo-Brutalist animated loading/splash screen displayed on app startup.
class LoadingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration duration;

  const LoadingScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _tileRotationController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnim;

  int _textIndex = 0;
  final _loadingSubtitles = const [
    'Initializing daily puzzles...',
    'Assembling word & logic grids...',
    'Preparing 15 offline games...',
    'Ready to play!',
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _tileRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final newIndex = (_progressAnim.value * (_loadingSubtitles.length - 1))
          .floor()
          .clamp(0, _loadingSubtitles.length - 1);
      if (newIndex != _textIndex) {
        setState(() => _textIndex = newIndex);
      }
    });

    _progressController.forward().then((_) {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _tileRotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F6F2);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final tileColors = [
      const Color(0xFF4ADE80), // Lime Green
      const Color(0xFFFACC15), // Sunflower Yellow
      const Color(0xFFF43F5E), // Rose Pink
      const Color(0xFF38BDF8), // Cyan
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Minimal Sleek App Icon Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3.5, 3.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 38,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 24),

                // Clean Minimal Title Typography
                Text(
                  'PUZZLEBOX',
                  style: TextStyle(
                    fontFamily: 'PuzzleSans',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 48),

                // Minimal Slim Progress Bar Container
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Container(
                          width: 200,
                          height: 10,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 1.8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnim.value.clamp(0.04, 1.0),
                              child: Container(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle Loading State Text
                        Text(
                          _loadingSubtitles[_textIndex],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .1,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
