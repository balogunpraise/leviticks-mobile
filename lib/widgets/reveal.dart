import 'package:flutter/material.dart';

/// Mirrors `src/components/shared/Reveal.tsx`: a fade + slide-up entrance
/// animation. The web version triggers on scroll-into-view via
/// IntersectionObserver; since mobile lists mount their sections up front,
/// this plays once on first build after an optional stagger delay, giving the
/// same "content settling in" feel as the page load.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = curved;
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: FractionalTranslation(translation: _offset.value, child: child),
      ),
      child: widget.child,
    );
  }
}
