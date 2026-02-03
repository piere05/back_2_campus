// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hod_layout.dart';
import 'hod_list_students_page.dart';
import 'list_alumni.dart';
import 'list_staff_page.dart';

class HodDashboard extends StatelessWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final String? email = FirebaseAuth.instance.currentUser?.email;

    return HodLayout(
      child: email == null
          ? const Center(child: Text('User not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hod')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('HOD record not found'));
                }

                final hodData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final String hodName = hodData['name'] ?? 'HOD';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Welcome Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.waving_hand,
                              color: Colors.orange,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  hodName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔹 Dashboard Tiles (Responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;

                          if (constraints.maxWidth >= 900) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth >= 500) {
                            crossAxisCount = 2;
                          } else if (constraints.maxWidth < 350) {
                            crossAxisCount = 1; // only ultra-small screens
                          }

                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.6,
                                ),

                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('staff')
                                    .where('hodEmail', isEqualTo: email)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return _dashboardTile(
                                      title: 'Total Staff',
                                      count: '0',
                                      icon: Icons.groups,
                                      color: const Color(0xFF2563EB),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ListStaffPage(),
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  final count = snapshot.data!.docs.length
                                      .toString();

                                  return _dashboardTile(
                                    title: 'Total Staff',
                                    count: count,
                                    icon: Icons.groups,
                                    color: const Color(0xFF2563EB),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ListStaffPage(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('alumni')
                                    .where('hodEmail', isEqualTo: email)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return _dashboardTile(
                                      title: 'Total Alumni',
                                      count: '0',
                                      icon: Icons.school,
                                      color: const Color(0xFF16A34A),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ListAlumniPage(),
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  final count = snapshot.data!.docs.length
                                      .toString();

                                  return _dashboardTile(
                                    title: 'Total Alumni',
                                    count: count,
                                    icon: Icons.school,
                                    color: const Color(0xFF16A34A),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ListAlumniPage(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('students')
                                    .where('hodEmail', isEqualTo: email)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return _dashboardTile(
                                      title: 'Total Final Year Students',
                                      count: '0',
                                      icon: Icons.person_outline,
                                      color: const Color(0xFFF97316),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ListStaffPage(),
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  final count = snapshot.data!.docs.length
                                      .toString();

                                  return _dashboardTile(
                                    title: 'Total Final Year Students',
                                    count: count,
                                    icon: Icons.person_outline,
                                    color: const Color(0xFFF97316),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const HodListStudentsPage(),
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
                    ],
                  ),
                );
              },
            ),
    );
  }

  // 🔹 Tile Widget
  static Widget _dashboardTile({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            const Spacer(),
            Text(
              count,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
