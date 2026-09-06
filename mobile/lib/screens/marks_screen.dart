import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
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
        glows: const [
          GlassGlow(
            top: -100,
            right: -50,
            size: 300,
            color: Color(0x33FF9500),
          ),
          GlassGlow(
            bottom: 0,
            left: -100,
            size: 250,
            color: Color(0x338B0000),
          ),
        ],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: GlassAppBar(
                title: 'CIA Marks',
                showBackButton: true,
                bottomPadding: true,
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: LoadingView())
            else if (_error != null)
              SliverFillRemaining(
                child: ErrorView(
                  message: _error!,
                  onRetry: _refreshData,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList.separated(
                  itemCount: _marks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildCourseCard(_marks[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COURSE CARD
  // ---------------------------------------------------------------------------
  Widget _buildCourseCard(CourseMarks course) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.courseCode} - ${course.courseName}',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 18),

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
                  SizedBox(width: 8),
                  Text(
                    'Marks not available yet',
                    style: TextStyle(color: AppColors.white54),
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
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildComponentBox(c),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white24, height: 1),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${course.totals?.outOf100.toStringAsFixed(1) ?? '--'} / 100',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            component.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMark ? '${component.mark}' : '--',
            style: TextStyle(
              color: hasMark ? AppColors.white : AppColors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/${component.maxMark.toInt()}',
            style: const TextStyle(color: AppColors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}