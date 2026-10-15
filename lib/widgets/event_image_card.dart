import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../models/event_models.dart';

/// Mirrors `src/components/shared/ImageCard.tsx` — the event card used on
/// Explore/Dashboard: cover image with category + like overlay, then title,
/// date/location, organizer avatar and a "Get Tickets" pill.
class EventImageCard extends StatefulWidget {
  const EventImageCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onToggleSave,
  });

  final EventCardModel event;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggleSave;

  @override
  State<EventImageCard> createState() => _EventImageCardState();
}

class _EventImageCardState extends State<EventImageCard> {
  late bool _isSaved = widget.event.isSavedByCurrentUser ?? false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: e.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(color: AppColors.gray200),
                    placeholder: (_, _) => Container(color: AppColors.gray200),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _pill(
                      e.category.toUpperCase(),
                      background: Colors.black.withValues(alpha: 0.5),
                      textColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isSaved = !_isSaved);
                        widget.onToggleSave?.call(_isSaved);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.heart,
                          size: 16,
                          color: _isSaved ? AppColors.rose : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (e.price.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _pill(
                        e.price,
                        background: e.isFree ? AppColors.emerald500 : Colors.white.withValues(alpha: 0.9),
                        textColor: e.isFree ? Colors.white : AppColors.gray900,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${e.date} · ${e.time}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: isDark ? Colors.white : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 11, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          e.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.gray200,
                        backgroundImage: e.organizerImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(e.organizerImageUrl)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.organizerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Text(
                          'Get Tickets',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {required Color background, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
