import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/constants/app_colors.dart';
import '../models/college_announcement.dart';
import '../services/college_updates_service.dart';
import '../utils/announcement_links.dart';

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
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.service.fetchUpdates(refresh: refresh);
      if (!mounted) return;
      setState(() { _updates = result; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final announcements = _items(_updates?['announcements']);
    final events = _items(_updates?['events']);
    final preview = announcements.take(3).map(CollegeAnnouncement.fromJson).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          color: AppColors.crimson,
          backgroundColor: AppColors.glass,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.explore_rounded, color: AppColors.background)),
                const SizedBox(width: 11),
                const Expanded(child: Text('CAMPUS', style: TextStyle(color: AppColors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8))),
                IconButton(onPressed: _loading ? null : () => _load(refresh: true), tooltip: 'Refresh campus updates', icon: const Icon(Icons.refresh_rounded, color: AppColors.white70)),
              ]),
              const SizedBox(height: 24),
              const Text('Stay in the loop.', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
              const SizedBox(height: 7),
              const Text('College notices, events and important academic dates — together.', style: TextStyle(color: AppColors.white54, fontSize: 13, height: 1.45)),
              const SizedBox(height: 22),
              _calendarFeature(context),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _countCard('Notices', _loading && _updates == null ? '—' : '${announcements.length}', Icons.campaign_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _countCard('Events', _loading && _updates == null ? '—' : '${events.length}', Icons.event_available_outlined)),
              ]),
              const SizedBox(height: 26),
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Latest notices', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Published by Loyola College', style: TextStyle(color: AppColors.white54, fontSize: 11)),
                ])),
                TextButton(onPressed: () => context.push(AppRoutes.updates), child: const Text('View all')),
              ]),
              const SizedBox(height: 9),
              if (_loading && _updates == null)
                _message('Fetching the latest college updates…', Icons.sync_rounded)
              else if (_error != null && _updates == null)
                _retryCard()
              else if (preview.isEmpty)
                _message('No notices are available right now.', Icons.inbox_outlined)
              else
                ...preview.map(_noticeCard),
              const SizedBox(height: 24),
              const Text('Your campus toolkit', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _toolTile(
                icon: Icons.calendar_month_rounded,
                title: 'Academic calendar',
                subtitle: 'Browse official academic dates month by month',
                onTap: () => context.push(AppRoutes.calendar),
              ),
              _toolTile(
                icon: Icons.notifications_active_outlined,
                title: 'All announcements',
                subtitle: 'Notices, circulars and downloadable documents',
                onTap: () => context.push(AppRoutes.updates),
              ),
              const SizedBox(height: 10),
              const Text('Timetable note: a verified weekly class timetable is not currently connected to this screen. We will not display sample classes as if they were official.', style: TextStyle(color: AppColors.white38, fontSize: 11, height: 1.45)),
              if (_updates?['fetchedAt'] != null) ...[
                const SizedBox(height: 16),
                Text('Last synced: ${_updates!['fetchedAt']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white38, fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarFeature(BuildContext context) => InkWell(
    onTap: () => context.push(AppRoutes.calendar),
    borderRadius: BorderRadius.circular(23),
    child: Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF283C35), Color(0xFF17251F)]),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.crimson.withValues(alpha: .2)),
      ),
      child: Row(children: [
        Container(width: 49, height: 49, decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.calendar_month_rounded, color: AppColors.crimson, size: 25)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Academic calendar', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Plan around official college dates', style: TextStyle(color: AppColors.white70, fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.crimson),
      ]),
    ),
  );

  Widget _countCard(String title, String count, IconData icon) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.outline)),
    child: Row(children: [Icon(icon, color: AppColors.crimson, size: 19), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(count, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)), Text(title, style: const TextStyle(color: AppColors.white54, fontSize: 11))])]),
  );

  Widget _noticeCard(CollegeAnnouncement item) => InkWell(
    onTap: () => _open(item.url),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(item.isPdf ? Icons.picture_as_pdf_outlined : Icons.campaign_outlined, color: AppColors.crimson, size: 19)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 5),
          Text(item.source, style: const TextStyle(color: AppColors.white54, fontSize: 10)),
        ])),
        const SizedBox(width: 7),
        const Icon(Icons.open_in_new_rounded, color: AppColors.white38, size: 16),
      ]),
    ),
  );

  Widget _toolTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline)),
    child: ListTile(onTap: onTap, leading: Icon(icon, color: AppColors.crimson), title: Text(title, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: AppColors.white54, fontSize: 11)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.white38)),
  );

  Widget _message(String message, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.outline)),
    child: Row(children: [Icon(icon, color: AppColors.white54, size: 18), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: AppColors.white54, fontSize: 12)))]),
  );

  Widget _retryCard() => _message('College updates could not be loaded. Tap refresh or pull down to retry.', Icons.cloud_off_outlined);

  Future<void> _open(String url) async {
    final opened = await openAnnouncementLink(url);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this notice.')));
  }
}
