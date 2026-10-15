import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../services/location_service.dart';

/// Mirrors `src/components/shared/LocationMap.tsx`: an embedded OpenStreetMap
/// view defaulting to Lagos, with an "Enable Location" button that requests
/// the device's real position and recenters the map on it.
class LocationMapCard extends StatefulWidget {
  const LocationMapCard({super.key});

  @override
  State<LocationMapCard> createState() => _LocationMapCardState();
}

class _LocationMapCardState extends State<LocationMapCard> {
  final _locationService = LocationService();

  double _lat = 6.5244;
  double _lng = 3.3792;
  bool _hasLocation = false;
  bool _loading = false;
  String _locationLabel = 'Lagos, Nigeria (default)';

  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(_mapUrl));

  String get _mapUrl =>
      'https://www.openstreetmap.org/export/embed.html'
      '?bbox=${_lng - 0.05}%2C${_lat - 0.05}%2C${_lng + 0.05}%2C${_lat + 0.05}'
      '&layer=mapnik&marker=$_lat%2C$_lng';

  Future<void> _requestLocation() async {
    setState(() => _loading = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _hasLocation = true;
        _locationLabel = '${_lat.toStringAsFixed(4)}° N, ${_lng.toStringAsFixed(4)}° E';
        _loading = false;
      });
      unawaited(_controller.loadRequest(Uri.parse(_mapUrl)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLabel = 'Location access denied';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            SizedBox(height: 200, child: WebViewWidget(controller: _controller)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: (isDark ? AppColors.gray900 : Colors.white).withValues(alpha: 0.9),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 13, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.gray700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _loading ? null : _requestLocation,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            Icon(
                              _hasLocation ? LucideIcons.refreshCw : LucideIcons.locateFixed,
                              size: 12,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _loading
                                ? 'Locating…'
                                : _hasLocation
                                    ? 'Change Location'
                                    : 'Enable Location',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
