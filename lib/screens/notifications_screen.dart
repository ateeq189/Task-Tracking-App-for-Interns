import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return 'now';
  final difference = DateTime.now().difference(timestamp.toDate());
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

class NotificationsScreen extends StatelessWidget {
  final String uid;
  final bool isAdmin;

  const NotificationsScreen({
    super.key,
    required this.uid,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final service = NotificationService();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.mine(uid, isAdmin),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...snapshot.data!.docs]
            ..sort((a, b) {
              final timestampA = a.data()['createdAt'];
              final timestampB = b.data()['createdAt'];
              final timeA = timestampA is Timestamp
                  ? timestampA.millisecondsSinceEpoch
                  : 1 << 50;
              final timeB = timestampB is Timestamp
                  ? timestampB.millisecondsSinceEpoch
                  : 1 << 50;
              return timeB.compareTo(timeA);
            });

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No notifications yet'),
                ],
              ),
            );
          }

          bool isRead(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final readBy = doc.data()['readBy'];
            return readBy is List && readBy.contains(uid);
          }

          final unread = docs.where((doc) => !isRead(doc)).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (unread.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Mark all read'),
                    onPressed: () async {
                      try {
                        await Future.wait(
                          unread.map((doc) => service.markRead(doc.id, uid)),
                        );
                      } on FirebaseException catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not mark notifications as read: ${error.message}',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ...docs.map((doc) {
                final data = doc.data();
                final read = isRead(doc);
                final createdAt = data['createdAt'];
                return Card(
                  elevation: 0,
                  color: read
                      ? null
                      : colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: ListTile(
                    onTap: read
                        ? null
                        : () async {
                            try {
                              await service.markRead(doc.id, uid);
                            } on FirebaseException catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not mark notification as read: ${error.message}',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      data['title'] as String? ?? 'Notification',
                      style: TextStyle(
                        fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(data['body'] as String? ?? ''),
                    trailing: Text(
                      timeAgo(createdAt is Timestamp ? createdAt : null),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
