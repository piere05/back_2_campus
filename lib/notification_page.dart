// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationBody extends StatefulWidget {
  const NotificationBody({super.key});

  @override
  State<NotificationBody> createState() => _NotificationBodyState();
}

class _NotificationBodyState extends State<NotificationBody> {
  static const int pageSize = 7;
  int _currentPage = 0;

  String userDepartment = '';
  bool loading = true;

  String formatDate(Timestamp ts) {
    return DateFormat('dd/MM/yyyy').format(ts.toDate());
  }

  @override
  void initState() {
    super.initState();
    _loadUserDepartment();
  }

  // ================= LOAD USER DEPARTMENT =================
  Future<void> _loadUserDepartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final email = user.email!;
    final collections = ['hod', 'staff', 'students', 'alumni'];

    for (final col in collections) {
      final snap = await FirebaseFirestore.instance
          .collection(col)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        userDepartment = snap.docs.first['department'] ?? '';
        break;
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userDepartment.isEmpty) {
      return const Center(child: Text('Department not found'));
    }

    final col = FirebaseFirestore.instance
        .collection('notifications')
        .where('department', isEqualTo: userDepartment);

    return StreamBuilder<QuerySnapshot>(
      stream: col.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        /// 🔥 COPY DOCS + SORT (LATEST FIRST)
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final ta = (a['created_at'] as Timestamp?)?.toDate();
            final tb = (b['created_at'] as Timestamp?)?.toDate();
            return (tb ?? DateTime(1970)).compareTo(ta ?? DateTime(1970));
          });

        if (docs.isEmpty) {
          return const Center(child: Text('No notifications'));
        }

        /// PAGINATION
        final totalPages = (docs.length / pageSize).ceil();
        final start = _currentPage * pageSize;
        final end = (start + pageSize > docs.length)
            ? docs.length
            : start + pageSize;

        final pageDocs = docs.sublist(start, end);

        return Column(
          children: [
            /// ===== LIST =====
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pageDocs.length,
                itemBuilder: (context, i) {
                  final data = pageDocs[i].data() as Map<String, dynamic>;

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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withOpacity(0.12),
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
              ),
            ),

            /// ===== PAGINATION =====
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text(
                    'Page ${_currentPage + 1} of $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
