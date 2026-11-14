import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
import '../models/college_announcement.dart';
import '../services/college_updates_service.dart';
import '../utils/announcement_links.dart';
import '../widgets/announcement_card.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_kit.dart';

class CampusHubScreen extends StatefulWidget {
  const CampusHubScreen({super.key, required this.service});
  final CollegeUpdatesService service;

  @override
  State<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends State<CampusHubScreen> {
  Map<String, dynamic>? _updates;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.service.fetchUpdates(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _updates = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) {
      context.push(AppRoutes.updates);
      return;
    }
    final opened = await openAnnouncementLink(url);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final announcements = _items(_updates?['announcements']);
    final events = _items(_updates?['events']);
    final preview = announcements
        .take(3)
        .map(CollegeAnnouncement.fromJson)
        .toList();
    final firstLoad = _loading && _updates == null;
    final side = Responsive.dp(context, 20);

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _load(refresh: true),
            color: AppColors.crimson,
            backgroundColor: AppColors.glass,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                side,
                Responsive.dp(context, 18),
                side,
                Responsive.dp(context, 130),
              ),
              children: [
                FadeSlideIn(child: _header()),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _calendarHero(),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Notices',
                          firstLoad ? '—' : '${announcements.length}',
                          Icons.campaign_rounded,
                          AppColors.crimson,
                          () => context.push(AppRoutes.updates),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Events',
                          firstLoad ? '—' : '${events.length}',
                          Icons.event_available_rounded,
                          AppColors.blue,
                          () => context.push(AppRoutes.updates),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _eventsSection(events, firstLoad),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: _noticesSection(preview, firstLoad),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: _toolkit(),
                ),
                const SizedBox(height: 22),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CAMPUS',
                style: TextStyle(
                  color: AppColors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stay in the loop',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: Responsive.sp(context, 30),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Notices, events and academic dates in one place.',
                style: TextStyle(
                  color: AppColors.white54,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _RefreshButton(loading: _loading, onTap: () => _load(refresh: true)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CALENDAR HERO
  // ---------------------------------------------------------------------------
  Widget _calendarHero() {
    final now = DateTime.now();
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return PressableScale(
      scale: 0.985,
      onTap: () => context.push(AppRoutes.calendar),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.crimson.withValues(alpha: 0.18),
              AppColors.glass,
              AppColors.backgroundSoft,
            ],
            stops: const [0, 0.55, 1],
          ),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            // mini "calendar leaf" showing today
            Container(
              width: 62,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.crimson,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(17),
                      ),
                    ),
                    child: Text(
                      months[now.month - 1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${now.day}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic calendar',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Plan around official college dates, month by month.',
                    style: TextStyle(
                      color: AppColors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.background,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EVENTS
  // ---------------------------------------------------------------------------
  Widget _eventsSection(List<Map<String, dynamic>> events, bool firstLoad) {
    final shown = events.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Upcoming events',
          'Happening around campus',
          () => context.push(AppRoutes.updates),
        ),
        const SizedBox(height: 14),
        if (firstLoad) ...const [
          SkeletonBox(height: 96, radius: 20),
        ] else if (_error != null && _updates == null)
          _message('Events could not be loaded.', Icons.cloud_off_rounded)
        else if (shown.isEmpty)
          _message('No upcoming events were found.', Icons.event_busy_rounded)
        else
          for (final e in shown) _eventCard(e),
      ],
    );
  }

  Widget _eventCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'College event';
    final date = item['dateLabel']?.toString().trim() ?? '';
    final location = item['location']?.toString().trim() ?? '';
    final department = item['department']?.toString().trim() ?? '';
    final url = item['url']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        onTap: () => _open(url),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.event_rounded,
                color: AppColors.blue,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    _meta(Icons.schedule_rounded, date),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _meta(Icons.location_on_outlined, location),
                  ] else if (department.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _meta(Icons.account_balance_outlined, department),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.white38),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.white54, fontSize: 11.5),
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // NOTICES
  // ---------------------------------------------------------------------------
  Widget _noticesSection(List<CollegeAnnouncement> preview, bool firstLoad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Latest notices',
          'Published by Loyola College',
          () => context.push(AppRoutes.updates),
        ),
        const SizedBox(height: 14),
        if (firstLoad) ...const [
          SkeletonBox(height: 74, radius: 20),
          SizedBox(height: 10),
          SkeletonBox(height: 74, radius: 20),
        ] else if (_error != null && _updates == null)
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'College updates could not be loaded.',
                    style: TextStyle(color: AppColors.white54, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => _load(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (preview.isEmpty)
          _message('No notices are available right now.', Icons.inbox_rounded)
        else
          for (final item in preview)
            AnnouncementCard(announcement: item, onTap: () => _open(item.url)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOOLKIT
  // ---------------------------------------------------------------------------
  Widget _toolkit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Campus toolkit'),
        const SizedBox(height: 14),
        _toolTile(
          icon: Icons.calendar_month_rounded,
          color: AppColors.orange,
          title: 'Academic calendar',
          subtitle: 'Official dates, month by month',
          onTap: () => context.push(AppRoutes.calendar),
        ),
        _toolTile(
          icon: Icons.notifications_active_rounded,
          color: AppColors.purple,
          title: 'All announcements',
          subtitle: 'Notices, circulars and documents',
          onTap: () => context.push(AppRoutes.updates),
        ),
      ],
    );
  }

  Widget _toolTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        scale: 0.985,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SMALL PIECES
  // ---------------------------------------------------------------------------
  Widget _sectionHeader(String title, String subtitle, VoidCallback onAll) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      trailing: TextButton(
        onPressed: onAll,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.crimson,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('See all'),
            SizedBox(width: 3),
            Icon(Icons.arrow_forward_rounded, size: 15),
          ],
        ),
      ),
    );
  }

  Widget _message(String message, IconData icon) => GlassContainer(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(icon, color: AppColors.white54, size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.white54, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );

  Widget _footer() {
    final fetchedAt = _updates?['fetchedAt'];
    return Column(
      children: [
        const Text(
          'A verified weekly class timetable is not connected yet, so no sample classes are shown.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white38,
            fontSize: 11,
            height: 1.45,
          ),
        ),
        if (fetchedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last synced: $fetchedAt',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white30, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

/// Circular glass refresh button that spins while loading.
class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(covariant _RefreshButton old) {
    super.didUpdateWidget(old);
    if (widget.loading && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.loading) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.loading) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.loading ? null : widget.onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundSoft,
          border: Border.all(color: AppColors.outline),
        ),
        child: RotationTransition(
          turns: _c,
          child: const Icon(
            Icons.refresh_rounded,
            color: AppColors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }
}
