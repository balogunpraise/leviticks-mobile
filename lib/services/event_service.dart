import 'dart:typed_data';

import '../core/network/api_client.dart';
import '../models/common.dart';
import '../models/event_models.dart';
import '../models/ticket_models.dart';

class EventQueryParams {
  EventQueryParams({
    this.categoryId,
    this.pageSize = 20,
    this.currentPage = 1,
    this.sortValue = 'date',
    this.sortOrder = 'asc',
    this.searchTerm = '',
  });

  final String? categoryId;
  final int pageSize;
  final int currentPage;
  final String sortValue;
  final String sortOrder;
  final String searchTerm;
}

/// Mirrors the attendee-facing calls in `src/lib/services/event.ts`.
class EventService {
  EventService(this._client);

  final ApiClient _client;

  String _buildQuery(EventQueryParams p) {
    final parts = <String>[];
    if (p.categoryId != null && p.categoryId!.isNotEmpty) parts.add('CategoryId=${p.categoryId}');
    if (p.pageSize > 0) parts.add('PageSize=${p.pageSize}');
    if (p.currentPage > 0) parts.add('CurrentPage=${p.currentPage}');
    if (p.sortValue.isNotEmpty) parts.add('SortValue=${p.sortValue}');
    if (p.sortOrder.isNotEmpty) parts.add('SortOrder=${p.sortOrder}');
    if (p.searchTerm.isNotEmpty) parts.add('SearchTerm=${Uri.encodeComponent(p.searchTerm)}');
    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }

