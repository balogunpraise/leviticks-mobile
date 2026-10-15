import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../models/event_models.dart';
import 'primary_button.dart';

/// Mirrors `src/components/shared/FeaturedCarousel.tsx`: an auto-advancing
/// carousel of featured events with a gradient scrim, dot indicators and
/// prev/next controls.
class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({
    super.key,
    required this.events,
    this.interval = const Duration(milliseconds: 6000),
    this.onTap,
  });

  final List<EventCardModel> events;
  final Duration interval;
  final void Function(EventCardModel event)? onTap;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  late final PageController _controller = PageController();
  int _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  void _scheduleAutoAdvance() {
    _timer?.cancel();
    if (widget.events.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) => _goTo(_active + 1));
  }

  void _goTo(int index) {
    if (!_controller.hasClients || widget.events.isEmpty) return;
    final next = index % widget.events.length;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.events.length,
              onPageChanged: (i) => setState(() => _active = i),
              itemBuilder: (context, i) => _Slide(event: widget.events[i], onTap: widget.onTap),
            ),
            if (widget.events.length > 1) ...[
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(child: _ArrowButton(icon: LucideIcons.chevronLeft, onTap: () => _goTo(_active - 1))),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(child: _ArrowButton(icon: LucideIcons.chevronRight, onTap: () => _goTo(_active + 1))),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.events.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _active ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _active ? Colors.white : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.event, this.onTap});

  final EventCardModel event;
  final void Function(EventCardModel event)? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(imageUrl: event.imageUrl, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.orange500.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 10, color: AppColors.orange500),
                    const SizedBox(width: 5),
                    Text(
                      'FEATURED EVENT',
                      style: TextStyle(color: AppColors.orange500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.15),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 11, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${event.date} · ${event.time}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: event.price.isNotEmpty ? 'Get Tickets · ${event.price}' : 'Get Tickets',
                expand: false,
                onPressed: () => onTap?.call(event),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
