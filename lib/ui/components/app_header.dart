import 'package:flutter/material.dart';

// using Material icons instead of FontAwesome

import '../../core/state/forensics_controller.dart';
import '../../theme.dart';
import 'export_dialog.dart';

class AppHeader extends StatelessWidget {
  final ForensicsController controller;

  const AppHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF262B30)
        : const Color(0xFFE5E8EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

      child: Row(
        children: [
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
                  const Icon(
                    Icons.image,
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
              icon: const Icon(Icons.file_download, size: 14),
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
              icon: const Icon(Icons.rotate_left, size: 13),
              label: const Text('New Scan', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],

          // Theme toggle button
          IconButton(
            onPressed: () => controller.toggleTheme(),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              size: 16,
              color: isDark ? const Color(0xFFFFD166) : BrandColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