  Future<ApiResponse<EventsPagedResponse>?> getAllEvents(String? token, EventQueryParams params) {
    return _client.get<ApiResponse<EventsPagedResponse>>(
      'Event/get-all-events${_buildQuery(params)}',
      (json) => ApiResponse.fromJson(json, (d) => EventsPagedResponse.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<LeanEventDetails>?> getLeanEventDetails(String? token, String id) {
    return _client.get<ApiResponse<LeanEventDetails>>(
      'Event/$id/get-lean-event-details',
      (json) => ApiResponse.fromJson(json, (d) => LeanEventDetails.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<NextEventDto>?> getNextEvent(String? token) {
    return _client.get<ApiResponse<NextEventDto>>(
      'Event/next-event',
      (json) => ApiResponse.fromJson(json, (d) => NextEventDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<List<TicketTypeDto>>?> getTicketTypes(String? token, String eventId) {
    return _client.get<ApiResponse<List<TicketTypeDto>>>(
      'Ticket/$eventId/ticket-types',
      (json) => ApiResponse.fromJson(
        json,
        (d) => (d as List<dynamic>).map((e) => TicketTypeDto.fromJson(e as Map<String, dynamic>)).toList(),
      ),
      token: token,
    );
  }

  Future<ApiResponse<BookTicketResponse>?> bookTicket(String? token, BookTicketRequestModel request) {
    return _client.post<ApiResponse<BookTicketResponse>>(
      'Ticket/book-ticket',
      (json) => ApiResponse.fromJson(json, (d) => BookTicketResponse.fromJson(d as Map<String, dynamic>)),
      body: request.toJson(),
      token: token,
    );
  }

  Future<ApiResponse<bool>?> likeEvent(String? token, String eventId) {
    return _client.post<ApiResponse<bool>>(
      'EventEngagements/like',
      (json) => ApiResponse.fromJson(json, (d) => d as bool),
      body: {'eventId': eventId},
      token: token,
    );
  }

  /// Toggles the event in the user's saved list; data is true when it is now saved.
  Future<ApiResponse<bool>?> toggleSaveEvent(String? token, String eventId) {
    return _client.post<ApiResponse<bool>>(
      'EventEngagements/add-to-favorites',
      (json) => ApiResponse.fromJson(json, (d) => d as bool),
      body: {'eventId': eventId},
      token: token,
    );
  }

  Future<ApiResponse<EventsPagedResponse>?> getSavedEvents(
    String? token, {
    int pageSize = 12,
    int currentPage = 1,
    String searchTerm = '',
  }) {
    final parts = <String>[];
    if (pageSize > 0) parts.add('PageSize=$pageSize');
    if (currentPage > 0) parts.add('CurrentPage=$currentPage');
    if (searchTerm.isNotEmpty) parts.add('SearchTerm=${Uri.encodeComponent(searchTerm)}');
    final query = parts.isEmpty ? '' : '?${parts.join('&')}';
    return _client.get<ApiResponse<EventsPagedResponse>>(
      'EventEngagements/get-favorites$query',
      (json) => ApiResponse.fromJson(json, (d) => EventsPagedResponse.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  // The organizer running an event. ("{id}/organizer" below is the lookup by organizer id, not event id.)
  Future<ApiResponse<EventOrganizerDto>?> getEventOrganizer(String? token, String eventId) {
    return _client.get<ApiResponse<EventOrganizerDto>>(
      'EventEngagements/organizer?eventId=${Uri.encodeComponent(eventId)}',
      (json) => ApiResponse.fromJson(json, (d) => EventOrganizerDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<EventInterestDto>?> getEventInterest(String? token, String eventId, {int previewCount = 4}) {
    return _client.get<ApiResponse<EventInterestDto>>(
      'EventEngagements/$eventId/interested?previewCount=$previewCount',
      (json) => ApiResponse.fromJson(json, (d) => EventInterestDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<EventShareDto>?> getEventShare(String? token, String eventId) {
    return _client.get<ApiResponse<EventShareDto>>(
      'Event/$eventId/share',
      (json) => ApiResponse.fromJson(json, (d) => EventShareDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  /// Counts a completed share; returns the same payload with the new count.
  Future<ApiResponse<EventShareDto>?> recordEventShare(String? token, String eventId) {
    return _client.post<ApiResponse<EventShareDto>>(
      'Event/$eventId/share',
      (json) => ApiResponse.fromJson(json, (d) => EventShareDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<bool>?> followOrganizer(String? token, String organizerId) {
    return _client.post<ApiResponse<bool>>(
      'EventEngagements/organizer/follow',
      (json) => ApiResponse.fromJson(json, (d) => d as bool),
      body: {'organizerId': organizerId},
      token: token,
    );
  }

  Future<ApiResponse<bool>?> reviewEvent(String? token, ReviewEventRequest request) {
    return _client.post<ApiResponse<bool>>(
      'EventEngagements/review',
      (json) => ApiResponse.fromJson(json, (d) => d as bool),
      body: request.toJson(),
      token: token,
    );
  }

  Future<ApiResponse<OrganizerRatingsDto>?> getOrganizerRatings(String? token, String organizerId) {
    return _client.get<ApiResponse<OrganizerRatingsDto>>(
      'EventEngagements/$organizerId/organizer-ratings',
      (json) => ApiResponse.fromJson(json, (d) => OrganizerRatingsDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  Future<ApiResponse<List<MyTicketOrder>>?> getMyTickets(String? token) {
    return _client.get<ApiResponse<List<MyTicketOrder>>>(
      'Ticket/my-tickets',
      (json) => ApiResponse.fromJson(
        json,
        (d) => (d as List<dynamic>).map((e) => MyTicketOrder.fromJson(e as Map<String, dynamic>)).toList(),
      ),
      token: token,
    );
  }

  Future<ApiResponse<TicketDetailResponse>?> getTicketDetailsById(String? token, String ticketId) {
    return _client.get<ApiResponse<TicketDetailResponse>>(
      'Ticket/$ticketId/my-tickets',
      (json) => ApiResponse.fromJson(json, (d) => TicketDetailResponse.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  /// Backs the "buy for someone else" flow: says whether the address has an account, and whose.
  Future<ApiResponse<RecipientLookupResponse>?> lookupRecipient(String? token, String email) {
    return _client.get<ApiResponse<RecipientLookupResponse>>(
      'Ticket/recipient-lookup?email=${Uri.encodeComponent(email)}',
      (json) => ApiResponse.fromJson(json, (d) => RecipientLookupResponse.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  /// The real, scannable QR for a ticket, as PNG bytes (fetched with the auth header).
  Future<Uint8List?> getTicketQrImage(String? token, String ticketId) {
    return _client.getBytes('Ticket/$ticketId/qrcode', token: token);
  }

  Future<ApiResponse<VerifyCheckoutResponse>?> verifyCheckout(String? token, String reference) {
    return _client.get<ApiResponse<VerifyCheckoutResponse>>(
      'Checkout/verify/${Uri.encodeComponent(reference)}',
      (json) => ApiResponse.fromJson(json, (d) => VerifyCheckoutResponse.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  /// The buyer closed the payment form without paying: releases the reserved seats now rather
  /// than when the unpaid order expires. A payment that did go through still completes. Safe to repeat.
  Future<ApiResponse<VerifyCheckoutResponse>?> cancelCheckout(String? token, String reference) {
    return _client.post<ApiResponse<VerifyCheckoutResponse>>(
      'Checkout/cancel/${Uri.encodeComponent(reference)}',
      (json) => ApiResponse.fromJson(json, (d) => VerifyCheckoutResponse.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }
}
