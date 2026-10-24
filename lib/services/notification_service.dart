import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _collection = FirebaseFirestore.instance.collection('notifications');

  Future<void> send({
    String? toUid,
    String? toRole,
    required String title,
    required String body,
  }) => _collection.add({
    'toUid': toUid,
    'toRole': toRole,
    'title': title,
    'body': body,
    'readBy': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> mine(String uid, bool isAdmin) =>
      isAdmin
      ? _collection.where('toRole', isEqualTo: 'admin').snapshots()
      : _collection.where('toUid', isEqualTo: uid).snapshots();

  Future<void> markRead(String id, String uid) => _collection.doc(id).update({
    'readBy': FieldValue.arrayUnion([uid]),
  });
}
