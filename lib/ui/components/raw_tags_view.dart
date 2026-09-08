import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../core/state/forensics_controller.dart';
import '../../extensions.dart';
import '../../theme.dart';

class RawTagsView extends StatelessWidget {
  final ForensicsController controller;

  const RawTagsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191C20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262C32)
        : const Color(0xFFE2E6EA);
    final filteredTags = controller.filteredRawTags;
    final totalTags = controller.report?.rawTags.length ?? 0;
    final categories = [
      'All',
      'EXIF',
      'GPS',
      'Image',
      'Interoperability',
      'MakerNote',
      'Thumbnail',
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BrandColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.label,
                        color: BrandColors.info,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raw EXIF IFD Directory',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? BrandColors.white
                                  : BrandColors.darkGrey,
                            ),
                          ),
                          Text(
                            'Showing ${filteredTags.length} of $totalTags extracted tags',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? BrandColors.neutral
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (filteredTags.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _copyAllTags(context, filteredTags),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.copy, size: 12),
                        label: const Text(
                          'Copy All',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Input Field
                TextField(
                  onChanged: (val) => controller.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText:
                        'Search tag name or value (e.g. GPS, Shutter, ISO, Make)...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, size: 14),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14),
                            onPressed: () => controller.setSearchQuery(''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected =
                          (controller.selectedTagCategory == null &&
                              cat == 'All') ||
                          controller.selectedTagCategory == cat;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            controller.setSelectedTagCategory(
                              selected ? cat : 'All',
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tags List
          if (filteredTags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.filter_alt_off,
                      size: 28,
                      color: BrandColors.neutral,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No matching EXIF tags found',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? BrandColors.white
                            : BrandColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try clearing the search query or changing the filter category.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? BrandColors.neutral
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTags.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = filteredTags.entries.elementAt(index);
                final key = entry.key;
                final value = entry.value.toString();
                final tagCategory = key.contains(' ')
                    ? key.split(' ').first
                    : 'TAG';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF22272E)
                              : const Color(0xFFE2E7ED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tagCategory,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF8B949E)
                                : const Color(0xFF57606A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Key name
                      Expanded(
                        flex: 4,
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFD2D9E0)
                                : const Color(0xFF24292F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Value
                      Expanded(
                        flex: 6,
                        child: SelectableText(
                          value,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF7EE787)
                                : const Color(0xFF116329),
                          ),
                        ),
                      ),

                      // Copy button
                      IconButton(
                        onPressed: () => _copyTag(context, key, value),
                        tooltip: 'Copy tag',
                        icon: const Icon(
                          Icons.copy,
                          size: 12,
                          color: BrandColors.neutral,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _copyAllTags(BuildContext context, Map<String, dynamic> tags) {
    final buffer = StringBuffer();
    for (final entry in tags.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    context.showSuccessToast('All tags copied to clipboard', title: 'Copied');
  }

  void _copyTag(BuildContext context, String key, String value) {
    Clipboard.setData(ClipboardData(text: '$key: $value'));
    context.showSuccessToast('$key copied to clipboard', title: 'Copied');
  }
}
