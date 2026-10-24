import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String fmtDate(Timestamp timestamp) {
  final date = timestamp.toDate();
  return '${date.day}/${date.month}/${date.year}';
}

Color statusColor(String status) {
  switch (status) {
    case 'in_progress':
      return Colors.orange;
    case 'submitted':
      return Colors.blue;
    case 'completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class TaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool showIntern;
  final VoidCallback onTap;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    this.showIntern = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = task['status'] as String;
    final deadline = task['deadline'] as Timestamp;
    final overdue =
        status != 'completed' && deadline.toDate().isBefore(DateTime.now());
    final color = statusColor(status);
    final description = task['description'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.replaceAll('_', ' '),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (showIntern) ...[
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task['assignedToName'] as String,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Icon(
                            Icons.event,
                            size: 16,
                            color: overdue ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            overdue
                                ? '${fmtDate(deadline)} (overdue)'
                                : fmtDate(deadline),
                            style: TextStyle(
                              fontSize: 13,
                              color: overdue ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
