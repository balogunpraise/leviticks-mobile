import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/common.dart';
import '../../models/event_models.dart';
import '../../models/ticket_models.dart';
import '../../services/event_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/loading_and_empty.dart';
import '../../widgets/skeleton.dart';
import '../shell/app_top_bar.dart';
import 'calendar_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Mirrors `src/app/(attendee)/calendar/page.tsx` — a unified schedule built
/// by merging `getMyTicketsRequest` + `getSavedEventsRequest` client-side
/// (not a personal pinboard; every event shown is a real ticket or save).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum _SourceFilter { all, tickets, saved }

class _CalendarScreenState extends State<CalendarScreen> {
  final _today = _dateOnly(DateTime.now());
  late DateTime _viewDate = DateTime(_today.year, _today.month, 1);
  DateTime? _selectedDate;
  _SourceFilter _filter = _SourceFilter.all;

  bool _loading = true;
  List<CalendarEvent> _events = [];

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

    final results = await Future.wait<dynamic>([
      eventService.getMyTickets(token),
      eventService.getSavedEvents(token, pageSize: 100, currentPage: 1),
    ]);
    if (!mounted) return;

    final ticketsResponse = results[0] as ApiResponse<List<MyTicketOrder>>?;
    final savedResponse = results[1] as ApiResponse<EventsPagedResponse>?;

    final savedItems =
        (savedResponse?.statusCode == ApiResponse.successCode) ? savedResponse!.data?.items ?? <EventApiResponse>[] : <EventApiResponse>[];
    final savedIds = savedItems.map((e) => e.id).toSet();

    final merged = <String, CalendarEvent>{};
    if (ticketsResponse?.statusCode == ApiResponse.successCode) {
      for (final order in ticketsResponse!.data ?? []) {
        merged[order.eventId] = CalendarEvent(
          eventId: order.eventId,
          title: order.eventName,
          date: order.eventDateAndTime,
          venue: order.location,
          imageUrl: order.eventImageUrl,
          source: CalendarEventSource.ticket,
          isSaved: savedIds.contains(order.eventId),
          ticketId: order.tickets.isNotEmpty ? order.tickets.first.ticketId : null,
        );
      }
    }
    for (final e in savedItems) {
      merged.putIfAbsent(
        e.id,
        () => CalendarEvent(
          eventId: e.id,
          title: e.title,
          date: e.startDateTime,
          venue: e.venue.displayLine.isNotEmpty ? e.venue.displayLine : 'Location TBD',
          description: e.shortDescription ?? e.description,
          imageUrl: e.coverImageUrl,
          source: CalendarEventSource.saved,
          isSaved: true,
        ),
      );
    }

