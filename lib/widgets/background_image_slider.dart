import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Mirrors `src/components/shared/BackgroundSlider.tsx`: a set of full-bleed
/// images that crossfade on a timer, used behind hero copy.
class BackgroundImageSlider extends StatefulWidget {
  const BackgroundImageSlider({
    super.key,
    required this.images,
    this.interval = const Duration(milliseconds: 5000),
  });

  final List<String> images;
  final Duration interval;

  @override
  State<BackgroundImageSlider> createState() => _BackgroundImageSliderState();
}

class _BackgroundImageSliderState extends State<BackgroundImageSlider> {
  int _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (mounted) setState(() => _active = (_active + 1) % widget.images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.expand();
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.images.length; i++)
          AnimatedOpacity(
            opacity: i == _active ? 1 : 0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            child: CachedNetworkImage(imageUrl: widget.images[i], fit: BoxFit.cover),
          ),
      ],
    );
  }
}
