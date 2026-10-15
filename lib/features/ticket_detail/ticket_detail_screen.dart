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
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/ticket_qr_view.dart';

/// Mirrors `src/app/(attendee)/ticket/[ticketId]/page.tsx`.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _loading = true;
  TicketDetailResponse? _detail;
  int _reviewRating = 0;
  final _reviewComment = TextEditingController();
  bool _reviewSubmitting = false;
  bool _reviewSubmitted = false;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reviewComment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.getTicketDetailsById(token, widget.ticketId);
    if (!mounted) return;
    setState(() {
      if (response?.statusCode == ApiResponse.successCode) _detail = response?.data;
      _loading = false;
    });
  }

  String get _status {
    final d = _detail;
    if (d == null) return 'upcoming';
    final validTo = d.validTo != null ? DateTime.tryParse(d.validTo!) : null;
    if (validTo != null && validTo.isBefore(DateTime.now())) return 'past';
    if (d.status == 2) return 'transferred';
    return 'upcoming';
  }

  Future<void> _submitReview() async {
    if (_reviewRating == 0 || _detail == null) return;
    setState(() {
      _reviewSubmitting = true;
      _reviewError = null;
    });
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.reviewEvent(
      token,
      ReviewEventRequest(
        eventId: _detail!.eventId,
        rating: _reviewRating,
        comment: _reviewComment.text.trim().isEmpty ? null : _reviewComment.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _reviewSubmitting = false;
      if (response?.statusCode == ApiResponse.successCode) {
        _reviewSubmitted = true;
      } else {
        _reviewError = response?.message ?? 'Failed to submit review. Please try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.moveLeft), onPressed: () => context.pop()),
        title: const Text('Ticket Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const TicketDetailPageSkeleton()
          : _detail == null
              ? const Center(child: Text('Ticket not found.', style: TextStyle(color: AppColors.gray400)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.xl2),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                (_detail!.eventImageUrl?.isNotEmpty ?? false)
                                    ? CachedNetworkImage(imageUrl: _detail!.eventImageUrl!, fit: BoxFit.cover)
                                    : Container(
                                        color: AppColors.gray200,
                                        child: const Icon(LucideIcons.image, size: 36, color: AppColors.gray400)),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: StatusPill(
                                    label: _status,
                                    color: _status == 'past'
                                        ? StatusColors.past
                                        : _status == 'transferred'
                                            ? StatusColors.transferred
                                            : StatusColors.upcoming,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_detail!.eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 16),
                                Wrap(
                                  runSpacing: 12,
                                  children: [
                                    _field('ATTENDEE', _detail!.attendeeName, half: true),
                                    _field('TICKET TYPE', _detail!.ticketType, half: true),
                                    _field('ORDER NUMBER', _detail!.ticketNumber, half: true),
                                    _field(
                                      'PRICE',
                                      _detail!.pricePaid != null ? '₦${_detail!.pricePaid!.toStringAsFixed(0)}' : '—',
                                      half: true,
                                    ),
                                    if (_detail!.validFrom != null)
                                      _field(
                                        'DATE & TIME',
                                        DateFormat('MMM d, y · h:mm a')
                                            .format(DateTime.tryParse(_detail!.validFrom!) ?? DateTime.now()),
                                      ),
                                    _field('LOCATION', _detail!.location),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderColor),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text('SCAN AT ENTRANCE',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 1.5)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
                                  ),
                                  child: TicketQrView(ticketId: widget.ticketId, fallbackCode: _detail!.ticketNumber, size: 160),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _detail!.ticketNumber,
                                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_detail!.eventDescription?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.xl2),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('About this event', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(_detail!.eventDescription!, style: const TextStyle(color: AppColors.gray500, fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                    if (_status == 'past') ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.xl2),
                          border: Border.all(color: borderColor),
                        ),
                        child: _reviewSubmitted
                            ? const Row(
                                children: [
                                  Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
                                  SizedBox(width: 8),
                                  Text('Review submitted!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('How was the event?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: List.generate(5, (i) {
                                      final star = i + 1;
                                      return IconButton(
                                        onPressed: () => setState(() => _reviewRating = star),
                                        icon: Icon(
                                          star <= _reviewRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: AppColors.amber,
                                          size: 28,
                                        ),
                                      );
                                    }),
                                  ),
                                  TextField(
                                    controller: _reviewComment,
                                    maxLines: 3,
                                    decoration: const InputDecoration(hintText: 'Tell us about your experience (optional)'),
                                  ),
                                  if (_reviewError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(_reviewError!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
                                  ],
                                  const SizedBox(height: 12),
                                  PrimaryButton(
                                    label: 'Submit Review',
                                    icon: LucideIcons.send,
                                    isLoading: _reviewSubmitting,
                                    onPressed: _reviewRating == 0 ? null : _submitReview,
                                  ),
                                ],
                              ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _field(String label, String value, {bool half = false}) {
    return SizedBox(
      width: half ? (MediaQuery.of(context).size.width - 32 - 36) / 2 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
