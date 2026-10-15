import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

/// Placeholder shapes shown while a page or its data loads, mirroring
/// `src/components/shared/Skeleton.tsx`'s `animate-pulse` boxes — each page
/// skeleton here matches that file's per-page shapes and proportions so
/// nothing jumps when the real content arrives.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.gray800 : AppColors.gray200;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }
}

Color _cardBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? AppColors.gray700 : AppColors.gray200;

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: _cardBorder(context)),
    );

/// Heading + subtitle block, matching `PageHeaderSkeleton`.
class PageHeaderSkeleton extends StatelessWidget {
  const PageHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(width: 180, height: 24),
        SizedBox(height: 10),
        AppSkeleton(width: 240, height: 14),
      ],
    );
  }
}

/// One event-card placeholder, matching `EventImageCard`'s proportions
/// (16:11 cover image, title lines, divider, organizer row).
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: AppSkeleton(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(width: 120, height: 12),
                const SizedBox(height: 8),
                const AppSkeleton(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                const AppSkeleton(width: 160, height: 12),
                const SizedBox(height: 10),
                Divider(height: 1, color: _cardBorder(context)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const AppSkeleton(width: 20, height: 20, borderRadius: BorderRadius.all(Radius.circular(10))),
                    const SizedBox(width: 8),
                    const Expanded(child: AppSkeleton(width: double.infinity, height: 11)),
                    const SizedBox(width: 10),
                    AppSkeleton(width: 70, height: 20, borderRadius: BorderRadius.circular(AppRadius.md)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A column of [EventCardSkeleton]s with gaps, for list-based pages
/// (Dashboard/Explore/Saved), matching `AttendeePageSkeleton`.
class EventCardListSkeleton extends StatelessWidget {
  const EventCardListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          const EventCardSkeleton(),
        ],
      ],
    );
  }
}

/// A 2-column grid of [EventCardSkeleton]s, matching the Saved page's
/// `GridView` (`crossAxisCount: 2`, `childAspectRatio: 0.66`).
class EventCardGridSkeleton extends StatelessWidget {
  const EventCardGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (_, _) => const EventCardSkeleton(),
    );
  }
}

/// Full attendee page skeleton: heading + a stack of event cards.
/// Matches `AttendeePageSkeleton` — used by Dashboard, Explore, Saved.
class AttendeePageSkeleton extends StatelessWidget {
  const AttendeePageSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeaderSkeleton(),
          const SizedBox(height: 20),
          EventCardListSkeleton(count: count),
        ],
      ),
    );
  }
}

/// A full ticket-card placeholder, matching `MyTicketsScreen._ticketCard`'s
/// layout: banner image, title/venue, a divider, two info blocks, then a
/// QR box beside a "View Ticket" button.
class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: double.infinity, height: 130, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(width: 180, height: 15),
                const SizedBox(height: 8),
                const AppSkeleton(width: 140, height: 12),
                const SizedBox(height: 10),
                Divider(height: 1, color: _cardBorder(context)),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton(width: 70, height: 9),
                          SizedBox(height: 6),
                          AppSkeleton(width: 100, height: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton(width: 70, height: 9),
                          SizedBox(height: 6),
                          AppSkeleton(width: 100, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AppSkeleton(width: 52, height: 52, borderRadius: BorderRadius.circular(AppRadius.md)),
                    const SizedBox(width: 12),
                    Expanded(child: AppSkeleton(height: 36, borderRadius: BorderRadius.circular(AppRadius.md))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single ticket's detail skeleton: banner + QR box + info lines.
/// Matches `TicketDetailSkeleton`.
class TicketDetailPageSkeleton extends StatelessWidget {
  const TicketDetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 110, height: 13),
          const SizedBox(height: 16),
          Container(
            decoration: _cardDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const AppSkeleton(width: double.infinity, height: 140, borderRadius: BorderRadius.zero),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const AppSkeleton(width: 170, height: 170, borderRadius: BorderRadius.all(Radius.circular(16))),
                      const SizedBox(height: 20),
                      const AppSkeleton(width: double.infinity, height: 18),
                      const SizedBox(height: 10),
                      const AppSkeleton(width: 180, height: 13),
                      const SizedBox(height: 8),
                      const AppSkeleton(width: 220, height: 13),
                      const SizedBox(height: 16),
                      AppSkeleton(width: 150, height: 40, borderRadius: BorderRadius.circular(AppRadius.full)),
                    ],
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

/// A rounded stat/info card placeholder: a label line + a bigger value line.
class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 48, height: 10),
          SizedBox(height: 10),
          AppSkeleton(width: 36, height: 20),
        ],
      ),
    );
  }
}

/// Event detail page skeleton: tall hero block over an image, then the
/// about card and a grid of info tiles. Matches `EventDetailSkeleton`.
class EventDetailPageSkeleton extends StatelessWidget {
  const EventDetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 240,
          color: AppColors.gray900,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          alignment: Alignment.bottomLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 220, height: 26, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 10),
              Container(width: 140, height: 14, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Container(width: 48, height: 44, decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    )),
                  ],
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 140, height: 16),
                    SizedBox(height: 12),
                    AppSkeleton(width: double.infinity, height: 12),
                    SizedBox(height: 8),
                    AppSkeleton(width: double.infinity, height: 12),
                    SizedBox(height: 8),
                    AppSkeleton(width: 200, height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: const [
                  _StatCardSkeleton(),
                  _StatCardSkeleton(),
                  _StatCardSkeleton(),
                  _StatCardSkeleton(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Calendar page skeleton: heading bar + 3 stat boxes + a tall grid block.
/// Matches the inline skeleton in `calendar/page.tsx`.
class CalendarPageSkeleton extends StatelessWidget {
  const CalendarPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 220, height: 40, borderRadius: BorderRadius.circular(AppRadius.md)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: AppSkeleton(height: 72, borderRadius: BorderRadius.circular(AppRadius.md))),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppSkeleton(width: double.infinity, height: 420, borderRadius: BorderRadius.circular(AppRadius.md)),
        ],
      ),
    );
  }
}

/// A single pulsing bar, matching `TwoFactorCard.tsx`'s loading state.
class InlineBarSkeleton extends StatelessWidget {
  const InlineBarSkeleton({super.key, this.height = 64});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(width: double.infinity, height: height, borderRadius: BorderRadius.circular(AppRadius.md));
  }
}

/// Neutral fallback for pages without a shaped skeleton of their own:
/// heading + a few content blocks. Matches `GenericPageSkeleton`.
class GenericPageSkeleton extends StatelessWidget {
  const GenericPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeaderSkeleton(),
          const SizedBox(height: 20),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(context),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 160, height: 14),
                  SizedBox(height: 10),
                  AppSkeleton(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  AppSkeleton(width: 220, height: 12),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
