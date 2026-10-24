import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../widgets/filtered_task_list.dart';
import '../widgets/task_tile.dart';

class InternHome extends StatelessWidget {
  final String uid;
  final String name;

  const InternHome({super.key, required this.uid, required this.name});

  Future<void> _addTask(BuildContext context) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    DateTime? deadline;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_task, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 10),
                const Text('New Task'),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: desc,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          deadline == null
                              ? 'Pick deadline'
                              : 'Due: ${deadline!.day}/${deadline!.month}/${deadline!.year}',
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (d != null) setS(() => deadline = d);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty || deadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a title and pick a deadline'),
                      ),
                    );
                    return;
                  }
                  try {
                    await TaskService().addTask(
                      title: title.text.trim(),
                      description: desc.text.trim(),
                      deadline: deadline!,
                      assignedTo: uid,
                      assignedToName: name,
                      createdBy: uid,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on FirebaseException catch (error) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Could not add task: ${error.message}'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      title.dispose();
      desc.dispose();
    }
  }

  Future<void> _openTask(BuildContext context, Doc doc) => showDialog<void>(
    context: context,
    builder: (_) => _TaskDialog(doc: doc, name: name),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: FilteredTaskList(
        stream: TaskService().internTasks(uid),
        itemBuilder: (doc) =>
            TaskTile(task: doc.data(), onTap: () => _openTask(context, doc)),
      ),
    );
  }
}

class _TaskDialog extends StatefulWidget {
  final Doc doc;
  final String name;

  const _TaskDialog({required this.doc, required this.name});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final Map<String, dynamic> t = widget.doc.data();
  late String status = t['status'] as String;
  late final TextEditingController submission = TextEditingController(
    text: t['submission'] as String? ?? '',
  );

  @override
  void dispose() {
    submission.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = t['status'] == 'completed';
    final description = t['description'] as String? ?? '';
    final feedback = t['feedback'] as String? ?? '';

    return AlertDialog(
      title: Text(t['title'] as String),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) Text(description),
            const SizedBox(height: 12),
            if (locked)
              const Text('Completed', style: TextStyle(color: Colors.green))
            else
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(
                    value: 'submitted',
                    child: Text('Submitted'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => status = value);
                },
              ),
            const SizedBox(height: 8),
            TextField(
              controller: submission,
              enabled: !locked,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Submission (link or notes)',
              ),
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Admin feedback: $feedback',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (!locked)
          FilledButton(
            onPressed: () async {
              try {
                await TaskService().updateTask(widget.doc.id, {
                  'status': status,
                  'submission': submission.text.trim(),
                });
                if (status == 'submitted' && t['status'] != 'submitted') {
                  await NotificationService().send(
                    toRole: 'admin',
                    title: 'Task submitted',
                    body: '${widget.name} submitted "${t['title']}"',
                  );
                }
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
            },
            child: const Text('Update'),
          ),
      ],
    );
  }
}
