import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/models.dart';
import '../../theme.dart';

class LocationMapView extends StatefulWidget {
  final PhotoLocation? location;

  const LocationMapView({super.key, required this.location});

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _mapController = MapController.withPosition(
        initPosition: GeoPoint(
          latitude: widget.location!.latitude,
          longitude: widget.location!.longitude,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant LocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != null &&
        (oldWidget.location?.latitude != widget.location!.latitude ||
            oldWidget.location?.longitude != widget.location!.longitude)) {
      _mapController?.dispose();
      _mapController = MapController.withPosition(
        initPosition: GeoPoint(
          latitude: widget.location!.latitude,
          longitude: widget.location!.longitude,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      toastification.show(
        title: const Text('Error'),
        description: const Text('Could not open map URL'),
        type: ToastificationType.error,
      );
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    toastification.show(
      title: const Text('Copied'),
      description: Text('$label copied to clipboard'),
      type: ToastificationType.success,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191C20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262C32) : const Color(0xFFE2E6EA);
    final loc = widget.location;

    if (loc == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF21262C) : const Color(0xFFF0F4F8),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.locationPinLock,
                  size: 32,
                  color: BrandColors.neutral,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No GPS Telemetry Recorded',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? BrandColors.white : BrandColors.darkGrey,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'The image either does not contain GPS IFD coordinates, was captured on a device with location services disabled, or the metadata was sanitized.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? BrandColors.neutral : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrandColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.locationDot,
                    color: BrandColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geolocation & OpenStreetMap',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? BrandColors.white : BrandColors.darkGrey,
                        ),
                      ),
                      Text(
                        'Exact physical coordinates extracted from EXIF GPS tags',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? BrandColors.neutral : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // External map action buttons
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(loc.googleMapsUrl),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.mapLocationDot, size: 12),
                  label: const Text('Google Maps', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(loc.openStreetMapUrl),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.globe, size: 12),
                  label: const Text('OSM', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Interactive Map Container
          SizedBox(
            height: 320,
            width: double.infinity,
            child: OSMFlutter(
              controller: _mapController!,
              osmOption: const OSMOption(
                zoomOption: ZoomOption(initZoom: 15, minZoomLevel: 3, maxZoomLevel: 19),
              ),
              onMapIsReady: (isReady) async {
                if (isReady) {
                  await _mapController!.addMarker(
                    GeoPoint(
                      latitude: loc.latitude,
                      longitude: loc.longitude,
                    ),
                  );
                }
              },
            ),
          ),

          // Coordinate Details & Telemetry Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Coordinates Row
                Row(
                  children: [
                    Expanded(
                      child: _CoordPill(
                        label: 'Decimal Coordinates',
                        value: loc.formattedDecimal,
                        icon: FontAwesomeIcons.crosshairs,
                        isDark: isDark,
                        onCopy: () => _copy(loc.formattedDecimal, 'Decimal Coordinates'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CoordPill(
                        label: 'DMS Coordinates',
                        value: loc.formattedDms,
                        icon: FontAwesomeIcons.compass,
                        isDark: isDark,
                        onCopy: () => _copy(loc.formattedDms, 'DMS Coordinates'),
                      ),
                    ),
                  ],
                ),

                // Telemetry Details Row
                if (loc.altitude != null ||
                    loc.speed != null ||
                    loc.imgDirection != null ||
                    loc.gpsDateStamp != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (loc.altitude != null)
                        _TelemetryTag(
                          icon: FontAwesomeIcons.mountain,
                          label: 'Altitude',
                          value: '${loc.altitude!.toStringAsFixed(1)} m',
                          isDark: isDark,
                        ),
                      if (loc.speed != null)
                        _TelemetryTag(
                          icon: FontAwesomeIcons.gauge,
                          label: 'Speed',
                          value: '${loc.speed} km/h',
                          isDark: isDark,
                        ),
                      if (loc.imgDirection != null)
                        _TelemetryTag(
                          icon: FontAwesomeIcons.locationArrow,
                          label: 'Heading',
                          value: '${loc.imgDirection!.toStringAsFixed(1)}°',
                          isDark: isDark,
                        ),
                      if (loc.gpsDateStamp != null)
                        _TelemetryTag(
                          icon: FontAwesomeIcons.clock,
                          label: 'GPS Date',
                          value: loc.gpsDateStamp!,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordPill extends StatelessWidget {
  final String label;
  final String value;
  final FaIconData icon;
  final bool isDark;
  final VoidCallback onCopy;

  const _CoordPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? const Color(0xFF22262B) : const Color(0xFFE5E9EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 11, color: BrandColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: FaIcon(
                    FontAwesomeIcons.copy,
                    size: 11,
                    color: BrandColors.neutral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? BrandColors.white : BrandColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryTag extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _TelemetryTag({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFD3DCE4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: BrandColors.secondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9AA4B2) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? BrandColors.white : BrandColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
