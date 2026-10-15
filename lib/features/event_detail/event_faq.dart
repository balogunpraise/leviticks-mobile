import '../../models/event_models.dart';

/// Mirrors `src/lib/eventFaq.ts`'s `buildEventFaqs` — a pure function deriving
/// a fixed FAQ list from the event's policy fields, not fetched from the API.
List<(String question, String answer)> buildEventFaqs(LeanEventDetails event, bool isOnline) {
  final faqs = <(String, String)>[
    (
      'What should I bring to the event?',
      (event.whatToBring?.trim().isNotEmpty ?? false) ? event.whatToBring!.trim() : 'Valid QR code',
    ),
  ];

  if (!isOnline) {
    faqs.add(('Is there parking available?', _parkingAnswer(event.parkingOption)));
  }

  faqs.add((
    "Can I get a refund if I can't attend?",
    (event.refundPolicy?.trim().isNotEmpty ?? false)
        ? event.refundPolicy!.trim()
        : 'Refunds are handled by the organizer. Please contact them about your request.',
  ));

  faqs.add(('Are children allowed?', _childrenAnswer(event.childrenPolicy)));

  if (!isOnline) {
    faqs.add(('Will food and drinks be available?', _foodAnswer(event.foodAndDrinksOption)));
  }

  return faqs;
}

String _parkingAnswer(int? value) {
  switch (value) {
    case 1:
      return 'Yes, free parking is available at the venue.';
    case 2:
      return 'Yes, paid parking is available at the venue.';
    case 4:
      return 'No, there is no parking at the venue. We recommend a ride-hailing service or public transport.';
    case 3:
    default:
      return 'Parking is limited, so we recommend carpooling or using a ride-hailing service.';
  }
}

String _childrenAnswer(int? value) {
  switch (value) {
    case 2:
      return 'Yes, children are welcome when accompanied by an adult.';
    case 3:
      return 'No, this event is for adults only (18+).';
    case 1:
    default:
      return 'Yes, this event is open to all ages.';
  }
}

String _foodAnswer(int? value) {
  switch (value) {
    case 2:
      return 'Yes, food and drinks are included with your ticket.';
    case 3:
      return 'No, food and drinks will not be available.';
    case 1:
    default:
      return 'Yes, food and drinks will be available to buy at the event.';
  }
}
