import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

typedef Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class TaskService {
  final _tasks = FirebaseFirestore.instance.collection('tasks');

  Stream<QuerySnapshot<Map<String, dynamic>>> internTasks(String uid) =>
      _tasks.where('assignedTo', isEqualTo: uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> allTasks() => _tasks.snapshots();

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime deadline,
    required String assignedTo,
    required String assignedToName,
    required String createdBy,
  }) async {
    await _tasks.add({
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdBy': createdBy,
      'status': 'pending',
      'submission': '',
      'feedback': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (assignedTo != createdBy) {
      await NotificationService().send(
        toUid: assignedTo,
        title: 'New task assigned',
        body: title,
      );
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) =>
      _tasks.doc(id).update(data);

  Future<void> deleteTask(String id) => _tasks.doc(id).delete();

  Future<List<Doc>> interns() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'intern')
        .get();
    return snapshot.docs;
  }
}
