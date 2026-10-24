import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const developer = 'Ateeq Ur Rahman';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget feature(IconData icon, String text) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(text),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary,
                child: const Icon(
                  Icons.task_alt,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Task Tracking App for Interns',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A mobile-based task management system that helps interns stay organized and '
                  'monitor their assigned work. Interns create tasks, set deadlines and track '
                  'progress in real time, while admins assign tasks, review submissions and '
                  'evaluate performance through progress reports.',
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key features',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                feature(Icons.add_task, 'Create tasks with deadlines'),
                feature(Icons.sync, 'Real-time progress tracking'),
                feature(Icons.fact_check_outlined, 'Admin review and feedback'),
                feature(Icons.insights_outlined, 'Progress reports'),
                feature(Icons.notifications_outlined, 'Instant notifications'),
              ],
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Built with',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Flutter')),
                    Chip(label: Text('Firebase Auth')),
                    Chip(label: Text('Cloud Firestore')),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.code, color: Colors.white),
            ),
            title: const Text('Developed by'),
            subtitle: const Text(developer),
          ),
        ),
      ],
    );
  }
}
