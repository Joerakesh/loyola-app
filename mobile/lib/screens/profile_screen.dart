import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
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
          GlassGlow(top: -80, right: -40, size: 280, color: Color(0x3366D397)),
          GlassGlow(
            bottom: -60,
            left: -40,
            size: 300,
            color: Color(0x338B0000),
          ),
        ],
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.white,
          backgroundColor: Colors.black45,
          // AnimatedSwitcher moved to the root to fix scrolling
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

    if (_error != null || _profile == null) {
      return _buildStateLayout(
        key: const ValueKey('error'),
        child: ErrorView(
          message: _error ?? 'Unable to load profile',
          onRetry: _refreshData,
        ),
      );
    }

    // Scrollable List State
    return CustomScrollView(
      key: const ValueKey('content'),
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
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            Responsive.dp(context, 16),
            4,
            Responsive.dp(context, 16),
            Responsive.dp(context, 110),
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(_profile!),
              const SizedBox(height: 16), // Tighter spacing
              _buildDetailsCard(_profile!),
              const SizedBox(height: 16), // Tighter spacing
              _buildLogoutButton(),
            ]),
          ),
        ),
      ],
    );
  }

  // Helper method to keep AppBar visible during loading/error states
  Widget _buildStateLayout({required Key key, required Widget child}) {
    return CustomScrollView(
      key: key,
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
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(StudentProfile profile) {
    return GlassContainer(
      // Reduced padding
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 64, // Smaller avatar
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF9D84FF),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9D84FF).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24, // Smaller font
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18, // Smaller font
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.registerNumber,
            style: const TextStyle(
              color: AppColors.white54,
              fontSize: 12, // Smaller font
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
    final chips = [if (profile.program.isNotEmpty) profile.program];

    return Wrap(
      spacing: 6, // Tighter wrap spacing
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: chips
          .map(
            (chip) => Container(
              // Tighter chip padding
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                chip.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white70,
                  fontSize: 10, // Smaller font
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // DETAILS CARD
  // ---------------------------------------------------------------------------
  Widget _buildDetailsCard(StudentProfile profile) {
    final details = [
      ('Register Number', profile.registerNumber, Icons.badge_rounded),
      ('Program', profile.program, Icons.school_rounded),
      ('Course', profile.course, Icons.menu_book_rounded),
      ('Section', profile.section, Icons.grid_view_rounded),
      ('Academic Year', profile.academicYear, Icons.calendar_month_rounded),
      ('Mobile', profile.mobile, Icons.phone_rounded),
      ('Student ID', profile.studentId, Icons.tag_rounded),
    ];

    final validDetails = details.where((d) => d.$2.isNotEmpty).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(16), // Reduced outer padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14, // Smaller font
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16), // Tighter spacing
          for (var i = 0; i < validDetails.length; i++)
            Column(
              children: [
                _buildDetailRow(
                  title: validDetails[i].$1,
                  value: validDetails[i].$2,
                  icon: validDetails[i].$3,
                ),
                if (i < validDetails.length - 1)
                  Padding(
                    // Tighter divider padding
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: AppColors.white.withValues(alpha: 0.05),
                      height: 1,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          // Tighter icon container
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white54, size: 16), // Smaller icon
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white54,
                  fontSize: 11, // Smaller title
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14, // Smaller value
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return SizedBox(
      height: 44, // Shorter button
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 18), // Smaller icon
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 14, // Smaller label
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF7A7A),
          side: const BorderSide(
            color: Color(0xFFFF7A7A),
            width: 1.2,
          ), // Thinner border
          backgroundColor: const Color(0xFFFF7A7A).withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Tighter radius
          ),
        ),
      ),
    );
  }
}
