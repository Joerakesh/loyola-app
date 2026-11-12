import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
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
  int? _selectedSemester;
  bool _semesterSelectionInitialized = false;

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
        if (!_semesterSelectionInitialized) {
          _selectedSemester = _highestSemester(cached);
          _semesterSelectionInitialized = true;
        }
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
        if (result.changed) {
          _subjects = result.data;
          if (_selectedSemester != null &&
              !_subjects.any(
                (subject) => subject.semester == _selectedSemester,
              )) {
            _selectedSemester = _highestSemester(_subjects);
          } else if (!_semesterSelectionInitialized) {
            _selectedSemester = _highestSemester(_subjects);
          }
          _semesterSelectionInitialized = true;
        }
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

  int? _highestSemester(List<Subject> subjects) {
    final semesters = subjects
        .map((subject) => subject.semester)
        .where((semester) => semester > 0);
    return semesters.isEmpty ? null : semesters.reduce((a, b) => a > b ? a : b);
  }

  List<int> get _semesters =>
      _subjects
          .map((subject) => subject.semester)
          .where((semester) => semester > 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  List<Subject> get _visibleSubjects => _selectedSemester == null
      ? _subjects
      : _subjects
            .where((subject) => subject.semester == _selectedSemester)
            .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        glows: const [
          GlassGlow(top: -100, right: -50, size: 300, color: Color(0x18B9F36B)),
          GlassGlow(bottom: 0, left: -100, size: 250, color: Color(0x1472E4D2)),
        ],
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.white,
          backgroundColor: AppColors.glass,
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

              ..._buildContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers() {
    if (_isLoading) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: LoadingView()),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(message: _error!, onRetry: _refreshData),
        ),
      ];
    }

    final visibleSubjects = _visibleSubjects;
    if (visibleSubjects.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            _selectedSemester == null
                ? 'No subjects found'
                : 'No subjects found for Semester $_selectedSemester',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          Responsive.dp(context, 20),
          8,
          Responsive.dp(context, 20),
          Responsive.dp(context, 130),
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == 0) return _buildSummaryCard(visibleSubjects);
            if (index == 1) return const SizedBox(height: 32);
            if (index == 2) {
              return SectionHeader(
                title: 'Curriculum',
                subtitle: _selectedSemester == null
                    ? '${visibleSubjects.length} subjects across semesters'
                    : '${visibleSubjects.length} subjects · Semester $_selectedSemester',
              );
            }
            if (index == 3) return _buildSemesterFilter();
            if (index == 4) return const SizedBox(height: 16);

            final subject = visibleSubjects[index - 5];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildSubjectCard(subject),
            );
          }, childCount: visibleSubjects.length + 5),
        ),
      ),
    ];
  }

  Widget _buildEmptyState(String message) {
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
            message,
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
  Widget _buildSummaryCard(List<Subject> subjects) {
    final totalCredits = subjects.fold<int>(
      0,
      (sum, subject) => sum + subject.credits,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Courses',
            value: '${subjects.length}',
            icon: Icons.library_books_rounded,
            accentColor: AppColors.crimson,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            title: 'Total Credits',
            value: '$totalCredits',
            icon: Icons.stars_rounded,
            accentColor: AppColors.gold,
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _semesterChip(label: 'All', semester: null),
            for (final semester in _semesters) ...[
              const SizedBox(width: 8),
              _semesterChip(label: 'Semester $semester', semester: semester),
            ],
          ],
        ),
      ),
    );
  }

  Widget _semesterChip({required String label, required int? semester}) {
    final selected = _selectedSemester == semester;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedSemester = semester;
          _semesterSelectionInitialized = true;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.crimson : AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.crimson : AppColors.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
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
    final compact = Responsive.isCompact(context);
    final iconBox = Responsive.dp(context, compact ? 46 : 52);

    return GlassContainer(
      padding: EdgeInsets.all(Responsive.dp(context, 16)),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.import_contacts_rounded,
              color: AppColors.white,
              size: Responsive.dp(context, 22),
            ),
          ),
          SizedBox(width: Responsive.dp(context, 16)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.title.isEmpty ? 'Untitled Course' : subject.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
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

          SizedBox(width: Responsive.dp(context, 12)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${subject.credits}',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: Responsive.sp(context, 22),
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
