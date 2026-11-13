import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AcademicsHubScreen extends StatelessWidget {
  const AcademicsHubScreen({super.key});

  static const _items = <({IconData icon, String title, String subtitle, String path})>[
    (icon: Icons.fact_check_outlined, title: 'Attendance', subtitle: 'Track classes and subject-wise attendance', path: '/academics/attendance'),
    (icon: Icons.menu_book_outlined, title: 'Subjects', subtitle: 'Your semester subjects and faculty', path: '/academics/subjects'),
    (icon: Icons.bar_chart_rounded, title: 'Internal marks', subtitle: 'Review assessment scores and totals', path: '/academics/marks'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academics'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Text('Your academic workspace', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Attendance, subjects and assessment results in one place.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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