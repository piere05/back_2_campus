// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationBody extends StatelessWidget {
  const NotificationBody({super.key});

  String formatDate(Timestamp ts) {
    return DateFormat('dd/MM/yyyy').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('notifications');

    return StreamBuilder<QuerySnapshot>(
      stream: col.orderBy('created_at', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text('No notifications'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final data = snap.data!.docs[i].data() as Map<String, dynamic>;

            final String title = data['title'] ?? '';
            final String desc = data['description'] ?? '';
            final String createdBy = data['Createdby'] ?? '';
            final String createdName = data['Createdname'] ?? '';
            final Timestamp? ts = data['created_at'];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== TITLE ROW =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ===== DESCRIPTION =====
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),

                  const SizedBox(height: 10),

                  // ===== CREATED INFO (ONE LINE) =====
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Created by: $createdName • $createdBy'
                          '${ts != null ? ' • ${formatDate(ts)}' : ''}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
