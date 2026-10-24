import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../widgets/theme_toggle.dart';
import 'about_page.dart';
import 'admin_home.dart';
import 'intern_home.dart';
import 'notifications_screen.dart';
import 'overview_page.dart';
import 'report_screen.dart';

class _Nav {
  final String title;
  final IconData icon;

  const _Nav(this.title, this.icon);
}

class Shell extends StatefulWidget {
  final String uid;
  final String name;
  final String role;

  const Shell({
    super.key,
    required this.uid,
    required this.name,
    required this.role,
  });

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  bool get isAdmin => widget.role == 'admin';

  List<_Nav> get items => [
    const _Nav('Overview', Icons.dashboard_outlined),
    _Nav(isAdmin ? 'All tasks' : 'My tasks', Icons.checklist),
    if (isAdmin) const _Nav('Submissions', Icons.fact_check_outlined),
    if (isAdmin) const _Nav('Reports', Icons.insights_outlined),
    const _Nav('Settings', Icons.settings_outlined),
    const _Nav('About', Icons.info_outline),
  ];

  Widget _page(String title) {
    switch (title) {
      case 'Overview':
        return OverviewPage(
          uid: widget.uid,
          name: widget.name,
          isAdmin: isAdmin,
        );
      case 'My tasks':
        return InternHome(uid: widget.uid, name: widget.name);
      case 'All tasks':
        return const AdminHome(key: ValueKey('all'));
      case 'Submissions':
        return const AdminHome(
          key: ValueKey('sub'),
          initialFilter: 'submitted',
        );
      case 'Reports':
        return const ReportScreen();
      case 'About':
        return const AboutPage();
      default:
        return const _SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = items;
    final title = nav[_index].title;

    final sidebar = _SideBar(
      items: nav,
      index: _index,
      name: widget.name,
      isAdmin: isAdmin,
      onSelect: (i) {
        setState(() => _index = i);
        Navigator.pop(context);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          _Bell(uid: widget.uid, isAdmin: isAdmin),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(child: sidebar),
      body: _page(title),
    );
  }
}

class _Bell extends StatelessWidget {
  final String uid;
  final bool isAdmin;

  const _Bell({required this.uid, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: NotificationService().mine(uid, isAdmin),
      builder: (context, snapshot) {
        final count =
            snapshot.data?.docs.where((doc) {
              final readBy = doc.data()['readBy'];
              return readBy is! List || !readBy.contains(uid);
            }).length ??
            0;
        return IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(uid: uid, isAdmin: isAdmin),
            ),
          ),
        );
      },
    );
  }
}

class _SideBar extends StatelessWidget {
  final List<_Nav> items;
  final int index;
  final String name;
  final bool isAdmin;
  final ValueChanged<int> onSelect;

  const _SideBar({
    required this.items,
    required this.index,
    required this.name,
    required this.isAdmin,
    required this.onSelect,
  });

  Widget _badge(String title) {
    if (title != 'Submissions') return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TaskService().allTasks(),
      builder: (context, snapshot) {
        final count =
            snapshot.data?.docs
                .where((doc) => doc['status'] == 'submitted')
                .length ??
            0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(
                    Icons.task_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Task Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: i == index
                          ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          items[i].icon,
                          color: i == index ? colorScheme.primary : null,
                        ),
                        title: Text(
                          items[i].title,
                          style: TextStyle(
                            fontWeight: i == index
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: _badge(items[i].title),
                        onTap: () => onSelect(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(isAdmin ? 'Administrator' : 'Intern'),
            trailing: IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().logout(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: dark,
            onChanged: setDarkMode,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => AuthService().logout(),
          ),
        ),
      ],
    );
  }
}
