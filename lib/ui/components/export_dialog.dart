import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toastification/toastification.dart';
import '../../core/models/forensics_report.dart';
import '../../theme.dart';

void showExportDialog(BuildContext context, ForensicsReport report) {
  showDialog(
    context: context,
    builder: (context) => ExportDialog(report: report),
  );
}

class ExportDialog extends StatefulWidget {
  final ForensicsReport report;

  const ExportDialog({super.key, required this.report});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  int _selectedFormat = 0; // 0 = Markdown, 1 = JSON, 2 = Plain Text

  String get _currentContent {
    switch (_selectedFormat) {
      case 0:
        return widget.report.toMarkdownReport();
      case 1:
        return widget.report.toFormattedJson();
      case 2:
      default:
        return widget.report.toMarkdownReport();
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentContent));
    toastification.show(
      title: const Text('Copied to Clipboard'),
      description: Text(
        _selectedFormat == 0
            ? 'Markdown report copied'
            : _selectedFormat == 1
            ? 'JSON data copied'
            : 'Text summary copied',
      ),
      type: ToastificationType.success,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191C20) : const Color(0xFFF7F9FA);
    final borderColor = isDark
        ? const Color(0xFF2B3138)
        : const Color(0xFFE2E6EA);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.fileArrowDown,
                    color: BrandColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Forensics Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.white : BrandColors.darkGrey,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Format selector tabs
              Row(
                children: [
                  _FormatChoiceChip(
                    label: 'Markdown (.md)',
                    icon: FontAwesomeIcons.markdown,
                    isSelected: _selectedFormat == 0,
                    onTap: () => setState(() => _selectedFormat = 0),
                  ),
                  const SizedBox(width: 8),
                  _FormatChoiceChip(
                    label: 'JSON Data (.json)',
                    icon: FontAwesomeIcons.code,
                    isSelected: _selectedFormat == 1,
                    onTap: () => setState(() => _selectedFormat = 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Preview container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _currentContent,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFD4D8DD)
                            : const Color(0xFF2C3238),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                      foregroundColor: BrandColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.copy, size: 14),
                    label: const Text('Copy to Clipboard'),
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

class _FormatChoiceChip extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? BrandColors.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E2328) : const Color(0xFFEAEFF2)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? BrandColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 13,
              color: isSelected
                  ? BrandColors.primary
                  : (isDark ? BrandColors.neutral : const Color(0xFF555555)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? BrandColors.primary
                    : (isDark ? BrandColors.white : BrandColors.darkGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
