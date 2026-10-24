import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/task_service.dart';

class FilteredTaskList extends StatefulWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Widget Function(Doc doc) itemBuilder;
  final String initialFilter;

  const FilteredTaskList({
    super.key,
    required this.stream,
    required this.itemBuilder,
    this.initialFilter = 'all',
  });

  @override
  State<FilteredTaskList> createState() => _FilteredTaskListState();
}

class _FilteredTaskListState extends State<FilteredTaskList> {
  late String _filter;
  String _query = '';

  static const _filters = {
    'all': 'All',
    'pending': 'Pending',
    'in_progress': 'In progress',
    'submitted': 'Submitted',
    'completed': 'Completed',
    'overdue': 'Overdue',
  };

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  Widget _stat(String label, int value, Color color) => Expanded(
    child: Card(
      elevation: 0,
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );

  bool _matches(Map<String, dynamic> task) {
    final status = task['status'] as String;
    final deadline = task['deadline'] as Timestamp;
    final overdue =
        status != 'completed' && deadline.toDate().isBefore(DateTime.now());
    final matchesFilter =
        _filter == 'all' ||
        (_filter == 'overdue' ? overdue : status == _filter);
    final query = _query.toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        (task['title'] as String).toLowerCase().contains(query) ||
        (task['assignedToName'] as String).toLowerCase().contains(query);

    return matchesFilter && matchesQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by title or intern',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: _filters.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) => setState(() => _filter = entry.key),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = snapshot.data!.docs;
              final now = DateTime.now();
              final done = all
                  .where((doc) => doc['status'] == 'completed')
                  .length;
              final overdue = all
                  .where(
                    (doc) =>
                        doc['status'] != 'completed' &&
                        (doc['deadline'] as Timestamp).toDate().isBefore(now),
                  )
                  .length;
              final docs = all.where((doc) => _matches(doc.data())).toList()
                ..sort(
                  (a, b) => (a['deadline'] as Timestamp).compareTo(
                    b['deadline'] as Timestamp,
                  ),
                );

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _stat('Total', all.length, Colors.indigo),
                        _stat('Done', done, Colors.green),
                        _stat('Overdue', overdue, Colors.red),
                      ],
                    ),
                  ),
                  if (docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No tasks found')),
                    )
                  else
                    ...docs.map(widget.itemBuilder),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
