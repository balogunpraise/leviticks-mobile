import 'event_models.dart';

/// Mirrors `src/types/ticket.ts`.
class TicketTypeDto {
  TicketTypeDto({
    required this.ticketTypeId,
    required this.eventId,
    required this.name,
    this.description,
    this.price,
    this.quantityAvailable,
    this.maxPerOrder,
    this.isVisible = true,
  });

  final String ticketTypeId;
  final String eventId;
  final String name;
  final String? description;
  final double? price;
  final int? quantityAvailable;
  final int? maxPerOrder;
  final bool isVisible;

  factory TicketTypeDto.fromJson(Map<String, dynamic> json) => TicketTypeDto(
        ticketTypeId: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        quantityAvailable: json['quantityAvailable'] as int?,
        maxPerOrder: json['maxPerOrder'] as int?,
        isVisible: json['isVisible'] as bool? ?? true,
      );
}

class BookTicketItem {
  BookTicketItem({required this.ticketTypeId, required this.quantity});

  final String ticketTypeId;
  final int quantity;

  Map<String, dynamic> toJson() => {'ticketTypeId': ticketTypeId, 'quantity': quantity};
}

/// Who the tickets are for when the buyer is not keeping them. Omit to buy for yourself.
class TicketRecipient {
  TicketRecipient({required this.fullName, required this.email});

  final String fullName;
  final String email;

  Map<String, dynamic> toJson() => {'fullName': fullName, 'email': email};
}

class RecipientLookupResponse {
  RecipientLookupResponse({required this.found, this.firstName, this.lastName, this.imageUrl});

  final bool found;
  final String? firstName;
  final String? lastName;
  final String? imageUrl;

  factory RecipientLookupResponse.fromJson(Map<String, dynamic> json) => RecipientLookupResponse(
        found: json['found'] as bool? ?? false,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );

  String get fullName => [firstName, lastName].where((s) => s != null && s.trim().isNotEmpty).join(' ');
}

class BookTicketRequestModel {
  BookTicketRequestModel({required this.eventId, required this.ticketTypes, this.recipient});

  final String eventId;
  final List<BookTicketItem> ticketTypes;
  final TicketRecipient? recipient;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'ticketTypes': ticketTypes.map((e) => e.toJson()).toList(),
        if (recipient != null) 'recipient': recipient!.toJson(),
      };
}

class BookedTicketDto {
  BookedTicketDto({
    required this.ticketTypeName,
    required this.quantity,
    required this.pricePerTicket,
  });

  final String ticketTypeName;
  final int quantity;
  final double pricePerTicket;

  factory BookedTicketDto.fromJson(Map<String, dynamic> json) => BookedTicketDto(
        ticketTypeName: json['ticketTypeName'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        pricePerTicket: (json['pricePerTicket'] as num?)?.toDouble() ?? 0,
      );
}

class BookTicketResponse {
  BookTicketResponse({
    required this.bookingId,
    required this.bookedTickets,
    required this.totalAmount,
    this.checkoutUrl,
    this.paymentReference,
  });

  final String bookingId;
  final List<BookedTicketDto> bookedTickets;
  final double totalAmount;
  // Populated only for paid events - the buyer must be redirected here to complete payment.
  final String? checkoutUrl;
  final String? paymentReference;

  bool get requiresPayment => checkoutUrl != null && checkoutUrl!.isNotEmpty;

  factory BookTicketResponse.fromJson(Map<String, dynamic> json) => BookTicketResponse(
        bookingId: json['bookingId'] as String? ?? '',
        bookedTickets: (json['bookedTickets'] as List<dynamic>? ?? [])
            .map((e) => BookedTicketDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        checkoutUrl: json['checkoutUrl'] as String?,
        paymentReference: json['paymentReference'] as String?,
      );
}

class VerifyCheckoutResponse {
  VerifyCheckoutResponse({
    required this.orderId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalAmount,
    required this.bookedTickets,
  });

  final String orderId;
  final String orderStatus;
  final String paymentStatus;
  final double totalAmount;
  final List<BookedTicketDto> bookedTickets;

  bool get isSuccessful => paymentStatus.toLowerCase() == 'success' || paymentStatus.toLowerCase() == 'successful';
  bool get isFailed => paymentStatus.toLowerCase() == 'failed';

