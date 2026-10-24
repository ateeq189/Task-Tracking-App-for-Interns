import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import '../widgets/task_tile.dart';

class OverviewPage extends StatelessWidget {
  final String uid;
  final String name;
  final bool isAdmin;

  const OverviewPage({
    super.key,
    required this.uid,
    required this.name,
    required this.isAdmin,
  });

  static const green = Color(0xFF2D6A4F);
  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stream = isAdmin
        ? TaskService().allTasks()
        : TaskService().internTasks(uid);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs.map((doc) => doc.data()).toList();
        final total = tasks.length;
        final inProgress = tasks
            .where((task) => task['status'] == 'in_progress')
            .length;
        final review = tasks
            .where((task) => task['status'] == 'submitted')
            .length;
        final done = tasks
            .where((task) => task['status'] == 'completed')
            .length;
        final pct = total == 0 ? 0.0 : done / total;
        final upcoming =
            tasks.where((task) => task['status'] != 'completed').toList()..sort(
              (a, b) => (a['deadline'] as Timestamp).compareTo(
                b['deadline'] as Timestamp,
              ),
            );

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            final columns = wide ? 4 : 2;
            const gap = 12.0;
            final cardWidth =
                (constraints.maxWidth - 32 - gap * (columns - 1)) / columns;

            Widget stat(
              String label,
              int value,
              String chip,
              IconData icon,
              Color color,
            ) => SizedBox(
              width: cardWidth,
              child: _StatCard(
                label: label,
                value: value,
                chip: chip,
                icon: icon,
                color: color,
              ),
            );

            final chartCard = _card(
              context,
              SizedBox(
                height: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'A little better, every day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: green.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        const Text('Assigned', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 14),
                        const Icon(Icons.circle, size: 10, color: green),
                        const SizedBox(width: 4),
                        const Text('Completed', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _chart(tasks)),
                  ],
                ),
              ),
            );

            final goalCard = Container(
              height: 300,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'WEEKLY TEAM GOAL' : 'MY PROGRESS',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    pct >= 0.5
                        ? 'Look at you growing.'
                        : 'Keep going, you got this.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 88,
                              height: 88,
                              child: CircularProgressIndicator(
                                value: pct,
                                strokeWidth: 9,
                                backgroundColor: Colors.white24,
                                color: const Color(0xFFB7E4C7),
                              ),
                            ),
                            Text(
                              '${(pct * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$done of $total tasks',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'A little closer to your goals.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            );

            final upcomingCard = _card(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coming up next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'A little heads-up for your week.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (upcoming.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nothing due. Nice!'),
                    )
                  else
                    ...upcoming.take(4).map((task) {
                      final deadline = (task['deadline'] as Timestamp).toDate();
                      final overdue = deadline.isBefore(DateTime.now());
                      final status = task['status'] as String;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: (overdue ? Colors.red : green).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _months[deadline.month - 1],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: overdue ? Colors.red : green,
                                ),
                              ),
                              Text(
                                '${deadline.day}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          task['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          isAdmin
                              ? task['assignedToName'] as String
                              : status.replaceAll('_', ' '),
                        ),
                        trailing: Icon(
                          Icons.circle,
                          size: 10,
                          color: statusColor(status),
                        ),
                      );
                    }),
                ],
              ),
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Welcome back, ${name.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'A little focus today. A lot of progress tomorrow.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    stat(
                      'Total tasks',
                      total,
                      'Every step counts',
                      Icons.checklist,
                      green,
                    ),
                    stat(
                      'In progress',
                      inProgress,
                      'On track',
                      Icons.schedule,
                      Colors.blue,
                    ),
                    stat(
                      'Pending review',
                      review,
                      'Ready for feedback',
                      Icons.description_outlined,
                      Colors.orange,
                    ),
                    stat(
                      'Completed',
                      done,
                      '${(pct * 100).round()}% of all tasks',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chartCard),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: goalCard),
                    ],
                  )
                else ...[
                  chartCard,
                  const SizedBox(height: 12),
                  goalCard,
                ],
                const SizedBox(height: 16),
                upcomingCard,
                const SizedBox(height: 80),
              ],
            );
          },
        );
      },
    );
  }

  Widget _card(BuildContext context, Widget child) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );

  Widget _chart(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    DateTime? timestamp(dynamic value) =>
        value is Timestamp ? value.toDate() : null;

    final assigned = <FlSpot>[];
    final completed = <FlSpot>[];
    for (var i = 0; i < 7; i++) {
      final end = days[i].add(const Duration(days: 1));
      var assignedCount = 0;
      var completedCount = 0;
      for (final task in tasks) {
        final created = timestamp(task['createdAt']) ?? now;
        if (created.isBefore(end)) assignedCount++;
        if (task['status'] == 'completed') {
          final doneAt = timestamp(task['completedAt']) ?? created;
          if (doneAt.isBefore(end)) completedCount++;
        }
      }
      assigned.add(FlSpot(i.toDouble(), assignedCount.toDouble()));
      completed.add(FlSpot(i.toDouble(), completedCount.toDouble()));
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    names[days[index].weekday - 1],
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: assigned,
            isCurved: true,
            preventCurveOverShooting: true,
            color: green.withValues(alpha: 0.35),
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: completed,
            isCurved: true,
            preventCurveOverShooting: true,
            color: green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: green.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String chip;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.chip,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(chip, style: TextStyle(fontSize: 11, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
