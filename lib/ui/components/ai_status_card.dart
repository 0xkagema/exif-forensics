import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// switched to Material icons; removed font_awesome_flutter import
import 'package:toastification/toastification.dart';

import '../../core/models/models.dart';
import '../../extensions.dart';
import '../../theme.dart';

class AiStatusCard extends StatelessWidget {
  final AiDetectionResult aiDetection;

  const AiStatusCard({super.key, required this.aiDetection});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191C20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262C32)
        : const Color(0xFFE2E6EA);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final c2pa = aiDetection.c2paData;
    final sig = aiDetection.c2paSignature;
    final aiDetails = aiDetection.c2paAiDetails;
    final actions = aiDetection.c2paActionSummaries;
    final validation = aiDetection.c2paValidation;

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 16),
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
                                color: isDark
                                    ? BrandColors.white
                                    : BrandColors.darkGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                          if (aiDetection.hasC2paManifest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BrandColors.info.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: BrandColors.info.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 9,
                                    color: BrandColors.info,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'C2PA Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: BrandColors.info,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'AI & Provenance Forensics',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? BrandColors.neutral
                                  : const Color(0xFF666666),
                            ),
                          ),
                          if (c2pa != null && c2pa.hasC2pa) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• Rust C2PA Engine',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.secondary,
                              ),
                            ),
                          ],
                        ],
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
                    color: isDark
                        ? const Color(0xFFD0D6DC)
                        : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),

                // Generator & Model pills if detected
                if (aiDetection.generator != null ||
                    aiDetection.model != null ||
                    aiDetails?.company != null ||
                    aiDetails?.digitalSourceType != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (aiDetection.generator != null)
                        _DetailChip(
                          icon: Icons.settings,
                          label: 'Engine / Tool',
                          value: aiDetection.generator!,
                          isDark: isDark,
                        ),
                      if (aiDetection.model != null)
                        _DetailChip(
                          icon: Icons.widgets,
                          label: 'Model',
                          value: aiDetection.model!,
                          isDark: isDark,
                        ),
                      if (aiDetails?.company != null &&
                          aiDetails!.company != aiDetection.generator)
                        _DetailChip(
                          icon: Icons.apartment,
                          label: 'Organization',
                          value: aiDetails.company!,
                          isDark: isDark,
                        ),
                      if (aiDetails?.digitalSourceType != null)
                        _DetailChip(
                          icon: Icons.fingerprint,
                          label: 'IPTC Source',
                          value: aiDetails!.digitalSourceType!.split('/').last,
                          isDark: isDark,
                        ),
                      if (aiDetails?.generationDate != null)
                        _DetailChip(
                          icon: Icons.calendar_today,
                          label: 'Generated On',
                          value: aiDetails?.generationDate ?? '',
                          isDark: isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Rich C2PA Manifest & Certificate Details Card
                if (aiDetection.hasC2paManifest) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141A22)
                          : const Color(0xFFF0F6FC),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFD0D7DE),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield,
                                  color: BrandColors.info,
                                  size: 15,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'C2PA Cryptographic Provenance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? BrandColors.white
                                        : BrandColors.darkGrey,
                                  ),
                                ),
                              ],
                            ),
                            if (sig?.validationState != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (sig!.isSignatureValid
                                              ? BrandColors.success
                                              : BrandColors.danger)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        (sig.isSignatureValid
                                                ? BrandColors.success
                                                : BrandColors.danger)
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'Signature ${sig.validationState}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: sig.isSignatureValid
                                        ? BrandColors.success
                                        : BrandColors.danger,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Certificate / Signer Rows
                        if (sig != null) ...[
                          _C2paDataRow(
                            label: 'Signer Issuer',
                            value: sig.issuer ?? 'Unspecified Issuer',
                            isDark: isDark,
                          ),
                          if (sig.commonName != null &&
                              sig.commonName != sig.issuer)
                            _C2paDataRow(
                              label: 'Common Name (CN)',
                              value: sig.commonName!,
                              isDark: isDark,
                            ),
                          if (sig.algorithm != null)
                            _C2paDataRow(
                              label: 'Crypto Algorithm',
                              value: sig.algorithm!.toUpperCase(),
                              isDark: isDark,
                            ),
                          if (sig.signingTime != null)
                            _C2paDataRow(
                              label: 'Signing Timestamp',
                              value: sig.signingTime!,
                              isDark: isDark,
                            ),
                          if (sig.certSerialNumber != null)
                            _C2paDataRow(
                              label: 'Cert Serial',
                              value: sig.certSerialNumber!,
                              isDark: isDark,
                              isMonospace: true,
                              onCopy: () => _copyText(
                                context,
                                sig.certSerialNumber!,
                                'Certificate Serial',
                              ),
                            ),
                        ],

                        if (c2pa?.manifest?.claimGenerator != null)
                          _C2paDataRow(
                            label: 'Claim Generator',
                            value: c2pa!.manifest!.claimGenerator!,
                            isDark: isDark,
                          ),

                        const SizedBox(height: 10),

                        // Actions / View Raw JSON Buttons
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showRawManifestDialog(context, isDark),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.code, size: 11),
                              label: const Text(
                                'Inspect Manifest JSON',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Provenance Actions History (Timeline of operations)
                if (actions.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.list_alt,
                        size: 13,
                        color: BrandColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'C2PA Provenance History (${actions.length} Action${actions.length > 1 ? "s" : ""})',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? BrandColors.white
                              : BrandColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14181D)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF22272E)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (int i = 0; i < actions.length; i++) ...[
                          _ActionHistoryItem(
                            action: actions[i],
                            isDark: isDark,
                            isLast: i == actions.length - 1,
                          ),
                          if (i < actions.length - 1)
                            const Divider(height: 16, thickness: 0.5),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Cryptographic Validation Findings (Successes, Informational, Warnings)
                if (validation != null &&
                    (validation.successes.isNotEmpty ||
                        validation.informational.isNotEmpty ||
                        validation.failures.isNotEmpty)) ...[
                  Text(
                    'Cryptographic Integrity Findings',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (validation.successes.isNotEmpty)
                        _ValidationBadge(
                          count: validation.successes.length,
                          label: 'Passed Checks',
                          color: BrandColors.success,
                          icon: Icons.check_circle,
                          isDark: isDark,
                        ),
                      if (validation.informational.isNotEmpty)
                        _ValidationBadge(
                          count: validation.informational.length,
                          label: 'Notices',
                          color: BrandColors.info,
                          icon: Icons.info,
                          isDark: isDark,
                        ),
                      if (validation.failures.isNotEmpty)
                        _ValidationBadge(
                          count: validation.failures.length,
                          label: 'Failures',
                          color: BrandColors.danger,
                          icon: Icons.warning,
                          isDark: isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Embedded Prompt Inspector if available
                if (aiDetection.prompt != null &&
                    aiDetection.prompt!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.terminal,
                            size: 12,
                            color: BrandColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Embedded Generation Prompt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? BrandColors.white
                                  : BrandColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () =>
                            _copyText(context, aiDetection.prompt!, 'Prompt'),
                        tooltip: 'Copy Prompt',
                        icon: const Icon(Icons.copy, size: 12),
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
                      color: isDark
                          ? const Color(0xFF121417)
                          : const Color(0xFFF3F5F7),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF22272E)
                            : const Color(0xFFE2E7EC),
                      ),
                    ),
                    child: SelectableText(
                      aiDetection.prompt!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFC0CAD5)
                            : const Color(0xFF2D3748),
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
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sig,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFFB5BDC6)
                                    : const Color(0xFF4B5563),
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

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    context.showSuccessToast('$label copied to clipboard', title: 'Copied');
  }

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

  IconData _getStatusIcon() {
    switch (aiDetection.classification) {
      case ForensicClassification.aiGenerated:
        return Icons.smart_toy;
      case ForensicClassification.cameraOriginal:
        return Icons.camera_alt;
      case ForensicClassification.digitallyEdited:
        return Icons.edit;
      case ForensicClassification.inconclusive:
        return Icons.help;
    }
  }

  void _showRawManifestDialog(BuildContext context, bool isDark) {
    final rawManifest = aiDetection.c2paRawManifest;
    final jsonString = rawManifest != null
        ? const JsonEncoder.withIndent('  ').convert(rawManifest)
        : const JsonEncoder.withIndent(
            '  ',
          ).convert(aiDetection.c2paData?.toMap() ?? {});

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF16191E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark ? const Color(0xFF2E353D) : const Color(0xFFE2E7EC),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.code,
                            size: 16,
                            color: BrandColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Raw C2PA Manifest JSON',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? BrandColors.white
                                  : BrandColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _copyText(
                              context,
                              jsonString,
                              'Raw Manifest JSON',
                            ),
                            tooltip: 'Copy JSON',
                            icon: const Icon(Icons.copy, size: 14),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1115)
                            : const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF22272E)
                              : const Color(0xFFE2E7EC),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          jsonString,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.45,
                            color: isDark
                                ? const Color(0xFFC0CAD5)
                                : const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionHistoryItem extends StatelessWidget {
  final C2paActionSummary action;
  final bool isDark;
  final bool isLast;

  const _ActionHistoryItem({
    required this.action,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                (action.isAiAction
                        ? BrandColors.primary
                        : BrandColors.secondary)
                    .withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            action.isAiAction ? Icons.smart_toy : Icons.settings,
            size: 11,
            color: action.isAiAction
                ? BrandColors.primary
                : BrandColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    action.action,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                  if (action.isAiAction) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'AI Action',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (action.softwareAgent != null ||
                  action.softwareAgentName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Tool: ${action.softwareAgent ?? action.softwareAgentName!}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF4B5563),
                  ),
                ),
              ],
              if (action.when != null) ...[
                const SizedBox(height: 2),
                Text(
                  'When: ${action.when!}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? BrandColors.neutral
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _C2paDataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isMonospace;
  final VoidCallback? onCopy;

  const _C2paDataRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isMonospace = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF8B949E)
                    : const Color(0xFF57606A),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: isMonospace ? 'monospace' : null,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                ),
                if (onCopy != null)
                  InkWell(
                    onTap: onCopy,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.copy,
                        size: 11,
                        color: isDark
                            ? BrandColors.neutral
                            : const Color(0xFF6E7681),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
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
          Icon(icon, size: 11, color: BrandColors.secondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? BrandColors.neutral : const Color(0xFF64748B),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? BrandColors.white : BrandColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _ValidationBadge({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
