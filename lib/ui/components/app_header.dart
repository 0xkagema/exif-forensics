import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/state/forensics_controller.dart';
import '../../theme.dart';
import 'export_dialog.dart';

class AppHeader extends StatelessWidget {
  final ForensicsController controller;

  const AppHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF14171A) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262B30)
        : const Color(0xFFE5E8EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Logo & App Title
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: BrandColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const FaIcon(
              FontAwesomeIcons.shieldHalved,
              color: BrandColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EXIF Forensics',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.tertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OSINT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Image Metadata & C2PA Provenance Inspector',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? BrandColors.neutral : const Color(0xFF666666),
                ),
              ),
            ],
          ),

          const Spacer(),

          // If report is available, show action buttons
          if (controller.isSuccess && controller.report != null) ...[
            // File badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2328)
                    : const Color(0xFFF0F3F6),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.fileImage,
                    size: 13,
                    color: BrandColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      controller.report!.file.fileName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                        color: isDark
                            ? BrandColors.white
                            : BrandColors.darkGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Export report button
            OutlinedButton.icon(
              onPressed: () => showExportDialog(context, controller.report!),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.fileArrowDown, size: 14),
              label: const Text('Export', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),

            // New Scan Button
            ElevatedButton.icon(
              onPressed: () => controller.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                foregroundColor: BrandColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.arrowRotateLeft, size: 13),
              label: const Text('New Scan', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],

          // Theme toggle button
          IconButton(
            onPressed: () => controller.toggleTheme(),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            icon: FaIcon(
              isDark ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
              size: 16,
              color: isDark ? const Color(0xFFFFD166) : BrandColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
