import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
import '../models/marks_model.dart';
import '../services/marks_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key, required this.marksService});
  final MarksService marksService;

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  List<CourseMarks> _marks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _refreshData();
  }

  Future<void> _loadCached() async {
    try {
      final cached = await widget.marksService.getCachedMarks();
      if (!mounted || cached == null) return;
      setState(() {
        _marks = cached;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    try {
      final result = await widget.marksService.fetchMarks();
      if (!mounted) return;
      setState(() {
        if (result.changed) _marks = result.data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_marks.isEmpty) {
          _error = e.toString();
          _isLoading = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.white,
          backgroundColor: Colors.black45,
          // We move the AnimatedSwitcher to the root of the scroll view
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildStateLayout(
        key: const ValueKey('loading'),
        child: const LoadingView(),
      );
    }

    if (_error != null) {
      return _buildStateLayout(
        key: const ValueKey('error'),
        child: ErrorView(message: _error!, onRetry: _refreshData),
      );
    }

    if (_marks.isEmpty) {
      return _buildStateLayout(
        key: const ValueKey('empty'),
        child: _buildEmptyState(),
      );
    }

    // This is the populated, fully scrollable list state
    return CustomScrollView(
      key: const ValueKey('list'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(
          child: GlassAppBar(
            title: 'CIA Marks',
            showBackButton: false,
            bottomPadding: true,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            Responsive.dp(context, 20),
            8,
            Responsive.dp(context, 20),
            Responsive.dp(context, 130),
          ),
          sliver: SliverList.separated(
            itemCount: _marks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildCourseCard(_marks[index]),
          ),
        ),
      ],
    );
  }

  // Helper method for Loading, Error, and Empty states to keep the AppBar
  // at the top and allow pull-to-refresh even when there's no data.
  Widget _buildStateLayout({required Key key, required Widget child}) {
    return CustomScrollView(
      key: key,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(
          child: GlassAppBar(
            title: 'CIA Marks',
            showBackButton: false,
            bottomPadding: true,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody:
              false, // False allows the content to center itself properly
          child: child,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.leaderboard_rounded,
            size: 48,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No marks available yet',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COURSE CARD
  // ---------------------------------------------------------------------------
  Widget _buildCourseCard(CourseMarks course) {
    return GlassContainer(
      padding: EdgeInsets.all(Responsive.dp(context, 18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.courseCode} - ${course.courseName}',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(context, 15),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),

          if (!course.marksAvailable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.white54,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Marks pending',
                    style: TextStyle(
                      color: AppColors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: course.components
                  .map(
                    (c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildComponentBox(c),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white12, height: 1),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Score',
                  style: TextStyle(
                    color: AppColors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D84FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9D84FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${course.totals?.outOf100.toStringAsFixed(1) ?? '--'} / 100',
                    style: const TextStyle(
                      color: Color(0xFF9D84FF),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INDIVIDUAL COMPONENT BOX
  // ---------------------------------------------------------------------------
  Widget _buildComponentBox(MarkComponent component) {
    final hasMark = component.mark != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            component.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasMark ? '${component.mark}' : '--',
            style: TextStyle(
              color: hasMark ? AppColors.white : AppColors.white38,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/ ${component.maxMark.toInt()}',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
