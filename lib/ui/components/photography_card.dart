import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/models.dart';
import '../../theme.dart';

class PhotographyCard extends StatelessWidget {
  final PhotographyDetails photography;

  const PhotographyCard({super.key, required this.photography});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191C20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262C32)
        : const Color(0xFFE2E6EA);

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
                    color: BrandColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.sliders,
                    color: BrandColors.secondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photography & Optical Settings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? BrandColors.white
                            : BrandColors.darkGrey,
                      ),
                    ),
                    Text(
                      'Sensor parameters, exposure, and color calibration',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? BrandColors.neutral
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Primary Exposure Metrics Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 550 ? 4 : 2;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth > 550 ? 1.6 : 1.7,
                  children: [
                    _MetricTile(
                      icon: FontAwesomeIcons.gaugeHigh,
                      label: 'Shutter Speed',
                      value:
                          photography.exposureTime ??
                          photography.shutterSpeed ??
                          'N/A',
                      isDark: isDark,
                    ),
                    _MetricTile(
                      icon: FontAwesomeIcons.camera,
                      label: 'Aperture',
                      value: photography.fNumber != null
                          ? 'f/${photography.fNumber}'
                          : 'N/A',
                      isDark: isDark,
                    ),
                    _MetricTile(
                      icon: FontAwesomeIcons.film,
                      label: 'ISO Sensitivity',
                      value: photography.iso ?? 'N/A',
                      isDark: isDark,
                    ),
                    _MetricTile(
                      icon: FontAwesomeIcons.rulerHorizontal,
                      label: 'Focal Length',
                      value: photography.focalLength ?? 'N/A',
                      subtitle: photography.focalLength35mm != null
                          ? '35mm: ${photography.focalLength35mm}mm'
                          : null,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ),

          // Additional Photography Details List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _DetailRow(
                  icon: FontAwesomeIcons.bolt,
                  label: 'Flash Status',
                  value: photography.flash ?? 'Not recorded',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: FontAwesomeIcons.sun,
                  label: 'White Balance',
                  value: photography.whiteBalance ?? 'Auto / Not recorded',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: FontAwesomeIcons.bullseye,
                  label: 'Metering Mode',
                  value: photography.meteringMode ?? 'Not recorded',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: FontAwesomeIcons.palette,
                  label: 'Color Space',
                  value: photography.colorSpace ?? 'sRGB / Standard',
                  isDark: isDark,
                ),
                if (photography.exposureProgram != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: FontAwesomeIcons.barsProgress,
                    label: 'Exposure Program',
                    value: photography.exposureProgram!,
                    isDark: isDark,
                  ),
                ],
                if (photography.orientation != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: FontAwesomeIcons.rotate,
                    label: 'Orientation',
                    value: photography.orientation!,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool isDark;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFF3F6F8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? const Color(0xFF22262B) : const Color(0xFFE2E7EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 12, color: BrandColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                    color: isDark
                        ? const Color(0xFF8B949E)
                        : const Color(0xFF6E7781),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              overflow: TextOverflow.ellipsis,
              color: isDark ? BrandColors.white : BrandColors.darkGrey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? BrandColors.neutral : const Color(0xFF888888),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark ? const Color(0xFF202428) : const Color(0xFFE9ECEF),
        ),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 12, color: BrandColors.secondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9AA4B0) : const Color(0xFF555E68),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? BrandColors.white : BrandColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
