/// Mirrors the shapes used from `src/types/event.ts` on the attendee pages.
class VenueApiDto {
  VenueApiDto({
    this.name,
    this.venueImageUrl,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  final String? name;
  final String? venueImageUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  factory VenueApiDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VenueApiDto();
    return VenueApiDto(
      name: json['name'] as String?,
      venueImageUrl: json['venueImageUrl'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }

  String get displayLine =>
      [name, city].where((s) => s != null && s.trim().isNotEmpty).join(', ');

  String get fullAddressLine =>
      [name, address, city, state, country].where((s) => s != null && s.trim().isNotEmpty).join(', ');
}

class OrganizerDto {
  OrganizerDto({required this.organizerId, required this.organizerName});

  final String organizerId;
  final String organizerName;

  factory OrganizerDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OrganizerDto(organizerId: '', organizerName: '');
    return OrganizerDto(
      organizerId: json['organizerId'] as String? ?? '',
      organizerName: json['organizerName'] as String? ?? '',
    );
  }
}

class EventOrganizerDto {
  EventOrganizerDto({
    required this.organizerId,
    required this.organizerName,
    this.organizerImageUrl,
    required this.followersCount,
    required this.isFollowing,
  });

  final String organizerId;
  final String organizerName;
  final String? organizerImageUrl;
  final int followersCount;
  final bool isFollowing;

  factory EventOrganizerDto.fromJson(Map<String, dynamic> json) => EventOrganizerDto(
        organizerId: json['organizerId'] as String? ?? '',
        organizerName: json['organizerName'] as String? ?? '',
        organizerImageUrl: json['organizerImageUrl'] as String?,
        followersCount: json['followersCount'] as int? ?? 0,
        isFollowing: json['isFollowing'] as bool? ?? false,
      );
}

/// Mirrors `EventApiResponse` — the full event returned by `Event/get-all-events`.
class EventApiResponse {
  EventApiResponse({
    required this.id,
    required this.title,
    required this.description,
    this.shortDescription,
    this.organizerImageUrl,
    required this.organizerName,
    required this.startDateTime,
    required this.endDateTime,
    this.coverImageUrl,
    this.bannerImageUrl,
    required this.hasMaximumCapacity,
    required this.isFree,
    this.maxCapacity,
    required this.soldTicketsCount,
    this.mainCategory,
    required this.categories,
    required this.eventType,
    required this.organizer,
    required this.venue,
    required this.isLikedByCurrentUser,
    required this.isSavedByCurrentUser,
  });

  final String id;
  final String title;
  final String description;
  final String? shortDescription;
  final String? organizerImageUrl;
  final String organizerName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? coverImageUrl;
  final String? bannerImageUrl;
  final bool hasMaximumCapacity;
  final bool isFree;
  final int? maxCapacity;
  final int soldTicketsCount;
  final String? mainCategory;
  final List<String> categories;
  final String eventType;
  final OrganizerDto organizer;
  final VenueApiDto venue;
  final bool isLikedByCurrentUser;
  final bool isSavedByCurrentUser;

  factory EventApiResponse.fromJson(Map<String, dynamic> json) => EventApiResponse(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        shortDescription: json['shortDescription'] as String?,
        organizerImageUrl: json['organizerImageUrl'] as String?,
        organizerName: json['organizerName'] as String? ?? '',
        startDateTime: DateTime.tryParse(json['startDateTime'] as String? ?? '') ?? DateTime.now(),
        endDateTime: DateTime.tryParse(json['endDateTime'] as String? ?? '') ?? DateTime.now(),
        coverImageUrl: json['coverImageUrl'] as String?,
        bannerImageUrl: json['bannerImageUrl'] as String?,
        hasMaximumCapacity: json['hasMaximumCapacity'] as bool? ?? false,
        isFree: json['isFree'] as bool? ?? false,
        maxCapacity: json['maxCapacity'] as int?,
        soldTicketsCount: json['soldTicketsCount'] as int? ?? 0,
        mainCategory: json['mainCategory'] as String?,
        categories: (json['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        eventType: json['eventType'] as String? ?? '',
        organizer: OrganizerDto.fromJson(json['organizer'] as Map<String, dynamic>?),
        venue: VenueApiDto.fromJson(json['venue'] as Map<String, dynamic>?),
        isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
        isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool? ?? false,
      );
}

class EventsPagedResponse {
  EventsPagedResponse({
    required this.items,
    required this.totalCount,
    this.currentPage = 1,
    this.hasNextPage = false,
  });

  final List<EventApiResponse> items;
  final int totalCount;
  final int currentPage;
  final bool hasNextPage;

  factory EventsPagedResponse.fromJson(Map<String, dynamic> json) => EventsPagedResponse(
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => EventApiResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCount: json['totalCount'] as int? ?? 0,
        currentPage: json['currentPage'] as int? ?? 1,
        hasNextPage: json['hasNextPage'] as bool? ?? false,
      );
}

/// Mirrors `LeanEventDetails` — the detail-page payload.
class LeanEventDetails {
  LeanEventDetails({
    required this.id,
    required this.title,
    required this.description,
    this.shortDescription,
    this.organizerId,
    this.organizerImageUrl,
    required this.organizerName,
    required this.startDateTime,
    required this.endDateTime,
    this.coverImageUrl,
    this.bannerImageUrl,
    required this.hasMaximumCapacity,
    required this.isFree,
    this.maxCapacity,
    required this.soldTicketsCount,
    this.mainCategory,
    required this.categories,
    required this.eventType,
    required this.organizer,
    required this.venue,
    required this.isOrganizerFollowedByCurrentUser,
    required this.isLikedByCurrentUser,
    required this.isSavedByCurrentUser,
    required this.lineup,
    this.gallery = const [],
    this.eventHighlights = const [],
    this.whatToExpect,
    this.whatToBring,
    this.parkingOption,
    this.refundPolicy,
    this.childrenPolicy,
    this.foodAndDrinksOption,
    this.sharedCount = 0,
    this.favoriteCount = 0,
    this.shareUrl,
  });

  final String id;
  final String title;
  final String description;
  final String? shortDescription;
  final String? organizerId;
  final String? organizerImageUrl;
  final String organizerName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? coverImageUrl;
  final String? bannerImageUrl;
  final bool hasMaximumCapacity;
  final bool isFree;
  final int? maxCapacity;
  final int soldTicketsCount;
  final String? mainCategory;
  final List<String> categories;
  final String eventType;
  final OrganizerDto organizer;
  final VenueApiDto venue;
  final bool isOrganizerFollowedByCurrentUser;
  final bool isLikedByCurrentUser;
  final bool isSavedByCurrentUser;
  final List<EventLineupItem> lineup;
  final List<EventGalleryImage> gallery;
  final List<EventHighlightItem> eventHighlights;
  final String? whatToExpect;
  // FAQ answer sources — mirror src/lib/eventFaq.ts.
  final String? whatToBring;
  final int? parkingOption;
  final String? refundPolicy;
  final int? childrenPolicy;
  final int? foodAndDrinksOption;
  final int sharedCount;
  final int favoriteCount;
  final String? shareUrl;

  bool get isOnline => eventType.toLowerCase() == 'online';

  factory LeanEventDetails.fromJson(Map<String, dynamic> json) => LeanEventDetails(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        shortDescription: json['shortDescription'] as String?,
        organizerId: json['organizerId'] as String?,
        organizerImageUrl: json['organizerImageUrl'] as String?,
        organizerName: json['organizerName'] as String? ?? '',
        startDateTime: DateTime.tryParse(json['startDateTime'] as String? ?? '') ?? DateTime.now(),
        endDateTime: DateTime.tryParse(json['endDateTime'] as String? ?? '') ?? DateTime.now(),
        coverImageUrl: json['coverImageUrl'] as String?,
        bannerImageUrl: json['bannerImageUrl'] as String?,
        hasMaximumCapacity: json['hasMaximumCapacity'] as bool? ?? false,
        isFree: json['isFree'] as bool? ?? false,
        maxCapacity: json['maxCapacity'] as int?,
        soldTicketsCount: json['soldTicketsCount'] as int? ?? 0,
        mainCategory: json['mainCategory'] as String?,
        categories: (json['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        eventType: json['eventType'] as String? ?? '',
        organizer: OrganizerDto.fromJson(json['organizer'] as Map<String, dynamic>?),
        venue: VenueApiDto.fromJson(json['venue'] as Map<String, dynamic>?),
        isOrganizerFollowedByCurrentUser: json['isOrganizerFollowedByCurrentUser'] as bool? ?? false,
        isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
        isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool? ?? false,
        lineup: (json['lineup'] as List<dynamic>? ?? [])
            .map((e) => EventLineupItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        gallery: (json['gallery'] as List<dynamic>? ?? [])
            .map((e) => EventGalleryImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        eventHighlights: (json['eventHighlights'] as List<dynamic>? ?? [])
            .map((e) => EventHighlightItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        whatToExpect: json['whatToExpect'] as String?,
        whatToBring: json['whatToBring'] as String?,
        parkingOption: json['parkingOption'] as int?,
        refundPolicy: json['refundPolicy'] as String?,
        childrenPolicy: json['childrenPolicy'] as int?,
        foodAndDrinksOption: json['foodAndDrinksOption'] as int?,
        sharedCount: json['sharedCount'] as int? ?? 0,
        favoriteCount: json['favoriteCount'] as int? ?? 0,
        shareUrl: json['shareUrl'] as String?,
      );
}

class EventLineupItem {
  EventLineupItem({required this.name, required this.act, this.imageUrl, this.appointementCanclled = false});

  final String name;
  final String act;
  final String? imageUrl;
  final bool appointementCanclled;

  factory EventLineupItem.fromJson(Map<String, dynamic> json) => EventLineupItem(
        name: json['name'] as String? ?? '',
        act: json['act'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        appointementCanclled: json['appointementCanclled'] as bool? ?? false,
      );
}

class EventGalleryImage {
  EventGalleryImage({required this.id, required this.imageUrl, this.caption, this.isPrimary = false});

  final String id;
  final String imageUrl;
  final String? caption;
  final bool isPrimary;

  factory EventGalleryImage.fromJson(Map<String, dynamic> json) => EventGalleryImage(
        id: json['id'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        caption: json['caption'] as String?,
        isPrimary: json['isPrimary'] as bool? ?? false,
      );
}

class EventHighlightItem {
  EventHighlightItem({required this.id, required this.title, this.icon, this.details});

  final String id;
  final String title;
  final String? icon;
  final String? details;

  factory EventHighlightItem.fromJson(Map<String, dynamic> json) => EventHighlightItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        icon: json['icon'] as String?,
        details: json['details'] as String?,
      );
}

class EventInterestPerson {
  EventInterestPerson({this.firstName, this.imageUrl});

  final String? firstName;
  final String? imageUrl;

  factory EventInterestPerson.fromJson(Map<String, dynamic> json) => EventInterestPerson(
        firstName: json['firstName'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}

class EventInterestDto {
  EventInterestDto({required this.interestedCount, required this.people});

  final int interestedCount;
  final List<EventInterestPerson> people;

  factory EventInterestDto.fromJson(Map<String, dynamic> json) => EventInterestDto(
        interestedCount: json['interestedCount'] as int? ?? 0,
        people: (json['people'] as List<dynamic>? ?? [])
            .map((e) => EventInterestPerson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EventShareDto {
  EventShareDto({
    required this.eventId,
    required this.url,
    required this.title,
    required this.text,
    this.imageUrl,
    this.sharedCount = 0,
    this.channels = const {},
  });

  final String eventId;
  final String url;
  final String title;
  final String text;
  final String? imageUrl;
  final int sharedCount;
  final Map<String, String> channels;

  factory EventShareDto.fromJson(Map<String, dynamic> json) => EventShareDto(
        eventId: json['eventId'] as String? ?? '',
        url: json['url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        sharedCount: json['sharedCount'] as int? ?? 0,
        channels: (json['channels'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v.toString())),
      );
}

class NextEventDto {
  NextEventDto({
    required this.eventId,
    required this.eventDate,
    required this.address,
    required this.eventName,
  });

  final String eventId;
  final DateTime eventDate;
  final String address;
  final String eventName;

  factory NextEventDto.fromJson(Map<String, dynamic> json) => NextEventDto(
        eventId: json['eventId'] as String? ?? '',
        eventDate: DateTime.tryParse(json['eventDate'] as String? ?? '') ?? DateTime.now(),
        address: json['address'] as String? ?? '',
        eventName: json['eventName'] as String? ?? '',
      );
}

class OrganizerRatingReview {
  OrganizerRatingReview({
    required this.reviewerName,
    required this.comment,
    required this.rating,
    required this.dateReviewed,
    this.reviewerImageUrl,
    required this.eventName,
  });

  final String reviewerName;
  final String comment;
  final int rating;
  final String dateReviewed;
  final String? reviewerImageUrl;
  final String eventName;

  factory OrganizerRatingReview.fromJson(Map<String, dynamic> json) => OrganizerRatingReview(
        reviewerName: json['reviewerName'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
        rating: json['rating'] as int? ?? 0,
        dateReviewed: json['dateReviewed'] as String? ?? '',
        reviewerImageUrl: json['reviewerImageUrl'] as String?,
        eventName: json['eventName'] as String? ?? '',
      );
}

class OrganizerRatingsDto {
  OrganizerRatingsDto({
    required this.averageRating,
    required this.totalReviews,
    required this.randomReviews,
  });

  final double averageRating;
  final int totalReviews;
  final List<OrganizerRatingReview> randomReviews;

  factory OrganizerRatingsDto.fromJson(Map<String, dynamic> json) => OrganizerRatingsDto(
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        totalReviews: json['totalReviews'] as int? ?? 0,
        randomReviews: (json['randomReviews'] as List<dynamic>? ?? [])
            .map((e) => OrganizerRatingReview.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// UI-ready shape for cards, mirroring `EventCardModel` (built client-side
/// from `EventApiResponse` the same way `explore/page.tsx` maps it).
class EventCardModel {
  EventCardModel({
    this.slug,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.organizerName,
    required this.organizerImageUrl,
    required this.price,
    this.description,
    this.isLikedByCurrentUser,
    this.isSavedByCurrentUser,
  });

  final String? slug;
  final String title;
  final String imageUrl;
  final String category;
  final String date;
  final String time;
  final String location;
  final String organizerName;
  final String organizerImageUrl;
  final String price;
  final String? description;
  final bool? isLikedByCurrentUser;
  final bool? isSavedByCurrentUser;

  bool get isFree => price.toLowerCase() == 'free';
}
