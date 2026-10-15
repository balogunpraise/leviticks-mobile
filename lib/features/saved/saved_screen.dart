import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/common.dart';
import '../../models/event_models.dart';
import '../../services/event_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/event_image_card.dart';
import '../../widgets/loading_and_empty.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton.dart';
import '../shell/app_top_bar.dart';

const _defaultImage = 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=600&auto=format';

/// Mirrors `src/app/(attendee)/saved/SavedClient.tsx`: a paged grid of the
/// user's saved events, with a client-side "unsave" that updates in place.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  static const _pageSize = 12;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<EventCardModel> _events = [];
  int _currentPage = 1;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  EventCardModel _mapToCard(EventApiResponse e) {
    final venue = e.venue;
    final location = venue.name != null && venue.name!.isNotEmpty
        ? venue.displayLine
        : (e.eventType.toLowerCase() == 'online' ? 'Online Event' : 'Location TBD');
    final category = e.mainCategory ?? (e.categories.isNotEmpty ? e.categories.first : 'General');
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
      price: e.isFree ? 'Free' : '',
      description: e.shortDescription ?? e.description,
      isSavedByCurrentUser: true,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getSavedEvents(token, pageSize: _pageSize, currentPage: 1);
    if (!mounted) return;

    if (response?.statusCode == ApiResponse.successCode && response?.data != null) {
      setState(() {
        _events = response!.data!.items.map(_mapToCard).toList();
        _currentPage = response.data!.currentPage;
        _hasNextPage = response.data!.hasNextPage;
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load saved events';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNextPage) return;
    setState(() => _loadingMore = true);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getSavedEvents(token, pageSize: _pageSize, currentPage: _currentPage + 1);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (response?.statusCode == ApiResponse.successCode && response?.data != null) {
        _events = [..._events, ...response!.data!.items.map(_mapToCard)];
        _currentPage = response.data!.currentPage;
        _hasNextPage = response.data!.hasNextPage;
      }
    });
  }

  Future<void> _unsave(EventCardModel event) async {
    setState(() => _events = _events.where((e) => e.slug != event.slug).toList());
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    await eventService.toggleSaveEvent(token, event.slug ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Saved Events'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const EventCardGridSkeleton()
            else if (_error != null)
              EmptyStateCard(
                icon: LucideIcons.circleAlert,
                title: 'Failed to load saved events',
                subtitle: _error,
                actionLabel: 'Try again',
                onAction: _load,
              )
            else if (_events.isEmpty)
              const EmptyStateCard(
                icon: LucideIcons.heart,
                title: 'Nothing saved yet',
                subtitle: 'Tap the heart on any event to save it here.',
              )
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, i) {
                  final event = _events[i];
                  return EventImageCard(
                    event: event,
                    onTap: () => context.push('/event/${event.slug}'),
                    onToggleSave: (saved) {
                      if (!saved) _unsave(event);
                    },
                  );
                },
              ),
              if (_hasNextPage) ...[
                const SizedBox(height: 16),
                PrimaryButton(label: 'Load more', isLoading: _loadingMore, expand: false, onPressed: _loadMore),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
