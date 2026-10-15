import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/common.dart';
import '../../models/ticket_models.dart';
import '../../services/event_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/loading_and_empty.dart';
import '../../widgets/qr_pattern.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/ticket_qr_view.dart';
import '../shell/app_top_bar.dart';

/// Mirrors `src/app/(attendee)/my-tickets/page.tsx`.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  bool _loading = true;
  List<TicketItem> _all = [];
  String _activeTab = 'upcoming';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getMyTickets(token);
    if (!mounted) return;

    if (response?.statusCode == ApiResponse.successCode && response?.data != null) {
      final now = DateTime.now();
      final items = <TicketItem>[];
      for (final order in response!.data!) {
        for (final t in order.tickets) {
          final status = order.eventDateAndTime.isBefore(now)
              ? 'past'
              : t.status == 2
                  ? 'transferred'
                  : 'upcoming';
          items.add(TicketItem(
            eventTitle: order.eventName,
            imageUrl: order.eventImageUrl ?? '',
            eventDate: order.eventDateAndTime,
            venue: order.location,
            ticketType: t.ticketType,
            ticketCode: t.ticketNumber.isNotEmpty ? t.ticketNumber : t.ticketId,
            status: status,
            ticketId: t.ticketId,
          ));
        }
      }
      setState(() {
        _all = items;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  List<TicketItem> get _filtered => _all.where((t) => t.status == _activeTab).toList();

  int _count(String status) => _all.where((t) => t.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'My Tickets'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _tab('upcoming', 'Upcoming'),
                _tab('past', 'Past Events'),
                _tab('transferred', 'Transferred'),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    const TicketCardSkeleton(),
                  ],
                ],
              )
            else if (_filtered.isEmpty)
              const EmptyStateCard(
                icon: LucideIcons.ticket,
                title: 'No tickets found',
                subtitle: 'Tickets you book will show up here',
              )
            else
              Column(children: [for (final ticket in _filtered) _ticketCard(ticket)]),
          ],
        ),
      ),
    );
  }

  Widget _tab(String key, String label) {
    final active = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.gray400,
                ),
              ),
              const SizedBox(height: 2),
              Text('${_count(key)}', style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.gray400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketCard(TicketItem ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;
    final statusColor = ticket.status == 'past'
        ? StatusColors.past
        : ticket.status == 'transferred'
            ? StatusColors.transferred
            : StatusColors.upcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ticket.imageUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: ticket.imageUrl, fit: BoxFit.cover)
                    : Container(color: AppColors.gray200, child: const Icon(LucideIcons.image, color: AppColors.gray400)),
                Positioned(top: 8, left: 8, child: _dateBadge(ticket.eventDate)),
                Positioned(top: 8, right: 8, child: StatusPill(label: ticket.status, color: statusColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.eventTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: AppColors.gray400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(ticket.venue,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _infoBlock('DATE & TIME', DateFormat('MMM d, y · h:mm a').format(ticket.eventDate)),
                    ),
                    Expanded(child: _infoBlock('TICKET TYPE', '${ticket.ticketType} · ${ticket.ticketCode}')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => TicketQrFullscreenSheet.show(
                        context,
                        ticketId: ticket.ticketId ?? '',
                        ticketCode: ticket.ticketCode,
                        eventTitle: ticket.eventTitle,
                      ),
                      child: QrPatternView(code: ticket.ticketCode, size: 52, color: isDark ? Colors.white : AppColors.gray900),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/ticket/${ticket.ticketId}'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.gray800 : AppColors.gray900,
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.eye, size: 13, color: Colors.white),
                            SizedBox(width: 6),
                            Text('View Ticket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBadge(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(DateFormat.MMM().format(date).toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1)),
          Text('${date.day}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gray900, height: 1.2)),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
