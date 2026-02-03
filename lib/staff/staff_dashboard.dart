// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'staff_layout.dart';
import 'list_student.dart';
import 'list_alumini.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  String staffName = '';
  String hodEmail = '';
  bool loading = true;

  final loggedInEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  void initState() {
    super.initState();
    loadStaffDetails();
  }

  Future<void> loadStaffDetails() async {
    final snap = await FirebaseFirestore.instance
        .collection('staff')
        .where('email', isEqualTo: loggedInEmail)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      staffName = data['name'] ?? '';
      hodEmail = data['hodEmail'] ?? '';
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StaffLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== GREETING =====
                Text(
                  'Hi, $staffName 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome back',
                  style: TextStyle(color: Colors.grey),
                ),

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
                          // ===== TOTAL FINAL STUDENTS =====
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('students')
                                .where('staff_mail', isEqualTo: loggedInEmail)
                                .snapshots(),
                            builder: (context, snap) {
                              final count = snap.hasData
                                  ? snap.data!.docs.length
                                  : 0;

                              return _DashboardTile(
                                title: 'Total Final Students',
                                count: count.toString(),
                                icon: Icons.school,
                                color: const Color(0xFF0D9488),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StaffListStudentsPage(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          // ===== TOTAL ALUMNI =====
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('alumni')
                                .where('hodEmail', isEqualTo: hodEmail)
                                .snapshots(),
                            builder: (context, snap) {
                              final count = snap.hasData
                                  ? snap.data!.docs.length
                                  : 0;

                              return _DashboardTile(
                                title: 'Total Alumni',
                                count: count.toString(),
                                icon: Icons.people,
                                color: const Color(0xFF2563EB),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StaffViewAlumniTablePage(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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
