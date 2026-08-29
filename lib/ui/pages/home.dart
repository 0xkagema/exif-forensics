import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/state/forensics_controller.dart';
import '../../theme.dart';
import '../components/components.dart';

class HomePage extends StatefulWidget {
  final ForensicsController controller;

  const HomePage({super.key, required this.controller});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D0F11)
          : const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            AppHeader(controller: controller),

            // Main View Body
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(context, controller, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  Widget _buildActiveTabContent(ForensicsController controller, bool isDark) {
    final report = controller.report!;

    switch (controller.activeTabIndex) {
      case 0:
        return SummaryOverview(
          report: report,
          onNavigateToMap: () => controller.setActiveTab(3),
          onNavigateToDevice: () => controller.setActiveTab(1),
          onNavigateToPhotography: () => controller.setActiveTab(2),
          onNavigateToTags: () => controller.setActiveTab(4),
        );
      case 1:
        return DeviceCard(device: report.device);
      case 2:
        return PhotographyCard(photography: report.photography);
      case 3:
        return LocationMapView(location: report.location);
      case 4:
        return RawTagsView(controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBody(
    BuildContext context,
    ForensicsController controller,
    bool isDark,
  ) {
    switch (controller.status) {
      case ForensicsStatus.initial:
        return DropZone(controller: controller);

      case ForensicsStatus.loading:
        return _buildLoadingView(controller, isDark);

      case ForensicsStatus.error:
        return _buildErrorView(controller, isDark);

      case ForensicsStatus.success:
        return _buildSuccessDashboard(controller, isDark);
    }
  }

  Widget _buildErrorView(ForensicsController controller, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1516) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: BrandColors.danger.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 32,
                color: BrandColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Forensics Analysis Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? BrandColors.white : BrandColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ??
                  'An unexpected error occurred while parsing the file.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? const Color(0xFFD4B8B9)
                    : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                foregroundColor: BrandColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.arrowRotateLeft, size: 14),
              label: const Text('Try Another Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(ForensicsController controller, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16191D) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? const Color(0xFF262C32) : const Color(0xFFE2E6EA),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.shieldHalved,
                size: 32,
                color: BrandColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              backgroundColor: Color(0xFF2B313A),
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'Scanning & Analyzing Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? BrandColors.white : BrandColors.darkGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.loadingStage,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? BrandColors.neutral : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDashboard(ForensicsController controller, bool isDark) {
    final report = controller.report!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 960;

        if (isWideScreen) {
          // 2-Column Split Desktop Layout
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Image Preview + AI Status Card
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ImagePreviewCard(
                          imageBytes: controller.imageBytes,
                          file: report.file,
                          resolution: report.photography.resolutionString,
                        ),
                        const SizedBox(height: 16),
                        AiStatusCard(aiDetection: report.aiDetection),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Categorized Details with Navigation Tabs
                Expanded(
                  child: Column(
                    children: [
                      // Tab Bar Header
                      _buildTabBar(controller, isDark),
                      const SizedBox(height: 16),

                      // Tab Content Body
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildActiveTabContent(controller, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Single-Column Mobile/Narrow Layout
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ImagePreviewCard(
                  imageBytes: controller.imageBytes,
                  file: report.file,
                  resolution: report.photography.resolutionString,
                ),
                const SizedBox(height: 16),
                AiStatusCard(aiDetection: report.aiDetection),
                const SizedBox(height: 16),
                _buildTabBar(controller, isDark),
                const SizedBox(height: 16),
                _buildActiveTabContent(controller, isDark),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildTabBar(ForensicsController controller, bool isDark) {
    final report = controller.report!;
    final tabs = [
      _TabItem(title: 'Overview', icon: FontAwesomeIcons.tableCellsLarge),
      _TabItem(title: 'Device & Lens', icon: FontAwesomeIcons.cameraRetro),
      _TabItem(title: 'Photography', icon: FontAwesomeIcons.sliders),
      _TabItem(
        title: 'Location',
        icon: FontAwesomeIcons.locationDot,
        badge: report.hasLocation ? 'GPS' : null,
      ),
      _TabItem(
        title: 'Raw Tags',
        icon: FontAwesomeIcons.tags,
        badge: '${report.rawTags.length}',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16191D) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? const Color(0xFF262C32) : const Color(0xFFE2E6EA),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isSelected = controller.activeTabIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => controller.setActiveTab(idx),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BrandColors.primary
                        : (isDark
                              ? Colors.transparent
                              : const Color(0xFFF3F5F7)),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        item.icon,
                        size: 13,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? BrandColors.neutral
                                  : const Color(0xFF555E68)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? BrandColors.white
                                    : BrandColors.darkGrey),
                        ),
                      ),
                      if (item.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isDark
                                      ? const Color(0xFF262C32)
                                      : const Color(0xFFE0E5EA)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(0xFF9AA4B2)
                                        : const Color(0xFF47525E)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }
}

class _TabItem {
  final String title;
  final FaIconData icon;
  final String? badge;

  const _TabItem({required this.title, required this.icon, this.badge});
}
