import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/college_updates_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

class CollegeUpdatesScreen extends StatefulWidget {
  const CollegeUpdatesScreen({super.key, required this.service});

  final CollegeUpdatesService service;

  @override
  State<CollegeUpdatesScreen> createState() => _CollegeUpdatesScreenState();
}

class _CollegeUpdatesScreenState extends State<CollegeUpdatesScreen> {
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
    return value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final announcements = _items(_updates?['announcements']);
    final events = _items(_updates?['events']);
    final calendar = _updates?['calendar'] is Map
        ? (_updates!['calendar'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final calendarEntries = _items(calendar['entries']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _load(refresh: true),
            color: AppColors.white,
            backgroundColor: AppColors.glass,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'College Updates',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loading ? null : () => _load(refresh: true),
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading && _updates == null)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && _updates == null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: AppColors.white54, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.white70),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => _load(refresh: true),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _sectionTitle('Announcements', announcements.length),
                        if (announcements.isEmpty)
                          _empty('No announcements were found on the college website.')
                        else
                          ...announcements.map((item) => _announcementCard(item)),
                        const SizedBox(height: 24),
                        _sectionTitle('Upcoming Events', events.length),
                        if (events.isEmpty)
                          _empty('No upcoming events were found.')
                        else
                          ...events.map((item) => _eventCard(item)),
                        const SizedBox(height: 24),
                        _sectionTitle(
                          'Academic Calendar',
                          calendarEntries.length,
                          subtitle: calendar['month']?.toString(),
                        ),
                        if (calendarEntries.isEmpty)
                          _empty('No calendar entries were returned by the college website.')
                        else
                          ...calendarEntries.map((item) => _calendarCard(item)),
                        if (_updates?['fetchedAt'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Last synced: ${_updates!['fetchedAt']}',
                            style: const TextStyle(color: AppColors.white30, fontSize: 11),
                          ),
                        ],
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, int count, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: AppColors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text('$count', style: const TextStyle(color: AppColors.white54, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        child: Text(text, style: const TextStyle(color: AppColors.white54, fontSize: 13)),
      ),
    );
  }

  Widget _announcementCard(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.crimson),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['title']?.toString() ?? 'Announcement',
                style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> item) {
    final metadata = [
      item['department']?.toString(),
      item['dateLabel']?.toString(),
      item['location']?.toString(),
    ].where((value) => value != null && value.isNotEmpty).join(' · ');
    final details = metadata.isNotEmpty
        ? metadata
        : (item['details']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title']?.toString() ?? 'College event', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(details, style: const TextStyle(color: AppColors.white54, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _calendarCard(Map<String, dynamic> item) {
    final event = item['event']?.toString() ?? '';
    final dayOrder = item['dayOrder']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(item['dateLabel']?.toString() ?? '', style: const TextStyle(color: AppColors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            Expanded(
              child: Text(
                event.isEmpty ? 'No event' : event,
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
            if (dayOrder != null && dayOrder.isNotEmpty)
              Text(dayOrder, style: const TextStyle(color: AppColors.crimson, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
