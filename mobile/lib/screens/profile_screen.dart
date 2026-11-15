import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/responsive.dart';
import '../models/profile_model.dart';
import '../services/auth_provider.dart';
import '../services/profile_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

// Static college info (printed on the back of the physical card).
const _collegeName = 'LOYOLA COLLEGE';
const _collegeCity = 'CHENNAI 600 034 · INDIA';
const _collegeTel = '28178200 / 28178300';
const _collegeWeb = 'www.loyolacollege.edu';
const _collegeMail = 'helpdesk@loyolacollege.edu';
const _logoAsset = 'assets/images/loyola_logo.png';

const _cardMaroon = Color(0xFF5A1A22);
const _cardPaper = Color(0xFFF3F5F5);
const _cardInk = Color(0xFF1B1B1B);

/// Values up to this length are shown two-per-row.
const _shortLimit = 13;

// -----------------------------------------------------------------------------
// CATEGORISATION (exact backend keys first, keyword fallback after)
// -----------------------------------------------------------------------------
enum _Group { personal, academic, contact, family, record }

extension on _Group {
  String get title => switch (this) {
    _Group.personal => 'Personal',
    _Group.academic => 'Academic',
    _Group.contact => 'Contact & Address',
    _Group.family => 'Family & Guardian',
    _Group.record => 'Record',
  };

  IconData get icon => switch (this) {
    _Group.personal => Icons.person_rounded,
    _Group.academic => Icons.school_rounded,
    _Group.contact => Icons.contacts_rounded,
    _Group.family => Icons.family_restroom_rounded,
    _Group.record => Icons.folder_open_rounded,
  };
}

const _exactGroups = <String, _Group>{
  // personal
  'name': _Group.personal,
  'tamilName': _Group.personal,
  'nameInLocalLanguage': _Group.personal,
  'sex': _Group.personal,
  'dateOfBirth': _Group.personal,
  'nationality': _Group.personal,
  'religion': _Group.personal,
  'category': _Group.personal,
  'language': _Group.personal,
  // academic
  'registerNumber': _Group.academic,
  'universityRegisterNumber': _Group.academic,
  'studentId': _Group.academic,
  'program': _Group.academic,
  'course': _Group.academic,
  'section': _Group.academic,
  'academicYear': _Group.academic,
  'hostelDayScholar': _Group.academic,
  'isDetained': _Group.academic,
  'detainedDetails': _Group.academic,
  // contact
  'mobile': _Group.contact,
  'email': _Group.contact,
  'address': _Group.contact,
  'district': _Group.contact,
  'state': _Group.contact,
  // family
  'fatherName': _Group.family,
  'motherName': _Group.family,
  'parentMobile': _Group.family,
  'parentEmail': _Group.family,
  'occupation': _Group.family,
  'annualIncome': _Group.family,
  // record
  'officeId': _Group.record,
  'createdAt': _Group.record,
};

const _sensitiveKeys = <String>{
  'mobile',
  'email',
  'address',
  'dateOfBirth',
  'studentId',
  'religion',
  'category',
  'fatherName',
  'motherName',
  'parentMobile',
  'parentEmail',
  'occupation',
  'annualIncome',
};

bool _has(String k, List<String> parts) => parts.any(k.contains);

_Group _groupOf(String key) {
  final exact = _exactGroups[key];
  if (exact != null) return exact;
  final k = key.toLowerCase();
  if (_has(k, ['father', 'mother', 'parent', 'guardian', 'income'])) {
    return _Group.family;
  }
  if (_has(k, [
    'mobile',
    'phone',
    'email',
    'address',
    'district',
    'state',
    'city',
    'pin',
  ])) {
    return _Group.contact;
  }
  if (_has(k, [
    'program',
    'course',
    'section',
    'academic',
    'year',
    'batch',
    'department',
    'semester',
    'register',
    'student',
  ])) {
    return _Group.academic;
  }
  if (_has(k, [
    'name',
    'birth',
    'sex',
    'gender',
    'blood',
    'religion',
    'nationality',
    'language',
  ])) {
    return _Group.personal;
  }
  return _Group.record;
}

bool _isSensitive(String key) {
  if (_sensitiveKeys.contains(key)) return true;
  return _has(key.toLowerCase(), [
    'mobile',
    'phone',
    'email',
    'birth',
    'dob',
    'address',
    'aadhaar',
    'aadhar',
    'income',
  ]);
}

