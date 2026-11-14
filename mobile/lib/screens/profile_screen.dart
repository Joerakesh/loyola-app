import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// College static info (printed on the back of the physical card).
const _collegeName = 'LOYOLA COLLEGE';
const _collegeCity = 'CHENNAI 600 034 · TN · INDIA';
const _collegeTel = '28178200 / 28178300';
const _collegeWeb = 'www.loyolacollege.edu';
const _collegeMail = 'helpdesk@loyolacollege.edu';

const _cardMaroon = Color(0xFF5A1A22);
const _cardPaper = Color(0xFFF3F5F5);
const _cardInk = Color(0xFF1B1B1B);

/// One row in the details list.
class _Field {
  const _Field(this.label, this.value, this.icon, {this.sensitive = false});
  final String label;
  final String value;
  final IconData icon;
  final bool sensitive;
  String get key => label;
}

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

  /// Labels of sensitive fields that are currently revealed.
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _loadCached();
    _refreshData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<AuthProvider>().refreshStudentPhoto());
      }
    });
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

  // ---------------------------------------------------------------------------
  // MASKING HELPERS
  // ---------------------------------------------------------------------------
  String _mask(String v) {
    final t = v.trim();
    if (t.length <= 4) return '•' * t.length;
    final keep = t.length > 8 ? 3 : 2;
    return '•' * (t.length - keep) + t.substring(t.length - keep);
  }

  bool _isShown(_Field f) => !f.sensitive || _revealed.contains(f.key);

  void _toggle(String key) {
    setState(() {
      if (!_revealed.add(key)) _revealed.remove(key);
    });
  }

  void _toggleAll(List<_Field> fields) {
    final sensitive = fields.where((f) => f.sensitive).map((f) => f.key);
    setState(() {
      if (sensitive.every(_revealed.contains)) {
        _revealed.removeAll(sensitive);
      } else {
        _revealed.addAll(sensitive);
      }
    });
  }

  void _copy(_Field f) {
    if (!_isShown(f)) return;
    Clipboard.setData(ClipboardData(text: f.value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${f.label} copied'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // FIELD GROUPS
  //
  // To show more backend data: add the field to StudentProfile, then add a
  // line below, e.g.
  //   _Field('Email', p.email, Icons.mail_rounded, sensitive: true),
  //   _Field('Date of Birth', p.dob, Icons.cake_rounded, sensitive: true),
  //   _Field('Blood Group', p.bloodGroup, Icons.bloodtype_rounded),
  //   _Field('Parent Mobile', p.parentMobile, Icons.family_restroom_rounded,
  //       sensitive: true),
  //   _Field('Address', p.address, Icons.home_rounded, sensitive: true),
  // Empty values are skipped automatically.
  // ---------------------------------------------------------------------------
  List<_Field> _academic(StudentProfile p) => [
    // _Field('Program', p.program, Icons.school_rounded),
    _Field('Course', p.course, Icons.menu_book_rounded),
    _Field('Section', p.section, Icons.grid_view_rounded),
    _Field('Academic Year', p.academicYear, Icons.calendar_month_rounded),
  ].where((f) => f.value.isNotEmpty).toList();

  List<_Field> _identity(StudentProfile p) => [
    _Field('Register Number', p.registerNumber, Icons.badge_rounded),
    _Field('Student ID', p.studentId, Icons.tag_rounded, sensitive: true),
  ].where((f) => f.value.isNotEmpty).toList();

  List<_Field> _contact(StudentProfile p) => [
    _Field('Mobile', p.mobile, Icons.phone_rounded, sensitive: true),
  ].where((f) => f.value.isNotEmpty).toList();

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        glows: const [
          GlassGlow(top: -80, right: -40, size: 280, color: Color(0x1972E4D2)),
          GlassGlow(
            bottom: -60,
            left: -40,
            size: 300,
            color: Color(0x18B9F36B),
          ),
        ],
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.white,
          backgroundColor: AppColors.glass,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
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

    final profile = _profile!;
    final avatarUrl = context.watch<AuthProvider>().profileAvatarUrl;
    final contact = _contact(profile);
    final mobileField = contact.isEmpty ? null : contact.first;

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
              _FlipIdCard(
                profile: profile,
                avatar: _buildAvatar(profile, avatarUrl),
                mobileText: mobileField == null
                    ? null
                    : (_isShown(mobileField)
                          ? mobileField.value
                          : _mask(mobileField.value)),
                mobileRevealed: mobileField != null && _isShown(mobileField),
                onToggleMobile: mobileField == null
                    ? null
                    : () => _toggle(mobileField.key),
                academic: _academic(profile),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap or swipe the card to flip',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Academic',
                icon: Icons.school_rounded,
                fields: _academic(profile),
              ),
              _buildSection(
                title: 'Identity',
                icon: Icons.fingerprint_rounded,
                fields: _identity(profile),
              ),
              _buildSection(
                title: 'Contact',
                icon: Icons.contacts_rounded,
                fields: contact,
              ),
              _buildLogoutButton(),
            ]),
          ),
        ),
      ],
    );
  }

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
  // AVATAR
  // ---------------------------------------------------------------------------
  Widget _buildAvatar(StudentProfile profile, String? avatarUrl) {
    final url = avatarUrl?.trim();
    final fallback = Container(
      color: AppColors.crimson,
      alignment: Alignment.center,
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (url == null || url.isEmpty) return fallback;

    try {
      return url.startsWith('data:image/')
          ? Image.memory(
              base64Decode(url.substring(url.indexOf(',') + 1)),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            );
    } on FormatException {
      return fallback;
    }
  }

  // ---------------------------------------------------------------------------
  // DETAIL SECTIONS
  // ---------------------------------------------------------------------------
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_Field> fields,
  }) {
    if (fields.isEmpty) return const SizedBox.shrink();
    final hasSensitive = fields.any((f) => f.sensitive);
    final allShown =
        hasSensitive &&
        fields
            .where((f) => f.sensitive)
            .every((f) => _revealed.contains(f.key));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (hasSensitive)
                  TextButton.icon(
                    onPressed: () => _toggleAll(fields),
                    icon: Icon(
                      allShown
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                    ),
                    label: Text(allShown ? 'Hide' : 'Reveal'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white70,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < fields.length; i++) ...[
              _buildDetailRow(fields[i]),
              if (i < fields.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    color: AppColors.white.withValues(alpha: 0.05),
                    height: 1,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(_Field f) {
    final shown = _isShown(f);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onLongPress: () => _copy(f),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(f.icon, color: AppColors.white54, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.label,
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    shown ? f.value : _mask(f.value),
                    key: ValueKey(shown),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: shown ? 0 : 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (f.sensitive)
            IconButton(
              onPressed: () => _toggle(f.key),
              tooltip: shown ? 'Hide' : 'Reveal',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                shown ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: AppColors.white54,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red, width: 1.2),
          backgroundColor: AppColors.red.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FLIP ID CARD
// =============================================================================
class _FlipIdCard extends StatefulWidget {
  const _FlipIdCard({
    required this.profile,
    required this.avatar,
    required this.mobileText,
    required this.mobileRevealed,
    required this.onToggleMobile,
    required this.academic,
  });

  final StudentProfile profile;
  final Widget avatar;
  final String? mobileText;
  final bool mobileRevealed;
  final VoidCallback? onToggleMobile;
  final List<_Field> academic;

  @override
  State<_FlipIdCard> createState() => _FlipIdCardState();
}

class _FlipIdCardState extends State<_FlipIdCard>
    with SingleTickerProviderStateMixin {
  // Card is designed at a fixed logical size and scaled to fit the screen.
  static const double _w = 340;
  static const double _h = 214;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  bool get _showingBack =>
      _controller.value >= 0.5 || _controller.status == AnimationStatus.forward;

  void _flip() {
    HapticFeedback.selectionClick();
    if (_controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0).abs() > 150) _flip();
      },
      child: AspectRatio(
        aspectRatio: _w / _h,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final angle = _curve.value * math.pi;
            final isFront = angle <= math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: _w,
                      height: _h,
                      child: isFront
                          ? _front()
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: _back(),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FRONT
  // ---------------------------------------------------------------------------
  Widget _front() {
    final p = widget.profile;
    return Container(
      color: _cardPaper,
      child: Stack(
        children: [
          // soft sheen
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          // crest (replace with Image.asset of the college crest if you have it)
          const Positioned(left: 40, top: 16, child: _Crest()),
          // photo
          Positioned(
            right: 18,
            top: 16,
            child: Container(
              width: 82,
              height: 102,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: widget.avatar,
              ),
            ),
          ),
          // text block
          Positioned(
            left: 20,
            right: 120,
            top: 98,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cardInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                if (p.program.isNotEmpty)
                  Text(
                    p.program,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  p.registerNumber,
                  style: const TextStyle(
                    color: _cardInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          // flip hint icon
          Positioned(
            right: 16,
            top: 126,
            child: Icon(
              Icons.flip_rounded,
              size: 14,
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          // bottom bar
          const Positioned(left: 0, right: 0, bottom: 0, child: _MaroonBar()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BACK  (only fields that exist; no signature)
  // ---------------------------------------------------------------------------
  Widget _back() {
    final rows = <Widget>[];

    if (widget.mobileText != null) {
      rows.add(
        _backRow(
          'Mobile',
          widget.mobileText!,
          trailing: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggleMobile,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                widget.mobileRevealed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      );
    }
    for (final f in widget.academic) {
      rows.add(_backRow(f.label, f.value));
    }

    return Container(
      color: _cardPaper,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...rows,
                  const Spacer(),
                  const Text(
                    'If found please return to:',
                    style: TextStyle(
                      color: _cardInk,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'LOYOLA COLLEGE, CHENNAI - 600 034.',
                    style: TextStyle(
                      color: _cardInk,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'TEL : $_collegeTel',
                    style: TextStyle(color: _cardInk, fontSize: 9.5),
                  ),
                  const Text(
                    'Website : $_collegeWeb',
                    style: TextStyle(color: _cardInk, fontSize: 9.5),
                  ),
                  const Text(
                    'E-mail : $_collegeMail',
                    style: TextStyle(color: _cardInk, fontSize: 9.5),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Container(height: 6, color: _cardMaroon),
        ],
      ),
    );
  }

  Widget _backRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: _cardInk,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: _cardInk, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _cardInk,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class _MaroonBar extends StatelessWidget {
  const _MaroonBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: _cardMaroon,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  _collegeName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    height: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _collegeCity,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 7,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            _collegeWeb,
            style: TextStyle(color: Colors.white70, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}

/// Simple crest placeholder. Swap for `Image.asset('assets/loyola_crest.png')`.
class _Crest extends StatelessWidget {
  const _Crest();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 64,
      child: Image.asset(
        'assets/images/loyola_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.school_rounded, color: _cardMaroon, size: 40),
      ),
    );
  }
}