    setState(() {
      _events = merged.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      _loading = false;
    });
  }

  List<CalendarEvent> get _filteredEvents {
    switch (_filter) {
      case _SourceFilter.all:
        return _events;
      case _SourceFilter.tickets:
        return _events.where((e) => e.source == CalendarEventSource.ticket).toList();
      case _SourceFilter.saved:
        return _events.where((e) => e.isSaved).toList();
    }
  }

  List<CalendarEvent> _eventsOn(DateTime date) => _filteredEvents.where((e) => _isSameDay(e.date, date)).toList();

  List<DateTime> get _calendarCells {
    final first = DateTime(_viewDate.year, _viewDate.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  void _prevMonth() => setState(() {
        _viewDate = DateTime(_viewDate.year, _viewDate.month - 1, 1);
        _selectedDate = null;
      });
  void _nextMonth() => setState(() {
        _viewDate = DateTime(_viewDate.year, _viewDate.month + 1, 1);
        _selectedDate = null;
      });
  void _goToday() => setState(() {
        _viewDate = DateTime(_today.year, _today.month, 1);
        _selectedDate = _today;
      });

  List<CalendarEvent> get _comingUp {
    final list = _filteredEvents.where((e) => !e.date.isBefore(_today)).toList()..sort((a, b) => a.date.compareTo(b.date));
    return list.take(5).toList();
  }

  Future<void> _removeFromSaved(CalendarEvent event) async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    await eventService.toggleSaveEvent(token, event.eventId);
    if (!mounted) return;
    Navigator.pop(context);
    _load();
  }

  void _openDetail(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EventDetailSheet(
        event: event,
        onRemoveSaved: () => _removeFromSaved(event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return Scaffold(
      appBar: const AppTopBar(title: 'My Calendar'),
      body: _loading
          ? const CalendarPageSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: _statTile('${_filteredEvents.length}', 'On Calendar')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statTile(
                          '${_filteredEvents.where((e) => e.date.month == _viewDate.month && e.date.year == _viewDate.year).length}',
                          'This Month',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _statTile('${_filteredEvents.where((e) => _isSameDay(e.date, _today)).length}', 'Today')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _filterChip('All (${_events.length})', _SourceFilter.all),
                        const SizedBox(width: 8),
                        _filterChip(
                          'My Tickets (${_events.where((e) => e.source == CalendarEventSource.ticket).length})',
                          _SourceFilter.tickets,
                        ),
                        const SizedBox(width: 8),
                        _filterChip('Saved (${_events.where((e) => e.isSaved).length})', _SourceFilter.saved),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              IconButton(onPressed: _prevMonth, icon: const Icon(LucideIcons.chevronLeft, size: 18)),
                              TextButton(onPressed: _goToday, child: const Text('Today')),
                              Expanded(
                                child: Text(
                                  DateFormat.yMMMM().format(_viewDate),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                              IconButton(onPressed: _nextMonth, icon: const Icon(LucideIcons.chevronRight, size: 18)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),
                        Row(
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .map((d) => Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray400)),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 42,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.85),
                          itemBuilder: (context, i) {
                            final cellDate = _calendarCells[i];
                            final isToday = _isSameDay(cellDate, _today);
                            final isCurrentMonth = cellDate.month == _viewDate.month;
                            final isSelected = _selectedDate != null && _isSameDay(cellDate, _selectedDate!);
                            final dayEvents = _eventsOn(cellDate);

                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = (_selectedDate != null && _isSameDay(_selectedDate!, cellDate)) ? null : cellDate;
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                                  border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.5),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Opacity(
                                  opacity: isCurrentMonth ? 1 : 0.35,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isToday ? AppColors.primary : null,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${cellDate.day}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isToday ? Colors.white : (isSelected ? AppColors.primary : null),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 2,
                                        children: dayEvents
                                            .take(3)
                                            .map((e) => Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(color: sourceColor(e.source), shape: BoxShape.circle),
                                                ))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDate != null) ...[
                    Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDate!),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    if (_eventsOn(_selectedDate!).isEmpty)
                      const EmptyStateCard(icon: LucideIcons.calendarX, title: 'No events on this day')
                    else
                      Column(children: [for (final e in _eventsOn(_selectedDate!)) _eventTile(e)]),
                    const SizedBox(height: 20),
                  ],
                  const Text('Coming Up', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_comingUp.isEmpty)
                    const EmptyStateCard(icon: LucideIcons.calendar, title: 'Nothing on your calendar yet', subtitle: 'Save events or book tickets to see them here.')
                  else
                    Column(children: [for (final e in _comingUp) _eventTile(e)]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _statTile(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.gray400, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _SourceFilter value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.gray800 : AppColors.gray100),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.gray500)),
      ),
    );
  }

  Widget _eventTile(CalendarEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _openDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: sourceColor(event.source), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat.jm().format(event.date)} · ${event.venue}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.event, required this.onRemoveSaved});

  final CalendarEvent event;
  final VoidCallback onRemoveSaved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(event.hasTicket ? LucideIcons.ticket : LucideIcons.heart, size: 14, color: sourceColor(event.source)),
              const SizedBox(width: 6),
              Text(sourceLabel(event.source).toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sourceColor(event.source))),
            ],
          ),
          const SizedBox(height: 6),
          Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(LucideIcons.calendar, size: 15, color: AppColors.gray400),
            const SizedBox(width: 10),
            Text(DateFormat('EEEE, MMMM d, y').format(event.date)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(LucideIcons.clock, size: 15, color: AppColors.gray400),
            const SizedBox(width: 10),
            Text(DateFormat.jm().format(event.date)),
          ]),
          if (event.venue.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(LucideIcons.mapPin, size: 15, color: AppColors.gray400),
              const SizedBox(width: 10),
              Expanded(child: Text(event.venue)),
            ]),
          ],
          if (event.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 14),
            Text(event.description!, style: const TextStyle(color: AppColors.gray500, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (event.isSaved)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemoveSaved,
                    icon: const Icon(LucideIcons.heartOff, size: 14),
                    label: const Text('Remove from saved'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: AppColors.rose),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (event.isSaved) const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (event.hasTicket && event.ticketId != null) {
                      context.push('/ticket/${event.ticketId}');
                    } else {
                      context.push('/event/${event.eventId}');
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(event.hasTicket ? 'View Ticket' : 'View Event'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
