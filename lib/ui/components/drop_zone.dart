import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../core/state/forensics_controller.dart';
import '../../theme.dart';

class DropZone extends StatefulWidget {
  final ForensicsController controller;

  const DropZone({super.key, required this.controller});

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = BrandColors.primary;
    final dragHoverColor = BrandColors.success;
    final cardBg = isDark ? const Color(0xFF16191D) : const Color(0xFFF9FBFC);
    final borderColor = _isDragging
        ? dragHoverColor
        : (isDark ? const Color(0xFF2E353D) : const Color(0xFFCCD4DC));

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title & Subtitle
              Text(
                'Extract Deep Intelligence From Any Image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? BrandColors.white : BrandColors.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inspect GPS coordinates, camera hardware sensors, exposure metrics, C2PA manifests, and detect AI-generated imagery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? BrandColors.neutral : const Color(0xFF5A626A),
                ),
              ),
              const SizedBox(height: 28),

              // Drop Target Box
              DropTarget(
                onDragDone: (detail) async {
                  if (detail.files.isEmpty) return;
                  if (detail.files.length > 1) {
                    toastification.show(
                      title: const Text("Multiple Files Detected"),
                      description: const Text(
                        "Analyzing the first dropped image.",
                      ),
                      type: ToastificationType.info,
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  }

                  final file = detail.files.first;
                  final bytes = await file.readAsBytes();
                  widget.controller.analyzeBytes(bytes, file.name);
                },
                onDragEntered: (_) => setState(() => _isDragging = true),
                onDragExited: (_) => setState(() => _isDragging = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? dragHoverColor.withValues(alpha: 0.08)
                        : cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      if (_isDragging)
                        BoxShadow(
                          color: dragHoverColor.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      dashPattern: const [8, 6],
                      strokeWidth: 2,
                      color: borderColor,
                      radius: const Radius.circular(AppRadius.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drop Icon
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: _isDragging
                                  ? dragHoverColor.withValues(alpha: 0.15)
                                  : primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FaIcon(
                                _isDragging
                                    ? FontAwesomeIcons.fileCirclePlus
                                    : FontAwesomeIcons.cloudArrowUp,
                                color: _isDragging
                                    ? dragHoverColor
                                    : primaryColor,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Prompt Text
                          Text(
                            _isDragging
                                ? 'Drop image now to begin investigation'
                                : 'Drag & drop your image here',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? BrandColors.white
                                  : BrandColors.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Supports JPG, PNG, WebP, TIFF, and HEIC files',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? BrandColors.neutral
                                  : const Color(0xFF777777),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Browse button
                          ElevatedButton.icon(
                            onPressed: () => widget.controller.pickAndAnalyze(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: BrandColors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              elevation: 3,
                            ),
                            icon: const FaIcon(
                              FontAwesomeIcons.folderOpen,
                              size: 15,
                            ),
                            label: const Text(
                              'Browse File',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Feature Highlights Row
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FeaturePill(
                    icon: FontAwesomeIcons.robot,
                    label: 'AI & C2PA Detection',
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    icon: FontAwesomeIcons.locationDot,
                    label: 'GPS Map Telemetry',
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    icon: FontAwesomeIcons.cameraRetro,
                    label: 'Camera & Lens Hardware',
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    icon: FontAwesomeIcons.fingerprint,
                    label: 'Cryptographic Hashes',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool isDark;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2025) : const Color(0xFFF0F4F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E363E) : const Color(0xFFDCE2E7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: BrandColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD2D9) : const Color(0xFF48515B),
            ),
          ),
        ],
      ),
    );
  }
}
