import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/common.dart';
import '../../models/event_models.dart';
import '../../models/ticket_models.dart';
import '../../services/event_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton.dart';
import '../checkout/payment_verify_screen.dart';
import '../checkout/paystack_checkout_screen.dart';
import 'event_faq.dart';

typedef _Countdown = ({int days, int hours, int minutes, int seconds});

/// Mirrors `src/app/(attendee)/events/[slug]/EventDetailClient.tsx`'s real
/// (non-mock-only) sections, in the same top-to-bottom order the web page
/// uses at mobile width: hero + countdown, interested-avatars, organizer
/// card, about, gallery, highlights, reviews, location/online, lineup, FAQ.
/// Ticket purchase is a bottom-sheet modal here rather than an inline panel —
/// a deliberate native-app adaptation, not a web-order mismatch.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  LeanEventDetails? _details;
  EventOrganizerDto? _organizer;
  EventInterestDto? _interest;
  OrganizerRatingsDto? _ratings;
  bool _isSaved = false;
  bool _followBusy = false;
  String? _openFaq;

  _Countdown? _countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();

    final results = await Future.wait<dynamic>([
      eventService.getLeanEventDetails(token, widget.eventId),
      eventService.getEventOrganizer(token, widget.eventId),
      eventService.getEventInterest(token, widget.eventId),
    ]);
    if (!mounted) return;

    final detailsResponse = results[0] as ApiResponse<LeanEventDetails>?;
    final organizerResponse = results[1] as ApiResponse<EventOrganizerDto>?;
    final interestResponse = results[2] as ApiResponse<EventInterestDto>?;

    setState(() {
      _details = detailsResponse?.data;
      _organizer = organizerResponse?.data;
      _interest = interestResponse?.data;
      _isSaved = detailsResponse?.data?.isSavedByCurrentUser ?? false;
      _loading = false;
    });

    _startCountdown();
    final organizerId = _details?.organizerId;
    if (organizerId != null && organizerId.isNotEmpty) {
      _loadRatings(organizerId);
    }
  }

  Future<void> _loadRatings(String organizerId) async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getOrganizerRatings(token, organizerId);
    if (!mounted) return;
    setState(() => _ratings = response?.data);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final start = _details?.startDateTime;
    if (start == null) return;

    void tick() {
      final now = DateTime.now();
      if (!start.isAfter(now)) {
        setState(() => _countdown = null);
        return;
      }
      final diff = start.difference(now);
      setState(() {
        _countdown = (
          days: diff.inDays,
          hours: diff.inHours % 24,
          minutes: diff.inMinutes % 60,
          seconds: diff.inSeconds % 60,
        );
      });
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _toggleSave() async {
    setState(() => _isSaved = !_isSaved);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    await eventService.toggleSaveEvent(token, widget.eventId);
  }

  Future<void> _toggleFollow() async {
    if (_organizer == null || _followBusy) return;
    setState(() => _followBusy = true);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    await eventService.followOrganizer(token, _organizer!.organizerId);
    if (!mounted) return;
    setState(() {
      _organizer = EventOrganizerDto(
        organizerId: _organizer!.organizerId,
        organizerName: _organizer!.organizerName,
        organizerImageUrl: _organizer!.organizerImageUrl,
        followersCount:
            _organizer!.followersCount + (_organizer!.isFollowing ? -1 : 1),
        isFollowing: !_organizer!.isFollowing,
      );
      _followBusy = false;
    });
  }

  void _openTicketSheet() {
    if (_details == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TicketBookingSheet(
        eventId: widget.eventId,
        isFree: _details!.isFree,
      ),
    );
  }

  void _openShareSheet() {
    final d = _details;
    if (d == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShareSheet(
        eventId: widget.eventId,
        fallbackTitle: d.title,
        fallbackText: [
          d.title,
          '${DateFormat('EEE, MMM d').format(d.startDateTime)} · ${DateFormat.jm().format(d.startDateTime)}',
          if (d.venue.displayLine.isNotEmpty) d.venue.displayLine,
        ].join(' · '),
        fallbackUrl: (d.shareUrl?.isNotEmpty ?? false)
            ? d.shareUrl!
            : 'https://qa.leviticks.com/event/${d.id}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: EventDetailPageSkeleton());
    }
    final d = _details;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.moveLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Event not found.',
            style: TextStyle(color: AppColors.gray400),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;
    final isOnline = d.isOnline;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                (d.bannerImageUrl?.isNotEmpty ??
                        d.coverImageUrl?.isNotEmpty ??
                        false)
                    ? CachedNetworkImage(
                        imageUrl: (d.bannerImageUrl?.isNotEmpty ?? false)
                            ? d.bannerImageUrl!
                            : d.coverImageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.gray800,
                        child: const Icon(
                          LucideIcons.image,
                          color: AppColors.gray500,
                          size: 40,
                        ),
                      ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    bottom: false,
                    child: _circleIconButton(
                      LucideIcons.moveLeft,
                      () => context.pop(),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        _circleIconButton(LucideIcons.share2, _openShareSheet),
                        const SizedBox(width: 8),
                        _circleIconButton(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          _toggleSave,
                          color: _isSaved ? AppColors.rose : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.mainCategory?.isNotEmpty ?? d.categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      (d.mainCategory?.isNotEmpty ?? false)
                          ? d.mainCategory!
                          : d.categories.first,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  d.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(
                  LucideIcons.calendar,
                  DateFormat('EEEE, MMM d, y').format(d.startDateTime),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  LucideIcons.clock,
                  '${DateFormat.jm().format(d.startDateTime)} – ${DateFormat.jm().format(d.endDateTime)}',
                ),
                if (d.venue.displayLine.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(LucideIcons.mapPin, d.venue.fullAddressLine),
                ],
                const SizedBox(height: 16),
                _buildCountdown(),
                const SizedBox(height: 20),
                _buildInterestedBlock(),
                if (_organizer != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.gray200,
                          backgroundImage:
                              (_organizer!.organizerImageUrl?.isNotEmpty ??
                                  false)
                              ? CachedNetworkImageProvider(
                                  _organizer!.organizerImageUrl!,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _organizer!.organizerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${_organizer!.followersCount} followers',
                                style: const TextStyle(
                                  color: AppColors.gray400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _toggleFollow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _organizer!.isFollowing
                                ? AppColors.gray500
                                : AppColors.primary,
                            side: BorderSide(
                              color: _organizer!.isFollowing
                                  ? borderColor
                                  : AppColors.primary,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _organizer!.isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'About this event',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  d.description,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                if (d.gallery.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Photo Gallery',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _buildGallery(d),
                ],
                if (d.eventHighlights.isNotEmpty ||
                    (d.whatToExpect?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'What to Expect',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _buildHighlights(d, borderColor),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Organizer Reviews',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                _buildReviews(borderColor),
                const SizedBox(height: 20),
                Text(
                  isOnline ? 'Online Event' : 'Location & Directions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                isOnline
                    ? _buildOnlineCard(borderColor)
                    : _buildLocationCard(d, borderColor),
                if (d.lineup.any((e) => !e.appointementCanclled)) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Lineup',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _buildLineup(d),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                _buildFaqs(d, isOnline, borderColor),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            if (!d.isFree)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FROM',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      d.hasMaximumCapacity && d.maxCapacity != null
                          ? '${d.soldTicketsCount}/${d.maxCapacity} sold'
                          : 'Tickets available',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Text(
                  'Free Event',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.success,
                  ),
                ),
              ),
            SizedBox(
              width: 170,
              child: PrimaryButton(
                label: isOnline ? 'Book Seat' : 'Get Tickets',
                icon: LucideIcons.ticket,
                onPressed: _openTicketSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    final c = _countdown;
    if (c == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.clock, size: 14, color: AppColors.rose),
            SizedBox(width: 8),
            Text(
              'Event has passed',
              style: TextStyle(
                color: AppColors.rose,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        _countdownPill('${c.days}', 'Days'),
        const SizedBox(width: 8),
        _countdownPill('${c.hours}', 'Hrs'),
        const SizedBox(width: 8),
        _countdownPill('${c.minutes}', 'Mins'),
        const SizedBox(width: 8),
        _countdownPill('${c.seconds}', 'Secs'),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'until doors open',
            style: TextStyle(color: AppColors.gray400, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _countdownPill(String value, String label) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            value.padLeft(2, '0'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestedBlock() {
    final interest = _interest;
    final count = interest?.interestedCount ?? _details?.favoriteCount;
    if (count == null) return const SizedBox.shrink();
    final people = interest?.people ?? const [];
    return Row(
      children: [
        if (people.isNotEmpty)
          SizedBox(
            width: 20.0 * (people.length > 4 ? 4 : people.length) + 8,
            height: 28,
            child: Stack(
              children: [
                for (var i = 0; i < people.length && i < 4; i++)
                  Positioned(
                    left: i * 20.0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context)
                          .scaffoldBackgroundColor,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.gray200,
                        backgroundImage:
                            (people[i].imageUrl?.isNotEmpty ?? false)
                            ? CachedNetworkImageProvider(people[i].imageUrl!)
                            : null,
                        child: (people[i].imageUrl?.isNotEmpty ?? false)
                            ? null
                            : const Icon(
                                LucideIcons.user,
                                size: 12,
                                color: AppColors.gray400,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Text(
            count == 0
                ? 'Be the first to save this event'
                : '${NumberFormat.decimalPattern().format(count)} ${count == 1 ? 'person' : 'people'} interested',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(LeanEventDetails d) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: d.gallery.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: CachedNetworkImage(
            imageUrl: d.gallery[i].imageUrl,
            width: 176,
            height: 112,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildHighlights(LeanEventDetails d, Color borderColor) {
    if (d.eventHighlights.isEmpty) {
      return Text(
        d.whatToExpect!.trim(),
        style: const TextStyle(
          color: AppColors.gray500,
          fontSize: 13,
          height: 1.6,
        ),
      );
    }
    return Column(
      children: [
        for (final h in d.eventHighlights)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _highlightIcon(h.icon),
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (h.details?.trim().isNotEmpty ?? false)
                        Text(
                          h.details!.trim(),
                          style: const TextStyle(
                            color: AppColors.gray400,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _highlightIcon(String? name) {
    switch (name) {
      case 'music':
        return LucideIcons.music;
      case 'users':
        return LucideIcons.users;
      case 'star':
        return LucideIcons.star;
      case 'utensils':
        return LucideIcons.utensils;
      case 'camera':
        return LucideIcons.camera;
      case 'gift':
        return LucideIcons.gift;
      default:
        return LucideIcons.sparkles;
    }
  }

  Widget _buildReviews(Color borderColor) {
    final ratings = _ratings;
    if (ratings == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AppSkeleton(width: 96, height: 18),
            SizedBox(width: 10),
            AppSkeleton(width: 60, height: 12),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              children: List.generate(5, (i) {
                final filled = i + 1 <= ratings.averageRating.round();
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.amber,
                  size: 18,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              ratings.averageRating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 4),
            Text(
              '(${ratings.totalReviews} reviews)',
              style: const TextStyle(color: AppColors.gray400, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ratings.randomReviews.isEmpty)
          const Text(
            'No reviews yet.',
            style: TextStyle(color: AppColors.gray400, fontSize: 13),
          )
        else
          for (final r in ratings.randomReviews)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.gray200,
                        backgroundImage:
                            (r.reviewerImageUrl?.isNotEmpty ?? false)
                            ? CachedNetworkImageProvider(r.reviewerImageUrl!)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatReviewDate(r.dateReviewed),
                              style: const TextStyle(
                                color: AppColors.gray400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i + 1 <= r.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.amber,
                            size: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      r.comment,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    r.eventName,
                    style: const TextStyle(
                      color: AppColors.gray400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  String _formatReviewDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    return parsed != null ? DateFormat('MMM yyyy').format(parsed) : raw;
  }

  Widget _buildOnlineCard(Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.video,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This is an online event',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Join from anywhere. The link to join is in your ticket confirmation email.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LeanEventDetails d, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: isDark ? AppColors.gray800 : AppColors.gray100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _MapGridPainter(isDark: isDark),
                ),
                const Icon(
                  LucideIcons.mapPin,
                  color: AppColors.primary,
                  size: 28,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.venue.displayLine.isNotEmpty
                        ? d.venue.displayLine
                        : 'Location TBD',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineup(LeanEventDetails d) {
    final lineup = d.lineup.where((e) => !e.appointementCanclled).toList();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: lineup.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final item = lineup[i];
          return Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gray200,
                backgroundImage: (item.imageUrl?.isNotEmpty ?? false)
                    ? CachedNetworkImageProvider(item.imageUrl!)
                    : null,
                child: (item.imageUrl?.isNotEmpty ?? false)
                    ? null
                    : const Icon(LucideIcons.user, color: AppColors.gray400),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 70,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFaqs(LeanEventDetails d, bool isOnline, Color borderColor) {
    final faqs = buildEventFaqs(d, isOnline);
    return Column(
      children: [
        for (final faq in faqs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(
                    () => _openFaq = _openFaq == faq.$1 ? null : faq.$1,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          _openFaq == faq.$1
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.gray400,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_openFaq == faq.$1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.$2,
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _circleIconButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: CircleAvatar(
        radius: 17,
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        child: IconButton(
          icon: Icon(icon, size: 16, color: color),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// Decorative grid backdrop for the location placeholder — mirrors the
/// static inline-SVG "fake map" `EventDetailClient.tsx` uses (no real map
/// library/lat-lng usage there either).
class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 20.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

Map<String, String> _fallbackShareChannels({
  required String url,
  required String text,
  required String title,
}) {
  final textWithUrl = Uri.encodeComponent('$text $url');
  final encodedText = Uri.encodeComponent(text);
  final encodedUrl = Uri.encodeComponent(url);
  final encodedTitle = Uri.encodeComponent(title);
  return {
    'whatsapp': 'https://wa.me/?text=$textWithUrl',
    'x': 'https://twitter.com/intent/tweet?text=$encodedText&url=$encodedUrl',
    'facebook': 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
    'linkedin':
        'https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl',
    'telegram': 'https://t.me/share/url?url=$encodedUrl&text=$encodedText',
    'email': 'mailto:?subject=$encodedTitle&body=$textWithUrl',
  };
}

/// Mirrors the share panel inside `EventDetailClient.tsx`'s ticket card:
/// lazily fetches `EventShareDto` on open, falls back to locally-built
/// channel links if that hasn't loaded, and records a share on every tap.
class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.eventId,
    required this.fallbackTitle,
    required this.fallbackText,
    required this.fallbackUrl,
  });

  final String eventId;
  final String fallbackTitle;
  final String fallbackText;
  final String fallbackUrl;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  EventShareDto? _share;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getEventShare(token, widget.eventId);
    if (!mounted) return;
    setState(() => _share = response?.data);
  }

  String get _url =>
      (_share?.url.isNotEmpty ?? false) ? _share!.url : widget.fallbackUrl;
  String get _text =>
      (_share?.text.isNotEmpty ?? false) ? _share!.text : widget.fallbackText;
  String get _title => (_share?.title.isNotEmpty ?? false)
      ? _share!.title
      : widget.fallbackTitle;

  Map<String, String> get _channels => (_share?.channels.isNotEmpty ?? false)
      ? _share!.channels
      : _fallbackShareChannels(url: _url, text: _text, title: _title);

  Future<void> _record() async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.recordEventShare(token, widget.eventId);
    if (response?.data != null && mounted) {
      setState(() => _share = response!.data);
    }
  }

  Future<void> _openChannel(String url) async {
    if (url.isEmpty) return;
    unawaited(_record());
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _url));
    unawaited(_record());
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _nativeShare() async {
    unawaited(_record());
    await SharePlus.instance.share(
      ShareParams(title: _title, text: '$_text $_url'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = _channels;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Event',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _shareTile(
                'WhatsApp',
                LucideIcons.messageCircle,
                const Color(0xFF25D366),
                borderColor,
                () => _openChannel(channels['whatsapp'] ?? ''),
              ),
              _shareTile(
                'X',
                LucideIcons.x,
                isDark ? Colors.white : Colors.black,
                borderColor,
                () => _openChannel(channels['x'] ?? ''),
              ),
              _shareTile(
                'Facebook',
                LucideIcons.globe,
                const Color(0xFF1877F2),
                borderColor,
                () => _openChannel(channels['facebook'] ?? ''),
              ),
              _shareTile(
                'LinkedIn',
                LucideIcons.briefcase,
                const Color(0xFF0A66C2),
                borderColor,
                () => _openChannel(channels['linkedin'] ?? ''),
              ),
              _shareTile(
                'Telegram',
                LucideIcons.send,
                const Color(0xFF26A5E4),
                borderColor,
                () => _openChannel(channels['telegram'] ?? ''),
              ),
              _shareTile(
                'Email',
                LucideIcons.mail,
                AppColors.gray500,
                borderColor,
                () => _openChannel(channels['email'] ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _nativeShare,
                  icon: const Icon(LucideIcons.share2, size: 15),
                  label: const Text('More'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: Icon(
                    _copied ? LucideIcons.check : LucideIcons.link,
                    size: 15,
                  ),
                  label: Text(_copied ? 'Copied!' : 'Copy Link'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareTile(
    String label,
    IconData icon,
    Color color,
    Color borderColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketBookingSheet extends StatefulWidget {
  const _TicketBookingSheet({required this.eventId, required this.isFree});

  final String eventId;
  final bool isFree;

  @override
  State<_TicketBookingSheet> createState() => _TicketBookingSheetState();
}

class _TicketBookingSheetState extends State<_TicketBookingSheet> {
  bool _loading = true;
  List<TicketTypeDto> _types = [];
  final Map<String, int> _quantities = {};
  bool _booking = false;
  String? _error;
  BookTicketResponse? _result;

  bool _isGift = false;
  final _recipientEmail = TextEditingController();
  final _recipientName = TextEditingController();
  Timer? _lookupDebounce;
  bool _lookupBusy = false;
  RecipientLookupResponse? _lookupResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _recipientEmail.dispose();
    _recipientName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getTicketTypes(token, widget.eventId);
    if (!mounted) return;
    setState(() {
      _types = response?.data ?? [];
      _loading = false;
    });
  }

  int get _totalQuantity => _quantities.values.fold(0, (a, b) => a + b);
  double get _totalAmount => _types.fold(
    0,
    (sum, t) => sum + (t.price ?? 0) * (_quantities[t.ticketTypeId] ?? 0),
  );

  bool get _giftValid =>
      !_isGift ||
      (_recipientEmail.text.trim().contains('@') &&
          _recipientName.text.trim().isNotEmpty);

  void _onRecipientEmailChanged(String value) {
    _lookupDebounce?.cancel();
    setState(() => _lookupResult = null);
    final email = value.trim();
    if (!email.contains('@')) return;
    _lookupDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _lookupBusy = true);
      final auth = context.read<AuthProvider>();
      final eventService = context.read<EventService>();
      final token = await auth.getValidAccessToken();
      final response = await eventService.lookupRecipient(token, email);
      if (!mounted) return;
      setState(() {
        _lookupBusy = false;
        _lookupResult = response?.data;
        if (_lookupResult?.found ?? false) {
          _recipientName.text = _lookupResult!.fullName;
        }
      });
    });
  }

  Future<void> _book() async {
    if (_totalQuantity == 0 || !_giftValid) return;
    setState(() {
      _booking = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final token = await auth.getValidAccessToken();
    final response = await eventService.bookTicket(
      token,
      BookTicketRequestModel(
        eventId: widget.eventId,
        ticketTypes: _quantities.entries
            .where((e) => e.value > 0)
            .map((e) => BookTicketItem(ticketTypeId: e.key, quantity: e.value))
            .toList(),
        recipient: _isGift
            ? TicketRecipient(
                fullName: _recipientName.text.trim(),
                email: _recipientEmail.text.trim(),
              )
            : null,
      ),
    );
    if (!mounted) return;
    final data = response?.data;
    if (response?.statusCode != ApiResponse.successCode || data == null) {
      setState(() {
        _booking = false;
        _error = response?.message ?? 'Booking failed. Please try again.';
      });
      return;
    }
    if (data.requiresPayment) {
      final reference = await rootNavigator.push<String>(
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutScreen(
            checkoutUrl: data.checkoutUrl!,
            paymentReference: data.paymentReference ?? data.bookingId,
          ),
        ),
      );
      if (!mounted) return;
      setState(() => _booking = false);
      if (reference == null) {
        final cancelToken = await auth.getValidAccessToken();
        await eventService.cancelCheckout(
          cancelToken,
          data.paymentReference ?? data.bookingId,
        );
        if (mounted) {
          AppToast.show(
            context,
            message: 'Payment was cancelled.',
            success: false,
          );
        }
        return;
      }
      Navigator.of(context).pop();
      rootNavigator.push(
        MaterialPageRoute(
          builder: (_) => PaymentVerifyScreen(reference: reference),
        ),
      );
      return;
    }

    setState(() {
      _booking = false;
      _result = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _loading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 130, height: 17),
                SizedBox(height: 16),
                _TicketTypeRowSkeleton(),
                SizedBox(height: 12),
                _TicketTypeRowSkeleton(),
              ],
            )
          : _result != null
          ? _buildSuccess()
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Tickets',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (_types.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No ticket types available.',
                        style: TextStyle(color: AppColors.gray400),
                      ),
                    )
                  else
                    ..._types.map(_ticketRow),
                  const SizedBox(height: 6),
                  _buildGiftSection(),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.rose,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        widget.isFree
                            ? 'Free'
                            : '₦${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: widget.isFree
                        ? 'Confirm Booking'
                        : 'Checkout · $_totalQuantity ticket${_totalQuantity == 1 ? '' : 's'}',
                    isLoading: _booking,
                    onPressed: (_totalQuantity == 0 || !_giftValid)
                        ? null
                        : _book,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGiftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isGift = !_isGift),
          child: Row(
            children: [
              Checkbox(
                value: _isGift,
                onChanged: (v) => setState(() => _isGift = v ?? false),
              ),
              const Text(
                'This is a gift',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
        if (_isGift) ...[
          const SizedBox(height: 6),
          TextField(
            controller: _recipientEmail,
            keyboardType: TextInputType.emailAddress,
            onChanged: _onRecipientEmailChanged,
            decoration: InputDecoration(
              hintText: "Recipient's email",
              suffixIcon: _lookupBusy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          if (_lookupResult?.found ?? false)
            Row(
              children: [
                const Icon(
                  LucideIcons.userCheck,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Matched account: ${_lookupResult!.fullName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _recipientName,
              decoration: const InputDecoration(
                hintText: "Recipient's full name",
              ),
            ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 44),
        const SizedBox(height: 12),
        const Text(
          'Booking confirmed!',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Your tickets are ready in My Tickets.',
          style: const TextStyle(color: AppColors.gray400, fontSize: 13),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'View My Tickets',
          onPressed: () {
            Navigator.pop(context);
            context.go('/my-tickets');
          },
        ),
      ],
    );
  }

  Widget _ticketRow(TicketTypeDto type) {
    final qty = _quantities[type.ticketTypeId] ?? 0;
    final cap = type.maxPerOrder ?? 10;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  (type.price ?? 0) == 0
                      ? 'Free'
                      : '₦${(type.price ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: qty > 0
                ? () => setState(() => _quantities[type.ticketTypeId] = qty - 1)
                : null,
            icon: const Icon(LucideIcons.minus, size: 16),
          ),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            onPressed: qty < cap
                ? () => setState(() => _quantities[type.ticketTypeId] = qty + 1)
                : null,
            icon: const Icon(LucideIcons.plus, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Matches `_TicketBookingSheetState._ticketRow`'s shape, shown while the
/// ticket types are still loading.
class _TicketTypeRowSkeleton extends StatelessWidget {
  const _TicketTypeRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 90, height: 13),
                SizedBox(height: 6),
                AppSkeleton(width: 50, height: 12),
              ],
            ),
          ),
          AppSkeleton(width: 70, height: 28, borderRadius: BorderRadius.circular(AppRadius.md)),
        ],
      ),
    );
  }
}