  factory VerifyCheckoutResponse.fromJson(Map<String, dynamic> json) => VerifyCheckoutResponse(
        orderId: json['orderId'] as String? ?? '',
        orderStatus: json['orderStatus'] as String? ?? '',
        paymentStatus: json['paymentStatus'] as String? ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        bookedTickets: (json['bookedTickets'] as List<dynamic>? ?? [])
            .map((e) => BookedTicketDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MyTicketItem {
  MyTicketItem({
    required this.ticketId,
    required this.ticketNumber,
    required this.ticketType,
    required this.status,
  });

  final String ticketId;
  final String ticketNumber;
  final String ticketType;
  final int status;

  factory MyTicketItem.fromJson(Map<String, dynamic> json) => MyTicketItem(
        ticketId: json['ticketId'] as String? ?? '',
        ticketNumber: json['ticketNumber'] as String? ?? '',
        ticketType: json['ticketType'] as String? ?? '',
        status: json['status'] as int? ?? 0,
      );
}

class MyTicketOrder {
  MyTicketOrder({
    required this.eventImageUrl,
    required this.eventId,
    required this.eventName,
    required this.location,
    required this.eventDateAndTime,
    required this.tickets,
  });

  final String? eventImageUrl;
  final String eventId;
  final String eventName;
  final String location;
  final DateTime eventDateAndTime;
  final List<MyTicketItem> tickets;

  factory MyTicketOrder.fromJson(Map<String, dynamic> json) => MyTicketOrder(
        eventImageUrl: json['eventImageUrl'] as String?,
        eventId: json['eventId'] as String? ?? '',
        eventName: json['eventName'] as String? ?? '',
        location: json['location'] as String? ?? '',
        eventDateAndTime:
            DateTime.tryParse(json['eventDateAndTime'] as String? ?? '') ?? DateTime.now(),
        tickets: (json['tickets'] as List<dynamic>? ?? [])
            .map((e) => MyTicketItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CheckInHistoryItem {
  CheckInHistoryItem({required this.checkInDateTime, required this.isValid});

  final DateTime checkInDateTime;
  final bool isValid;

  factory CheckInHistoryItem.fromJson(Map<String, dynamic> json) => CheckInHistoryItem(
        checkInDateTime: DateTime.tryParse(json['checkInDateTime'] as String? ?? '') ?? DateTime.now(),
        isValid: json['isValid'] as bool? ?? false,
      );
}

class TicketDetailResponse {
  TicketDetailResponse({
    required this.eventId,
    required this.eventName,
    this.eventImageUrl,
    required this.ticketId,
    required this.ticketNumber,
    required this.ticketType,
    required this.location,
    required this.eventType,
    required this.attendeeName,
    this.pricePaid,
    required this.status,
    this.validFrom,
    this.validTo,
    this.eventDescription,
    required this.venue,
  });

  final String eventId;
  final String eventName;
  final String? eventImageUrl;
  final String ticketId;
  final String ticketNumber;
  final String ticketType;
  final String location;
  final String eventType;
  final String attendeeName;
  final double? pricePaid;
  final int status;
  final String? validFrom;
  final String? validTo;
  final String? eventDescription;
  final VenueApiDto venue;

  factory TicketDetailResponse.fromJson(Map<String, dynamic> json) => TicketDetailResponse(
        eventId: json['eventId'] as String? ?? '',
        eventName: json['eventName'] as String? ?? '',
        eventImageUrl: json['eventImageUrl'] as String?,
        ticketId: json['ticketId'] as String? ?? '',
        ticketNumber: json['ticketNumber'] as String? ?? '',
        ticketType: json['ticketType'] as String? ?? '',
        location: json['location'] as String? ?? '',
        eventType: json['eventType'] as String? ?? '',
        attendeeName: json['attendeeName'] as String? ?? 'Guest',
        pricePaid: (json['pricePaid'] as num?)?.toDouble(),
        status: json['status'] as int? ?? 0,
        validFrom: json['validFrom'] as String?,
        validTo: json['validTo'] as String?,
        eventDescription: json['eventDescription'] as String?,
        venue: VenueApiDto.fromJson(json['venue'] as Map<String, dynamic>?),
      );
}

/// UI-ready ticket shape, mirroring the `TicketItem` mapped client-side in
/// `my-tickets/page.tsx` from `MyTicketOrder`/`TicketDetailResponse`.
class TicketItem {
  TicketItem({
    required this.eventTitle,
    required this.imageUrl,
    required this.eventDate,
    required this.venue,
    required this.ticketType,
    required this.ticketCode,
    required this.status,
    this.ticketId,
  });

  final String eventTitle;
  final String imageUrl;
  final DateTime eventDate;
  final String venue;
  final String ticketType;
  final String ticketCode;
  final String status; // upcoming | past | transferred
  final String? ticketId;
}

class ReviewEventRequest {
  ReviewEventRequest({required this.eventId, required this.rating, this.comment});

  final String eventId;
  final int rating;
  final String? comment;

  Map<String, dynamic> toJson() => {'eventId': eventId, 'rating': rating, 'comment': comment};
}
