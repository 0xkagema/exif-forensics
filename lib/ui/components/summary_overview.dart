import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../theme.dart';

class SummaryOverview extends StatelessWidget {
  final ForensicsReport report;
  final VoidCallback onNavigateToMap;
  final VoidCallback onNavigateToDevice;
  final VoidCallback onNavigateToPhotography;
  final VoidCallback onNavigateToTags;

  const SummaryOverview({
    super.key,
    required this.report,
    required this.onNavigateToMap,
    required this.onNavigateToDevice,
    required this.onNavigateToPhotography,
    required this.onNavigateToTags,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191C20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262C32)
        : const Color(0xFFE2E6EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stat Tiles Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 650 ? 3 : 2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth > 650 ? 2.1 : 1.7,
              children: [
                _StatTile(
                  icon: Icons.smart_toy,
                  title: 'AI Forensics',
                  value: report.aiDetection.isAiGenerated
                      ? 'AI Generated'
                      : report.aiDetection.classification ==
                            ForensicClassification.cameraOriginal
                      ? 'Optical Camera'
                      : 'Inconclusive',
                  subtitle: report.aiDetection.confidenceLabel,
                  iconColor: report.aiDetection.isAiGenerated
                      ? BrandColors.primary
                      : BrandColors.success,
                  isDark: isDark,
                ),
                _StatTile(
                  icon: Icons.location_on,
                  title: 'GPS Location',
                  value: report.hasLocation
                      ? report.location!.formattedDecimal
                      : 'No GPS Data',
                  subtitle: report.hasLocation
                      ? 'OpenStreetMap available'
                      : 'Coordinates missing',
                  iconColor: report.hasLocation
                      ? BrandColors.info
                      : BrandColors.neutral,
                  isDark: isDark,
                  onTap: report.hasLocation ? onNavigateToMap : null,
                ),
                _StatTile(
                  icon: Icons.camera_alt,
                  title: 'Capture Hardware',
                  value: report.device.displayName,
                  subtitle:
                      report.device.softwareVersion ?? 'Firmware unlisted',
                  iconColor: BrandColors.secondary,
                  isDark: isDark,
                  onTap: onNavigateToDevice,
                ),
                _StatTile(
                  icon: Icons.tune,
                  title: 'Photography',
                  value: report.photography.fNumber != null
                      ? 'f/${report.photography.fNumber} • ${report.photography.exposureTime ?? ""}'
                      : 'Sensor Data Present',
                  subtitle: report.photography.resolutionString,
                  iconColor: BrandColors.warning,
                  isDark: isDark,
                  onTap: onNavigateToPhotography,
                ),
                _StatTile(
                  icon: Icons.access_time,
                  title: 'Capture Timestamp',
                  value: report.captureDateTimeString ?? 'Not Recorded',
                  subtitle: report.timeZoneOffset != null
                      ? 'Offset: ${report.timeZoneOffset}'
                      : 'UTC / Local',
                  iconColor: BrandColors.info,
                  isDark: isDark,
                ),
                _StatTile(
                  icon: Icons.label,
                  title: 'IFD Tags Extracted',
                  value: '${report.rawTags.length} Tags',
                  subtitle:
                      '${report.groupedTags.keys.length} Categories parsed',
                  iconColor: BrandColors.primary,
                  isDark: isDark,
                  onTap: onNavigateToTags,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Timeline & History Card
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timeline,
                    size: 14,
                    color: BrandColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Temporal Timeline & Provenance Records',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TimelineEvent(
                icon: Icons.camera_alt,
                label: 'Original Shutter Capture',
                time: report.captureDateTimeString ?? 'Unknown / Not in EXIF',
                isRecorded: report.captureDateTimeString != null,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _TimelineEvent(
                icon: Icons.memory,
                label: 'Sensor Digitization',
                time:
                    report.digitizedDateTime?.toIso8601String() ??
                    'Same as original',
                isRecorded: report.digitizedDateTime != null,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _TimelineEvent(
                icon: Icons.edit,
                label: 'File Modification / Last Saved',
                time:
                    report.modifiedDateTime?.toIso8601String() ??
                    'No modification record',
                isRecorded: report.modifiedDateTime != null,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF262C32)
        : const Color(0xFFE2E6EA);
    final cardBg = isDark ? const Color(0xFF191C20) : Colors.white;

    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                    color: isDark
                        ? const Color(0xFF8B949E)
                        : const Color(0xFF57606A),
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward,
                  size: 10,
                  color: isDark
                      ? const Color(0xFF6E7681)
                      : const Color(0xFF8C959F),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              overflow: TextOverflow.ellipsis,
              color: isDark ? BrandColors.white : BrandColors.darkGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              overflow: TextOverflow.ellipsis,
              color: isDark ? const Color(0xFF7D8590) : const Color(0xFF6E7781),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      );
    }
    return content;
  }
}

class _TimelineEvent extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isRecorded;
  final bool isDark;

  const _TimelineEvent({
    required this.icon,
    required this.label,
    required this.time,
    required this.isRecorded,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isRecorded
                ? BrandColors.success.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF22272E) : const Color(0xFFECEFF2)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 11,
            color: isRecorded ? BrandColors.success : BrandColors.neutral,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? BrandColors.white : BrandColors.darkGrey,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  color: isRecorded
                      ? (isDark
                            ? const Color(0xFF88D2D0)
                            : const Color(0xFF0D7E7C))
                      : (isDark
                            ? BrandColors.neutral
                            : const Color(0xFF777777)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
