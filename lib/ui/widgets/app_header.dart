import 'package:flutter/material.dart';

import '../../core/state/forensics_controller.dart';
import '../../theme.dart';
import 'export_dialog.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final ForensicsController controller;

  const AppHeader({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 560;
    final isVeryCompact = screenWidth < 400;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: isCompact ? 16 : 24,
      title: Text(
        'EXIF Forensics',
        style: TextStyle(
          fontSize: isCompact ? 16 : 18,
          fontWeight: FontWeight.w700,
          color: isDark ? BrandColors.white : BrandColors.darkGrey,
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 8,
      ),
      actions: [
        if (controller.isSuccess && controller.report != null) ...[
          _HeaderAction(
            tooltip: 'Export Report',
            onPressed: () => showExportDialog(context, controller.report!),
            isCompact: isCompact,
            icon: Icons.file_download,
            label: 'Export',
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            tooltip: 'New Scan',
            onPressed: controller.reset,
            isCompact: isCompact,
            icon: Icons.rotate_left,
            label: 'New Scan',
            isPrimary: true,
          ),
          const SizedBox(width: 8),
        ],
        Tooltip(
          message: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          child: IconButton(
            onPressed: controller.toggleTheme,
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              size: isVeryCompact ? 20 : 21,
              color: isDark ? const Color(0xFFFFD166) : BrandColors.tertiary,
            ),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final bool isCompact;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _HeaderAction({
    required this.tooltip,
    required this.onPressed,
    required this.isCompact,
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: BrandColors.primary,
            foregroundColor: BrandColors.white,
            minimumSize: Size(isCompact ? 48 : 0, 48),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: BrandColors.primary,
            minimumSize: Size(isCompact ? 48 : 0, 48),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          );

    final Widget button;
    if (isCompact) {
      button = isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Icon(icon, size: 20),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Icon(icon, size: 20),
            );
    } else {
      button = isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 18),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 18),
              label: Text(label),
            );
    }

    return Tooltip(message: tooltip, child: button);
  }
}
