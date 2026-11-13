import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CampusHubScreen extends StatelessWidget {
  const CampusHubScreen({super.key});

  static const _items = <({IconData icon, String title, String subtitle, String path})>[
    (icon: Icons.campaign_outlined, title: 'Announcements', subtitle: 'Official college updates and notices', path: '/campus/updates'),
    (icon: Icons.event_available_outlined, title: 'Academic calendar', subtitle: 'Important dates and college events', path: '/campus/calendar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Text('Stay connected', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('The latest information and important dates from your campus.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          for (final item in _items) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                leading: CircleAvatar(child: Icon(item.icon)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(item.subtitle)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.go(item.path),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}