IconData _iconFor(String key) {
  final k = key.toLowerCase();
  if (k.contains('email')) return Icons.email_outlined;
  if (k.contains('mobile') || k.contains('phone')) return Icons.phone_rounded;
  if (k.contains('birth') || k.contains('dob')) return Icons.cake_rounded;
  if (k.contains('blood')) return Icons.bloodtype_rounded;
  if (k.contains('created') || k.contains('date')) {
    return Icons.event_rounded;
  }
  if (k.contains('university')) return Icons.confirmation_number_rounded;
  if (k.contains('register')) return Icons.badge_rounded;
  if (k.contains('studentid')) return Icons.tag_rounded;
  if (k.contains('father') || k.contains('mother')) {
    return Icons.person_pin_rounded;
  }
  if (k.contains('occupation')) return Icons.work_outline_rounded;
  if (k.contains('income')) return Icons.currency_rupee_rounded;
  if (k.contains('language')) return Icons.translate_rounded;
  if (k == 'sex' || k.contains('gender')) return Icons.wc_rounded;
  if (k.contains('religion')) return Icons.diversity_3_rounded;
  if (k.contains('category')) return Icons.category_rounded;
  if (k.contains('nationality')) return Icons.flag_rounded;
  if (k.contains('hostel')) return Icons.apartment_rounded;
  if (k.contains('detained')) return Icons.gpp_maybe_rounded;
  if (k.contains('office')) return Icons.business_rounded;
  if (k.contains('name')) return Icons.person_outline_rounded;
  if (k.contains('address') || k.contains('district') || k.contains('state')) {
    return Icons.location_on_outlined;
  }
  if (k.contains('section')) return Icons.grid_view_rounded;
  if (k.contains('course')) return Icons.menu_book_rounded;
  if (k.contains('program') || k.contains('year')) return Icons.school_rounded;
  return Icons.info_outline_rounded;
}

class _Field {
  const _Field({
    required this.key,
    required this.label,
    required this.value,
    required this.group,
    required this.sensitive,
    required this.icon,
  });

  final String key;
  final String label;
  final String value;
  final _Group group;
  final bool sensitive;
  final IconData icon;

  bool get isShort => value.length <= _shortLimit && !value.contains('\n');
}

String _pretty(String key, String raw) {
  final t = raw.trim().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final k = key.toLowerCase();
  if (k.contains('date') || k.contains('birth') || k.contains('created')) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (m != null) return '${m[3]}-${m[2]}-${m[1]}';
  }
  return t;
}

String _mask(String v) {
  final t = v.trim();
  final at = t.indexOf('@');
  if (at > 1) return '${t[0]}${'•' * 4}${t.substring(at)}';
  if (t.contains('\n') || t.length > 24) return '•' * 14;
  if (t.length <= 4) return '•' * t.length;
  final keep = t.length > 8 ? 3 : 2;
  return '•' * (t.length - keep) + t.substring(t.length - keep);
}

