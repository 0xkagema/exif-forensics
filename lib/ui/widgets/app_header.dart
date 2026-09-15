import 'package:flutter/material.dart';

import '../../core/state/forensics_controller.dart';
import '../../theme.dart';
import 'export_dialog.dart';

class AppHeader extends StatelessWidget {
  final ForensicsController controller;

  const AppHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final isVeryCompact = constraints.maxWidth < 460;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Right-aligned action buttons
              if (controller.isSuccess && controller.report != null) ...[
                // Export report button
                if (isVeryCompact)
                  Tooltip(
                    message: 'Export Report',
                    child: OutlinedButton(
                      onPressed: () =>
                          showExportDialog(context, controller.report!),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Icon(Icons.file_download, size: 14),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () =>
                        showExportDialog(context, controller.report!),
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
                if (isVeryCompact)
                  Tooltip(
                    message: 'New Scan',
                    child: ElevatedButton(
                      onPressed: () => controller.reset(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        foregroundColor: BrandColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Icon(Icons.rotate_left, size: 13),
                    ),
                  )
                else
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
                    label: const Text(
                      'New Scan',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
              ],

              // Theme toggle button
              IconButton(
                onPressed: () => controller.toggleTheme(),
                tooltip: isDark
                    ? 'Switch to Light Theme'
                    : 'Switch to Dark Theme',
                icon: Icon(
                  isDark ? Icons.wb_sunny : Icons.nightlight_round,
                  size: 16,
                  color: isDark
                      ? const Color(0xFFFFD166)
                      : BrandColors.tertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
