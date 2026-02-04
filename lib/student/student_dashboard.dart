// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_job_internship_list_page.dart';
import 'student_layout.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String studentName = '';
  String department = '';
  bool loading = false;

  final String loggedInEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  void initState() {
    super.initState();
    loadStudentDetails();
  }

  Future<void> loadStudentDetails() async {
    final snap = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: loggedInEmail)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      studentName = data['name'] ?? '';
      department = data['department'] ?? '';
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== GREETING =====
                Text(
                  'Hi, $studentName 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(department, style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 20),

                // ===== DASHBOARD TILES =====
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isSmall = constraints.maxWidth <= 350;

                      return GridView.count(
                        crossAxisCount: isSmall ? 2 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          // ===== JOBS / INTERNSHIPS =====
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('job_internships')
                                .where('department', isEqualTo: department)
                                .where('status', isEqualTo: 'ongoing')
                                .snapshots(),
                            builder: (context, snap) {
                              final count = snap.hasData
                                  ? snap.data!.docs.length
                                  : 0;

                              return _DashboardTile(
                                title: 'Jobs / Internships',
                                count: count.toString(),
                                icon: Icons.work,
                                color: const Color(0xFF2563EB),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentJobInternshipListPage(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          // ===== APPLIED JOBS =====
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ================= TILE =================
class _DashboardTile extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              count,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
