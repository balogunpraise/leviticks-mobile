import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Mirrors the `CalendarEvent` the web app builds client-side in
/// `(attendee)/calendar/page.tsx` by merging `getMyTicketsRequest` +
/// `getSavedEventsRequest` — a ticket entry wins over a saved entry for the
/// same event, but keeps the `isSaved` flag either way.
class CalendarEvent {
  CalendarEvent({
    required this.eventId,
    required this.title,
    required this.date,
    required this.venue,
    this.description,
    this.imageUrl,
    required this.source,
    required this.isSaved,
    this.ticketId,
  });

  final String eventId;
  final String title;
  final DateTime date;
  final String venue;
  final String? description;
  final String? imageUrl;
  final CalendarEventSource source;
  final bool isSaved;
  final String? ticketId;

  bool get hasTicket => source == CalendarEventSource.ticket;
}

enum CalendarEventSource { ticket, saved }

Color sourceColor(CalendarEventSource source) => source == CalendarEventSource.ticket ? AppColors.success : AppColors.rose;

String sourceLabel(CalendarEventSource source) => source == CalendarEventSource.ticket ? 'My Tickets' : 'Saved';
