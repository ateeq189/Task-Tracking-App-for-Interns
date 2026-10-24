import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal_mobile_app/widgets/task_tile.dart';

void main() {
  testWidgets('task tile shows task, intern, deadline, and status', (
    tester,
  ) async {
    final deadline = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: {
              'title': 'Prepare onboarding checklist',
              'status': 'in_progress',
              'deadline': Timestamp.fromDate(deadline),
              'assignedToName': 'Amina',
            },
            showIntern: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Prepare onboarding checklist'), findsOneWidget);
    expect(find.text('in progress'), findsOneWidget);
    expect(find.textContaining('Amina  •  Due:'), findsOneWidget);
  });
}
