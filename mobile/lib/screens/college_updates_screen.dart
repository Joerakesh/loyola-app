import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/constants/app_colors.dart';
import '../models/college_announcement.dart';
import '../services/college_updates_service.dart';
import '../utils/announcement_links.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('College updates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading && _updates == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _updates == null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: () => _load(refresh: true),
                  color: AppColors.crimson,
                  backgroundColor: AppColors.backgroundSoft,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    children: [
                      const Text('What’s happening at Loyola', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 7),
                      const Text(
                        'Notices and events from the Loyola College website.',
                        style: TextStyle(color: AppColors.white54, fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 25),
                      _calendarShortcut(),
                      const SizedBox(height: 24),
                      _sectionHeading('Announcements', announcements.length),
                      const SizedBox(height: 10),
                      if (announcements.isEmpty)
                        _empty('No announcements are available right now.')
                      else
                        ...announcements.map(_announcementItem),
                      const SizedBox(height: 26),
                      _sectionHeading('Upcoming events', events.length),
                      const SizedBox(height: 10),
                      if (events.isEmpty)
                        _empty('No upcoming events were found.')
                      else
                        ...events.map(_eventItem),
                      if (_updates?['fetchedAt'] != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Last synced: ' + _updates!['fetchedAt'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.white38, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _calendarShortcut() {
    return InkWell(
      onTap: () => context.push(AppRoutes.calendar),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.crimson.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.crimson),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Academic calendar', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Browse dates and day-wise schedule', style: TextStyle(color: AppColors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.crimson),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String title, int count, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.white54, fontSize: 12)),
              ],
            ],
          ),
        ),
        Text(count.toString(), style: const TextStyle(color: AppColors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _announcementItem(Map<String, dynamic> item) {
    final announcement = CollegeAnnouncement.fromJson(item);
    final details = item['details']?.toString().trim() ?? '';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.crimson, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.4),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(details, style: const TextStyle(color: AppColors.white70, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 12),
          _linkButton(announcement.isPdf ? 'Read full notice (PDF)' : 'Open notice', () => _openLink(announcement.url)),
        ],
      ),
    );
  }

  Widget _eventItem(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'College event';
    final details = item['details']?.toString().trim() ?? '';
    final department = item['department']?.toString().trim() ?? '';
    final date = item['dateLabel']?.toString().trim() ?? '';
    final location = item['location']?.toString().trim() ?? '';
    final url = item['url']?.toString() ?? '';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.4)),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 9),
            _detailLine(Icons.calendar_today_outlined, date),
          ],
          if (department.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailLine(Icons.account_balance_outlined, department),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailLine(Icons.location_on_outlined, location),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(details, style: const TextStyle(color: AppColors.white54, fontSize: 12, height: 1.45)),
          ],
          if (url.isNotEmpty) ...[
            const SizedBox(height: 10),
            _linkButton('View event details', () => _openLink(url)),
          ],
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.white38),
        const SizedBox(width: 7),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.white70, fontSize: 12, height: 1.4))),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: padding ?? const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: child,
    );
  }

  Widget _linkButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.crimson,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _empty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: const TextStyle(color: AppColors.white54, fontSize: 13, height: 1.4)),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38, color: AppColors.white54),
            const SizedBox(height: 12),
            Text(_error ?? 'Unable to load college updates.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white70, fontSize: 13)),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => _load(refresh: true), child: const Text('Try again')),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final opened = await openAnnouncementLink(url);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this link.')),
    );
  }
}
