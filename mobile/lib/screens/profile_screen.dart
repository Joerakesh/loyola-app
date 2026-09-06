import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/profile_model.dart';
import '../services/auth_provider.dart';
import '../services/profile_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profileService});

  final ProfileService profileService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StudentProfile? _profile;
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
      final cached = await widget.profileService.getCachedProfile();
      if (!mounted || cached == null) return;
      setState(() {
        _profile = cached;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    try {
      final result = await widget.profileService.fetchProfile();
      if (!mounted) return;
      setState(() {
        if (result.changed) _profile = result.data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_profile == null) {
          _error = e.toString();
          _isLoading = false;
        }
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        glows: const [
          GlassGlow(
            top: -80,
            right: -40,
            size: 280,
            color: Color(0x3366D397),
          ),
          GlassGlow(
            bottom: -60,
            left: -40,
            size: 300,
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
                title: 'Profile',
                showBackButton: false,
                bottomPadding: true,
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: LoadingView())
            else if (_error != null || _profile == null)
              SliverFillRemaining(
                child: ErrorView(
                  message: _error ?? 'Unable to load profile',
                  onRetry: _refreshData,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(_profile!),
                    const SizedBox(height: 24),
                    _buildDetailsCard(_profile!),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StudentProfile profile) {
    return GlassContainer(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.crimson.withValues(alpha: 0.3),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty
                    ? profile.name[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.registerNumber,
            style: const TextStyle(
              color: AppColors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (profile.program.isNotEmpty || profile.course.isNotEmpty)
            _buildInfoChipRow(profile),
        ],
      ),
    );
  }

  Widget _buildInfoChipRow(StudentProfile profile) {
    final chips = [
      if (profile.program.isNotEmpty) profile.program,
      if (profile.course.isNotEmpty) profile.course,
      if (profile.section.isNotEmpty) 'Sec ${profile.section}',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: chips
          .map(
            (chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                chip.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDetailsCard(StudentProfile profile) {
    final details = [
      ('Register Number', profile.registerNumber, Icons.badge_outlined),
      ('Program', profile.program, Icons.school_outlined),
      ('Course', profile.course, Icons.menu_book_outlined),
      ('Section', profile.section, Icons.grid_view_rounded),
      ('Academic Year', profile.academicYear, Icons.calendar_month_outlined),
      ('Mobile', profile.mobile, Icons.phone_outlined),
      ('Student ID', profile.studentId, Icons.tag_rounded),
    ];

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (final (title, value, icon) in details)
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.white54, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Logout',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
          backgroundColor: AppColors.red.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}