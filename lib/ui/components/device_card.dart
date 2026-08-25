import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toastification/toastification.dart';
import '../../core/models/models.dart';
import '../../theme.dart';

class DeviceCard extends StatelessWidget {
  final DeviceDetails device;

  const DeviceCard({super.key, required this.device});

  void _copy(BuildContext context, String text, String label) {
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
                    FontAwesomeIcons.cameraRetro,
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
                        'Device & Hardware Forensics',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? BrandColors.white : BrandColors.darkGrey,
                        ),
                      ),
                      Text(
                        device.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? BrandColors.neutral : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DeviceInfoTile(
                  icon: FontAwesomeIcons.industry,
                  title: 'Manufacturer',
                  value: device.manufacturer ?? 'Not Specified',
                  isDark: isDark,
                  onCopy: device.manufacturer != null
                      ? () => _copy(context, device.manufacturer!, 'Manufacturer')
                      : null,
                ),
                const SizedBox(height: 12),
                _DeviceInfoTile(
                  icon: FontAwesomeIcons.camera,
                  title: 'Device Model',
                  value: device.model ?? 'Not Specified',
                  isDark: isDark,
                  onCopy: device.model != null
                      ? () => _copy(context, device.model!, 'Device Model')
                      : null,
                ),
                const SizedBox(height: 12),
                _DeviceInfoTile(
                  icon: FontAwesomeIcons.microchip,
                  title: 'Software / Firmware',
                  value: device.softwareVersion ?? 'Not Specified',
                  isDark: isDark,
                  onCopy: device.softwareVersion != null
                      ? () => _copy(context, device.softwareVersion!, 'Software Version')
                      : null,
                ),
                const SizedBox(height: 12),
                _DeviceInfoTile(
                  icon: FontAwesomeIcons.circleDot,
                  title: 'Lens Model',
                  value: device.lensModel ?? device.lensSpecification ?? 'Not Specified',
                  isDark: isDark,
                  onCopy: (device.lensModel ?? device.lensSpecification) != null
                      ? () => _copy(
                            context,
                            device.lensModel ?? device.lensSpecification!,
                            'Lens Model',
                          )
                      : null,
                ),
                if (device.bodySerialNumber != null || device.lensSerialNumber != null) ...[
                  const SizedBox(height: 12),
                  _DeviceInfoTile(
                    icon: FontAwesomeIcons.barcode,
                    title: 'Serial Number',
                    value: device.bodySerialNumber ?? device.lensSerialNumber ?? 'N/A',
                    isDark: isDark,
                    onCopy: () => _copy(
                      context,
                      device.bodySerialNumber ?? device.lensSerialNumber!,
                      'Serial Number',
                    ),
                  ),
                ],
                if (device.artist != null || device.copyright != null) ...[
                  const SizedBox(height: 12),
                  _DeviceInfoTile(
                    icon: FontAwesomeIcons.userPen,
                    title: 'Photographer / Artist',
                    value: device.artist ?? device.copyright ?? 'N/A',
                    isDark: isDark,
                    onCopy: () => _copy(
                      context,
                      device.artist ?? device.copyright!,
                      'Photographer',
                    ),
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

class _DeviceInfoTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String value;
  final bool isDark;
  final VoidCallback? onCopy;

  const _DeviceInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isSpecified = value != 'Not Specified' && value != 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? const Color(0xFF22262B) : const Color(0xFFE5E9EC),
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 14,
            color: isSpecified ? BrandColors.secondary : BrandColors.neutral,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF9EA7B3) : const Color(0xFF57606A),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSpecified ? FontWeight.w700 : FontWeight.w400,
                color: isSpecified
                    ? (isDark ? BrandColors.white : BrandColors.darkGrey)
                    : (isDark ? const Color(0xFF6E7681) : const Color(0xFF8C959F)),
              ),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: FaIcon(
                  FontAwesomeIcons.copy,
                  size: 11,
                  color: BrandColors.neutral,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
