import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../core/models/models.dart';
import '../../extensions.dart';
import '../../theme.dart';

class ImagePreviewCard extends StatelessWidget {
  final Uint8List? imageBytes;
  final FileMetadata file;
  final String? resolution;

  const ImagePreviewCard({
    super.key,
    required this.imageBytes,
    required this.file,
    this.resolution,
  });

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
          // Image Preview Container
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  color: isDark
                      ? const Color(0xFF0F1113)
                      : const Color(0xFFF0F3F5),
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: BrandColors.neutral,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: BrandColors.neutral,
                          ),
                        ),
                ),

                // Zoom button overlay
                if (imageBytes != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: InkWell(
                        onTap: () => _showZoomDialog(context),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.open_in_full,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Resolution & Format Pill overlay
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      resolution ?? file.dimensionsString,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File Info & Hashes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File name & Size row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.fileName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                          color: isDark
                              ? BrandColors.white
                              : BrandColors.darkGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        file.formattedSize,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? BrandColors.secondary
                              : BrandColors.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  file.mimeType,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? BrandColors.neutral
                        : const Color(0xFF6B7280),
                  ),
                ),
                const Divider(height: 24),

                // Hashes section title
                Row(
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      size: 13,
                      color: BrandColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cryptographic Hashes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark
                            ? BrandColors.white
                            : BrandColors.darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // MD5 Row
                _HashRow(
                  label: 'MD5',
                  hash: file.md5Hash,
                  onCopy: () => _copyToClipboard(context, file.md5Hash, 'MD5'),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),

                // SHA-256 Row
                _HashRow(
                  label: 'SHA-256',
                  hash: file.sha256Hash,
                  onCopy: () =>
                      _copyToClipboard(context, file.sha256Hash, 'SHA-256'),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    context.showSuccessToast('$label copied to clipboard', title: 'Copied');
  }

  void _showZoomDialog(BuildContext context) {
    if (imageBytes == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(imageBytes!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HashRow extends StatelessWidget {
  final String label;
  final String hash;
  final VoidCallback onCopy;
  final bool isDark;

  const _HashRow({
    required this.label,
    required this.hash,
    required this.onCopy,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark ? const Color(0xFF22262B) : const Color(0xFFE5E9EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222830) : const Color(0xFFE2E7EC),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFBAC2CB)
                    : const Color(0xFF424A53),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hash,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                overflow: TextOverflow.ellipsis,
                color: isDark
                    ? const Color(0xFFB0B7C0)
                    : const Color(0xFF333B44),
              ),
            ),
          ),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy, size: 11, color: BrandColors.neutral),
            ),
          ),
        ],
      ),
    );
  }
}
