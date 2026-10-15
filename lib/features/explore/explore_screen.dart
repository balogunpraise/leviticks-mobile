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
import '../../widgets/event_image_card.dart';
import '../../widgets/loading_and_empty.dart';
import '../../widgets/location_map_card.dart';
import '../../widgets/reveal.dart';
import '../../widgets/skeleton.dart';
import '../shell/app_top_bar.dart';

const _defaultImage = 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=600&auto=format';

const _categoryIcon = <String, IconData>{
  'Music': LucideIcons.music,
  'Technology': LucideIcons.cpu,
  'Art & Culture': LucideIcons.palette,
  'Food & Drink': LucideIcons.utensils,
  'Workshops': LucideIcons.pencilRuler,
};

/// Mirrors `src/app/(attendee)/explore/page.tsx`.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _loading = true;
  String? _error;
  List<EventCardModel> _allEvents = [];
  String _filterCategory = '';
  final String _sortBy = 'date-asc';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();

    final response = await eventService.getAllEvents(token, EventQueryParams(pageSize: 100, currentPage: 1));
    if (!mounted) return;

    if (response?.data?.items != null) {
      setState(() {
        _allEvents = response!.data!.items.map(_mapToCard).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load events';
        _loading = false;
      });
    }
  }

  Future<void> _toggleSave(String eventId) async {
    if (eventId.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    await eventService.toggleSaveEvent(token, eventId);
  }

  EventCardModel _mapToCard(EventApiResponse e) {
    final venue = e.venue;
    final location = venue.name != null && venue.name!.isNotEmpty
        ? venue.displayLine
        : (e.eventType.toLowerCase() == 'online' ? 'Online Event' : 'Location TBD');
    final category = e.mainCategory ?? (e.categories.isNotEmpty ? e.categories.first : 'General');
    final price = e.isFree
        ? 'Free'
        : (e.hasMaximumCapacity && e.maxCapacity != null ? 'Capacity: ${e.soldTicketsCount}/${e.maxCapacity}' : '');

    return EventCardModel(
      slug: e.id,
      title: e.title.isNotEmpty ? e.title : 'Untitled Event',
      imageUrl: (e.coverImageUrl?.trim().isNotEmpty ?? false) ? e.coverImageUrl! : _defaultImage,
      category: category,
      date: DateFormat('EEE, MMM d').format(e.startDateTime).toUpperCase(),
      time: DateFormat.jm().format(e.startDateTime),
      location: location,
      organizerName: e.organizerName,
      organizerImageUrl: e.organizerImageUrl ?? _defaultImage,
      price: price,
      description: e.shortDescription ?? e.description,
      isLikedByCurrentUser: e.isLikedByCurrentUser,
      isSavedByCurrentUser: e.isSavedByCurrentUser,
    );
  }

  List<String> get _categories => _allEvents.map((e) => e.category).toSet().toList()..sort();

  List<EventCardModel> get _filtered {
    var list = List<EventCardModel>.from(_allEvents);
    if (_filterCategory.isNotEmpty) list = list.where((e) => e.category == _filterCategory).toList();
    switch (_sortBy) {
      case 'name-asc':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'date-desc':
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      default:
        list.sort((a, b) => a.date.compareTo(b.date));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Explore Events'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Reveal(child: LocationMapCard()),
            const SizedBox(height: 16),
            Reveal(child: _buildCategoryChips()),
            const SizedBox(height: 16),
            if (_loading)
              const EventCardListSkeleton(count: 4)
            else if (_error != null)
              EmptyStateCard(
                icon: LucideIcons.circleAlert,
                title: 'Failed to load events',
                subtitle: _error,
                actionLabel: 'Try again',
                onAction: _load,
              )
            else if (_filtered.isEmpty)
              const EmptyStateCard(
                icon: LucideIcons.calendarX,
                title: 'No events found',
                subtitle: 'Try a different category',
              )
            else
              Reveal(
                delay: const Duration(milliseconds: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_filtered.length} event${_filtered.length == 1 ? '' : 's'} found',
                        style: const TextStyle(color: AppColors.gray400, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    // One full-width card per row (not a grid) — each card sizes to its own
                    // content height, and the whole list scrolls with the page's outer ListView.
                    for (final model in _filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: EventImageCard(
                            event: model,
                            onTap: () => context.push('/event/${model.slug}'),
                            onToggleSave: (_) => _toggleSave(model.slug ?? ''),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('All', LucideIcons.layoutGrid, _filterCategory == '', () => setState(() => _filterCategory = '')),
          const SizedBox(width: 8),
          for (final cat in _categories) ...[
            _chip(cat, _categoryIcon[cat] ?? LucideIcons.calendar, _filterCategory == cat,
                () => setState(() => _filterCategory = cat)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: active ? AppColors.primary : (isDark ? AppColors.gray700 : AppColors.gray200)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : AppColors.gray500),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}
