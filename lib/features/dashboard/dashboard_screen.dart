import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/event_models.dart';
import '../../services/event_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/background_image_slider.dart';
import '../../widgets/event_image_card.dart';
import '../../widgets/featured_carousel.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reveal.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../shell/app_top_bar.dart';

const _defaultImage = 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&auto=format';

/// Mirrors `src/lib/heroImages.ts`, plus the brand's own concert photo.
const _heroBackgroundImages = [
  'https://res.cloudinary.com/dvoez6mj2/image/upload/v1789201488/concert_mobile_nnjz95.png',
  'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1400&auto=format',
  'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=1400&auto=format',
  'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=1400&auto=format',
  'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=1400&auto=format',
];

const _categoryTiles = [
  (label: 'Music', icon: LucideIcons.music, color: Color(0xFFEC4899)),
  (label: 'Technology', icon: LucideIcons.cpu, color: Color(0xFF3B82F6)),
  (label: 'Art & Culture', icon: LucideIcons.palette, color: Color(0xFFA855F7)),
  (label: 'Food & Drink', icon: LucideIcons.utensils, color: Color(0xFFF97316)),
  (label: 'Workshops', icon: LucideIcons.pencilRuler, color: Color(0xFF14B8A6)),
  (label: 'Sports', icon: LucideIcons.trophy, color: Color(0xFF22C55E)),
];

/// Mirrors `src/app/(attendee)/dashboard/page.tsx`.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _firstName;
  NextEventDto? _nextEvent;
  List<EventApiResponse> _trending = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();

    final results = await Future.wait([
      eventService.getAllEvents(token, EventQueryParams(pageSize: 6, currentPage: 1)),
      eventService.getNextEvent(token),
      auth.loadProfile(),
    ]);
    if (!mounted) return;

    final eventsResponse = results[0] as dynamic;
    final nextEventResponse = results[1] as dynamic;

    setState(() {
      _trending = (eventsResponse?.data?.items as List<EventApiResponse>?) ?? [];
      _nextEvent = nextEventResponse?.data as NextEventDto?;
      _firstName = auth.profile?.firstName ?? auth.profile?.email;
      _loading = false;
    });
  }

  Future<void> _toggleSave(String eventId) async {
    if (eventId.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    await eventService.toggleSaveEvent(token, eventId);
  }

  EventCardModel _toCardModel(EventApiResponse e) {
    return EventCardModel(
      slug: e.id,
      title: e.title,
      imageUrl: (e.coverImageUrl?.trim().isNotEmpty ?? false) ? e.coverImageUrl! : _defaultImage,
      category: e.categories.isNotEmpty ? e.categories.first : e.eventType,
      date: DateFormat('EEE, MMM d').format(e.startDateTime).toUpperCase(),
      time: DateFormat.jm().format(e.startDateTime),
      location: e.venue.displayLine,
      organizerName: e.organizerName,
      organizerImageUrl: e.organizerImageUrl ?? _defaultImage,
      price: e.isFree ? 'Free' : (e.hasMaximumCapacity && e.maxCapacity != null ? '${e.soldTicketsCount}/${e.maxCapacity} seats' : ''),
      description: e.shortDescription ?? e.description,
      isLikedByCurrentUser: e.isLikedByCurrentUser,
      isSavedByCurrentUser: e.isSavedByCurrentUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppTopBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHero(isDark),
            const SizedBox(height: 28),
            Reveal(child: _buildNextEvent(isDark)),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Trending Now',
                    icon: LucideIcons.flame,
                    iconColor: AppColors.orange500,
                    actionLabel: 'See all',
                    onAction: () => context.go('/explore'),
                  ),
                  const SizedBox(height: 12),
                  _buildTrending(),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: _loading
                  ? AppSkeleton(height: 220, borderRadius: BorderRadius.circular(AppRadius.md))
                  : FeaturedCarousel(
                      events: _trending.take(3).map(_toCardModel).toList(),
                      onTap: (event) => context.push('/event/${event.slug}'),
                    ),
            ),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Browse by Category', icon: LucideIcons.layoutGrid),
                  const SizedBox(height: 12),
                  _buildCategoryGrid(isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: BackgroundImageSlider(images: _heroBackgroundImages)),
            Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.45))),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Good evening${_firstName != null ? ', $_firstName' : ''} 👋',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'What are you doing\nthis weekend?',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Explore Events',
                      icon: LucideIcons.search,
                      expand: false,
                      onPressed: () => context.go('/explore'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextEvent(bool isDark) {
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your Next Event',
          icon: LucideIcons.ticket,
          actionLabel: 'All tickets',
          onAction: () => context.go('/my-tickets'),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: _loading
              ? Row(
                  children: [
                    AppSkeleton(width: 52, height: 52, borderRadius: BorderRadius.circular(AppRadius.md)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton(width: double.infinity, height: 13),
                          SizedBox(height: 8),
                          AppSkeleton(width: 120, height: 11),
                        ],
                      ),
                    ),
                  ],
                )
              : _nextEvent == null
                  ? Row(
                      children: [
                        const Icon(LucideIcons.calendarX, size: 20, color: AppColors.gray400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/explore'),
                            child: const Text.rich(
                              TextSpan(
                                text: 'No upcoming events. ',
                                style: TextStyle(color: AppColors.gray400, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'Explore events',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat.MMM().format(_nextEvent!.eventDate).toUpperCase(),
                                style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${_nextEvent!.eventDate.day}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nextEvent!.eventName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEE, h:mm a').format(_nextEvent!.eventDate),
                                style: const TextStyle(color: AppColors.gray400, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/event/${_nextEvent!.eventId}'),
                          icon: const Icon(LucideIcons.chevronRight, size: 18),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildTrending() {
    if (_loading) {
      return SizedBox(
        height: 306,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const SizedBox(width: 220, child: EventCardSkeleton()),
        ),
      );
    }
    if (_trending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No events yet.', style: TextStyle(color: AppColors.gray400))),
      );
    }
    return SizedBox(
      // Tall enough for EventImageCard's content at width 220, including a
      // 2-line title — it was overflowing at 250 (RenderFlex overflow) once
      // real event titles/venues replaced the previously-empty trending list.
      height: 306,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _trending.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final model = _toCardModel(_trending[i]);
          return SizedBox(
            width: 220,
            child: EventImageCard(
              event: model,
              onTap: () => context.push('/event/${model.slug}'),
              onToggleSave: (_) => _toggleSave(model.slug ?? ''),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categoryTiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, i) {
        final tile = _categoryTiles[i];
        return GestureDetector(
          onTap: () => context.go('/explore'),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: tile.color, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(tile.icon, size: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