// -----------------------------------------------------------------------------
// SCREEN
// -----------------------------------------------------------------------------
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

  /// Keys of sensitive fields currently revealed.
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _loadCached();
    _refreshData();

    // Retry the ERP photo when Profile is opened. This also handles users who
    // linked their ERP account after the initial Google sign-in.
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
  // DATA
  // ---------------------------------------------------------------------------
  List<_Field> _fields(StudentProfile p) {
    final out = <_Field>[];
    for (final key in StudentProfile.displayOrder) {
      String value;
      try {
        value = _pretty(key, p.displayValue(key));
      } catch (_) {
        continue;
      }
      if (value.isEmpty) continue;
      out.add(
        _Field(
          key: key,
          label: StudentProfile.labels[key] ?? key,
          value: value,
          group: _groupOf(key),
          sensitive: _isSensitive(key),
          icon: _iconFor(key),
        ),
      );
    }
    return out;
  }

  bool _shown(_Field f) => !f.sensitive || _revealed.contains(f.key);
  String _text(_Field f) => _shown(f) ? f.value : _mask(f.value);

  void _toggle(String key) => setState(() {
    if (!_revealed.add(key)) _revealed.remove(key);
  });

  void _toggleAll(List<_Field> fields) {
    final keys = fields.where((f) => f.sensitive).map((f) => f.key).toList();
    setState(() {
      if (keys.every(_revealed.contains)) {
        _revealed.removeAll(keys);
      } else {
        _revealed.addAll(keys);
      }
    });
  }

  void _copy(_Field f) {
    if (!_shown(f)) return;
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

  _BackRow _toBackRow(_Field f) => _BackRow(
    key: f.key,
    label: f.label,
    text: f.value.replaceAll('\n', ', '),
    sensitive: f.sensitive,
  );

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
          color: AppTheme.white,
          backgroundColor: AppTheme.glass,
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
    final fields = _fields(profile);

    _Field? byKey(String k) {
      for (final f in fields) {
        if (f.key == k) return f;
      }
      return null;
    }

    // Back of the card: these keys, in this order, when present.
    const backKeys = [
      'dateOfBirth',
      'mobile',
      // 'parentMobile',
      'program',
      // 'academicYear',
      'address',
    ];
    final backRows = <_BackRow>[
      for (final k in backKeys)
        if (byKey(k) != null) _toBackRow(byKey(k)!),
    ];
    final emailField = byKey('email');

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
                email: emailField == null ? null : _toBackRow(emailField),
                backRows: backRows,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap or swipe the card to flip',
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final g in _Group.values)
                _buildSection(g, fields.where((f) => f.group == g).toList()),
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
      color: AppTheme.crimson,
      alignment: Alignment.center,
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
        style: const TextStyle(
          color: AppTheme.white,
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
  // SECTIONS (short values go two-per-row, long values full width)
  // ---------------------------------------------------------------------------
  Widget _buildSection(_Group group, List<_Field> fields) {
    if (fields.isEmpty) return const SizedBox.shrink();
    final sensitive = fields.where((f) => f.sensitive).toList();
    final allShown =
        sensitive.isNotEmpty &&
        sensitive.every((f) => _revealed.contains(f.key));

    final shorts = fields.where((f) => f.isShort).toList();
    final longs = fields.where((f) => !f.isShort).toList();

    final rows = <Widget>[
      for (var i = 0; i < shorts.length; i += 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCell(shorts[i], compact: true)),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < shorts.length
                  ? _buildCell(shorts[i + 1], compact: true)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      for (final f in longs) _buildCell(f),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(group.icon, size: 16, color: AppTheme.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (sensitive.isNotEmpty)
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
                      foregroundColor: AppTheme.white70,
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
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    color: AppTheme.white.withValues(alpha: 0.05),
                    height: 1,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCell(_Field f, {bool compact = false}) {
    final shown = _shown(f);
    final iconBox = compact ? 28.0 : 32.0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onLongPress: () => _copy(f),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              f.icon,
              color: AppTheme.white54,
              size: compact ? 14 : 16,
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    _text(f),
                    key: ValueKey(shown),
                    maxLines: compact ? 2 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: shown ? 0 : 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (f.sensitive)
            InkResponse(
              onTap: () => _toggle(f.key),
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  shown
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 16,
                  color: AppTheme.white54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
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
          foregroundColor: AppTheme.red,
          side: const BorderSide(color: AppTheme.red, width: 1.2),
          backgroundColor: AppTheme.red.withValues(alpha: 0.1),
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
class _BackRow {
  const _BackRow({
    required this.key,
    required this.label,
    required this.text,
    required this.sensitive,
  });

  final String key;
  final String label;
  final String text;
  final bool sensitive;
}

class _FlipIdCard extends StatefulWidget {
  const _FlipIdCard({
    required this.profile,
    required this.avatar,
    required this.email,
    required this.backRows,
  });

  final StudentProfile profile;
  final Widget avatar;
  final _BackRow? email;
  final List<_BackRow> backRows;

  @override
  State<_FlipIdCard> createState() => _FlipIdCardState();
}

class _FlipIdCardState extends State<_FlipIdCard>
    with SingleTickerProviderStateMixin {
  // Designed at a fixed logical size, scaled to fit the screen width.
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
  // FRONT: logo, photo, name, register number, email
  // ---------------------------------------------------------------------------
  Widget _front() {
    final p = widget.profile;
    final email = widget.email;
    return Container(
      color: _cardPaper,
      child: Stack(
        children: [
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
          Positioned(
            left: 20,
            top: 14,
            child: SizedBox(
              width: 60,
              height: 66,
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.school_rounded,
                  color: _cardMaroon,
                  size: 40,
                ),
              ),
            ),
          ),
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
          Positioned(
            left: 20,
            right: 118,
            top: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cardInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.registerNumber,
                  style: const TextStyle(
                    color: _cardInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          email.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 126,
            child: Icon(
              Icons.flip_rounded,
              size: 14,
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: _MaroonBar()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BACK (only existing fields, no signature)
  // ---------------------------------------------------------------------------
  Widget _back() {
    return Container(
      color: _cardPaper,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in widget.backRows) _backRow(r),
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

  Widget _backRow(_BackRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              r.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _cardInk,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: _cardInk, fontSize: 10.5)),
          Flexible(
            child: Text(
              r.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _cardInk,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
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
      child: const Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          Text(
            _collegeWeb,
            style: TextStyle(color: Colors.white70, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}
