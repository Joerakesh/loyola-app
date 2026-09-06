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
          GlassGlow(
            top: -100,
            right: -50,
            size: 300,
            color: Color(0x33AF52DE),
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
            const SliverToBoxAdapter(
              child: GlassAppBar(
                title: 'Subjects',
                showBackButton: false,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Courses',
                      subtitle: '${_subjects.length} subjects this semester',
                    ),
                    const SizedBox(height: 14),
                    ..._subjects.map(
                      (subject) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSubjectCard(subject),
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.white70,
                  size: 20,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Courses',
                  style: TextStyle(color: AppColors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_subjects.length}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Credits',
                  style: TextStyle(color: AppColors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalCredits',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.title.isEmpty ? 'Untitled Course' : subject.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.courseCode,
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subject.faculty.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.white38,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subject.faculty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              '${subject.credits} CR',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}