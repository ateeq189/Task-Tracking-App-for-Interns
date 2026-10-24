import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import '../widgets/task_tile.dart';

class _Stats {
  final String name;
  int total = 0, completed = 0, overdue = 0;

  _Stats(this.name);

  double get percent => total == 0 ? 0 : completed / total;
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: TaskService().allTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No tasks to report yet'));
          }

          final now = DateTime.now();
          final byStatus = <String, int>{
            'pending': 0,
            'in_progress': 0,
            'submitted': 0,
            'completed': 0,
          };
          final perIntern = <String, _Stats>{};
          var overdueTotal = 0;

          for (final doc in docs) {
            final task = doc.data();
            final status = task['status'] as String;
            byStatus[status] = (byStatus[status] ?? 0) + 1;
            final overdue =
                status != 'completed' &&
                (task['deadline'] as Timestamp).toDate().isBefore(now);
            final assignedTo = task['assignedTo'] as String;
            final stats = perIntern.putIfAbsent(
              assignedTo,
              () => _Stats(task['assignedToName'] as String),
            );
            stats.total++;
            if (status == 'completed') stats.completed++;
            if (overdue) {
              stats.overdue++;
              overdueTotal++;
            }
          }

          final interns = perIntern.values.toList()
            ..sort((a, b) => b.percent.compareTo(a.percent));
          final completedAll = byStatus['completed']!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _summary('Total', '${docs.length}', Colors.indigo),
                  _summary('Completed', '$completedAll', Colors.green),
                  _summary('Overdue', '$overdueTotal', Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Task status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: byStatus.entries
                        .where((entry) => entry.value > 0)
                        .map(
                          (entry) => PieChartSectionData(
                            value: entry.value.toDouble(),
                            color: statusColor(entry.key),
                            title: '${entry.value}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                alignment: WrapAlignment.center,
                children: byStatus.keys
                    .map(
                      (status) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: statusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(status.replaceAll('_', ' ')),
                        ],
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Intern performance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...interns.map(
                (stats) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stats.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text('${(stats.percent * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: stats.percent,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${stats.completed}/${stats.total} completed'
                          '  •  ${stats.overdue} overdue',
                          style: TextStyle(
                            color: stats.overdue > 0
                                ? Colors.red
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(String label, String value, Color color) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
