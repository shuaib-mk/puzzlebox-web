import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original, resolution-independent Puzzlebox character.
class PuzzlePal extends StatefulWidget {
  final double size;
  const PuzzlePal({super.key, this.size = 100});
  @override
  State<PuzzlePal> createState() => _PuzzlePalState();
}

class _PuzzlePalState extends State<PuzzlePal>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, child) => Transform.translate(
      offset: MediaQuery.disableAnimationsOf(context)
          ? Offset.zero
          : Offset(0, -3 * controller.value),
      child: child,
    ),
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: SvgPicture.asset(
          'assets/puzzlebox-logo.svg',
          width: widget.size,
          height: widget.size,
        ),
      ),
    ),
  );
}
