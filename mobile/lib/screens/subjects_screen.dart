import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/section_header.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key, required this.subjectService});

  final SubjectService subjectService;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> _subjects = [];
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
      final cached = await widget.subjectService.getCachedSubjects();
      if (!mounted || cached == null) return;
      setState(() {
        _subjects = cached;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    try {
      final result = await widget.subjectService.fetchSubjects();
      if (!mounted) return;
      setState(() {
        if (result.changed) _subjects = result.data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_subjects.isEmpty) {
          _error = e.toString();
          _isLoading = false;
        }
      });
    }
  }

  int get _totalCredits =>
      _subjects.fold(0, (sum, subject) => sum + subject.credits);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        glows: const [
          GlassGlow(top: -100, right: -50, size: 300, color: Color(0x33AF52DE)),
          GlassGlow(bottom: 0, left: -100, size: 250, color: Color(0x338B0000)),
        ],
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.white,
          backgroundColor: Colors.black45,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(
                child: GlassAppBar(
                  title: 'Subjects',
                  showBackButton: false, // Handled by AppShell
                  bottomPadding: true,
                ),
              ),

              // Animated Content Transition
              SliverFillRemaining(
                hasScrollBody: true,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const LoadingView(key: ValueKey('loading'));
    }

    if (_error != null) {
      return ErrorView(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: _refreshData,
      );
    }

    if (_subjects.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      key: const ValueKey('content'),
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSummaryCard(),
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Curriculum',
                subtitle: '${_subjects.length} subjects this semester',
              ),
              const SizedBox(height: 16),
              ..._subjects.map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildSubjectCard(subject),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects found',
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
  // SUMMARY CARDS
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Courses',
            value: '${_subjects.length}',
            icon: Icons.library_books_rounded,
            accentColor: const Color(0xFF9D84FF), // Theme Purple
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            title: 'Total Credits',
            value: '$_totalCredits',
            icon: Icons.stars_rounded,
            accentColor: const Color(0xFFFFCA7A), // Theme Gold
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBJECT LIST CARD
  // ---------------------------------------------------------------------------
  Widget _buildSubjectCard(Subject subject) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Sleek, monochromatic icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.import_contacts_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),

          // Course Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.title.isEmpty ? 'Untitled Course' : subject.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Frosted Code Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subject.courseCode,
                        style: const TextStyle(
                          color: AppColors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (subject.faculty.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '•  ${subject.faculty}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Credits
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${subject.credits}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'CR',
                style: TextStyle(
                  color: AppColors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
