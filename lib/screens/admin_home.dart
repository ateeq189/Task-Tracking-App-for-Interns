import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import '../services/notification_service.dart';
import '../widgets/filtered_task_list.dart';
import '../widgets/task_tile.dart';

class AdminHome extends StatelessWidget {
  final String initialFilter;

  const AdminHome({super.key, this.initialFilter = 'all'});

  Future<void> _assignTask(BuildContext context) async {
    late final List<Doc> interns;
    try {
      interns = await TaskService().interns();
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load interns: ${error.message}')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (interns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No interns registered yet')),
      );
      return;
    }

    final title = TextEditingController();
    final description = TextEditingController();
    DateTime? deadline;
    var selected = interns.first;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Assign Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Doc>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Intern'),
                    items: interns
                        .map(
                          (doc) => DropdownMenuItem(
                            value: doc,
                            child: Text(doc['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selected = value);
                      }
                    },
                  ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      deadline == null
                          ? 'Pick deadline'
                          : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => deadline = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty || deadline == null) {
                    return;
                  }
                  try {
                    await TaskService().addTask(
                      title: title.text.trim(),
                      description: description.text.trim(),
                      deadline: deadline!,
                      assignedTo: selected.id,
                      assignedToName: selected['name'] as String,
                      createdBy: FirebaseAuth.instance.currentUser!.uid,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on FirebaseException catch (error) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not assign task: ${error.message}',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Assign'),
              ),
            ],
          ),
        ),
      );
    } finally {
      title.dispose();
      description.dispose();
    }
  }

  Future<void> _review(BuildContext context, Doc doc) async {
    final task = doc.data();
    final feedback = TextEditingController(
      text: task['feedback'] as String? ?? '',
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(task['title'] as String),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intern: ${task['assignedToName']}'),
                Text('Due: ${fmtDate(task['deadline'] as Timestamp)}'),
                Text(
                  'Status: ${(task['status'] as String).replaceAll('_', ' ')}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Submission: '
                  '${(task['submission'] as String? ?? '').isEmpty ? '-' : task['submission']}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedback,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Feedback'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (confirmationContext) => AlertDialog(
                    title: const Text('Delete task?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(confirmationContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(confirmationContext, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !ctx.mounted) return;

                try {
                  await TaskService().deleteTask(doc.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                } on FirebaseException catch (error) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not delete task: ${error.message}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => _updateReview(
                ctx,
                doc.id,
                assignedTo: task['assignedTo'] as String,
                title: task['title'] as String,
                status: 'in_progress',
                feedback: feedback.text.trim(),
              ),
              child: const Text('Send back'),
            ),
            FilledButton(
              onPressed: () => _updateReview(
                ctx,
                doc.id,
                assignedTo: task['assignedTo'] as String,
                title: task['title'] as String,
                status: 'completed',
                feedback: feedback.text.trim(),
              ),
              child: const Text('Mark completed'),
            ),
          ],
        ),
      );
    } finally {
      feedback.dispose();
    }
  }

  Future<void> _updateReview(
    BuildContext context,
    String taskId, {
    required String assignedTo,
    required String title,
    required String status,
    required String feedback,
  }) async {
    try {
      await TaskService().updateTask(taskId, {
        'status': status,
        'feedback': feedback,
        if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
      await NotificationService().send(
        toUid: assignedTo,
        title: status == 'completed' ? 'Task completed' : 'Task sent back',
        body: status == 'completed'
            ? '"$title" was marked completed'
            : '"$title" needs more work',
      );
      if (context.mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not update task or send notification: ${error.message}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _assignTask(context),
        icon: const Icon(Icons.assignment_add),
        label: const Text('Assign task'),
      ),
      body: FilteredTaskList(
        stream: TaskService().allTasks(),
        initialFilter: initialFilter,
        itemBuilder: (doc) => TaskTile(
          task: doc.data(),
          showIntern: true,
          onTap: () => _review(context, doc),
        ),
      ),
    );
  }
}
