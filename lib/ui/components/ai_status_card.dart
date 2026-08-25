import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toastification/toastification.dart';
import '../../core/models/models.dart';
import '../../theme.dart';

class AiStatusCard extends StatelessWidget {
  final AiDetectionResult aiDetection;

  const AiStatusCard({super.key, required this.aiDetection});

  Color _getStatusColor() {
    switch (aiDetection.classification) {
      case ForensicClassification.aiGenerated:
        return BrandColors.primary;
      case ForensicClassification.cameraOriginal:
        return BrandColors.success;
      case ForensicClassification.digitallyEdited:
        return BrandColors.warning;
      case ForensicClassification.inconclusive:
        return BrandColors.neutral;
    }
  }

  FaIconData _getStatusIcon() {
    switch (aiDetection.classification) {
      case ForensicClassification.aiGenerated:
        return FontAwesomeIcons.robot;
      case ForensicClassification.cameraOriginal:
        return FontAwesomeIcons.camera;
      case ForensicClassification.digitallyEdited:
        return FontAwesomeIcons.penToSquare;
      case ForensicClassification.inconclusive:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  void _copyText(BuildContext context, String text, String label) {
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
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    statusIcon,
                    color: statusColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              aiDetection.verdict,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? BrandColors.white : BrandColors.darkGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              aiDetection.confidenceLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AI & Provenance Forensics',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? BrandColors.neutral : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explanation text
                Text(
                  aiDetection.explanation,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? const Color(0xFFD0D6DC) : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),

                // Generator & Model pills if detected
                if (aiDetection.generator != null || aiDetection.model != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (aiDetection.generator != null)
                        _DetailChip(
                          icon: FontAwesomeIcons.gears,
                          label: 'Engine',
                          value: aiDetection.generator!,
                          isDark: isDark,
                        ),
                      if (aiDetection.model != null)
                        _DetailChip(
                          icon: FontAwesomeIcons.cube,
                          label: 'Model',
                          value: aiDetection.model!,
                          isDark: isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // C2PA Manifest Banner
                if (aiDetection.hasC2paManifest) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BrandColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: BrandColors.info.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.certificate,
                          color: BrandColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'C2PA Content Credentials Verified',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: BrandColors.info,
                                ),
                              ),
                              if (aiDetection.c2paIssuer != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Issuer: ${aiDetection.c2paIssuer}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFFC5CEE0) : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                              if (aiDetection.c2paActions.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Actions: ${aiDetection.c2paActions.join(", ")}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? BrandColors.neutral : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Embedded Prompt Inspector if available
                if (aiDetection.prompt != null && aiDetection.prompt!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.terminal,
                            size: 12,
                            color: BrandColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Embedded Generation Prompt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? BrandColors.white : BrandColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _copyText(context, aiDetection.prompt!, 'Prompt'),
                        tooltip: 'Copy Prompt',
                        icon: const FaIcon(FontAwesomeIcons.copy, size: 12),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121417) : const Color(0xFFF3F5F7),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: isDark ? const Color(0xFF22272E) : const Color(0xFFE2E7EC),
                      ),
                    ),
                    child: SelectableText(
                      aiDetection.prompt!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.4,
                        color: isDark ? const Color(0xFFC0CAD5) : const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Detected signatures / evidence checklist
                if (aiDetection.detectedSignatures.isNotEmpty) ...[
                  Text(
                    'Forensic Evidence Markers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...aiDetection.detectedSignatures.map(
                    (sig) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sig,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFB5BDC6) : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _DetailChip extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailChip({
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
        color: isDark ? const Color(0xFF21262D) : const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1),
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
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? BrandColors.neutral : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? BrandColors.white : BrandColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
