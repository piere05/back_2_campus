import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_layout.dart';
import 'student_job_internship_view_page.dart';

class StudentJobInternshipListPage extends StatefulWidget {
  const StudentJobInternshipListPage({super.key});

  @override
  State<StudentJobInternshipListPage> createState() =>
      _StudentJobInternshipListPageState();
}

class _StudentJobInternshipListPageState
    extends State<StudentJobInternshipListPage> {
  String department = '';
  String search = '';
  bool loading = true;

  final email = FirebaseAuth.instance.currentUser!.email!;

  @override
  void initState() {
    super.initState();
    loadDepartment();
  }

  Future<void> loadDepartment() async {
    final snap = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      department = (snap.docs.first['department'] ?? '').toString();
    }
    setState(() => loading = false);
  }

  bool matchesSearch(Map<String, dynamic> d) {
    final q = search.toLowerCase();
    return (d['role'] ?? '').toString().toLowerCase().contains(q) ||
        (d['title'] ?? '').toString().toLowerCase().contains(q) ||
        (d['company'] ?? '').toString().toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'SEARCH ROLE, TITLE, COMPANY',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('job_internships')
                        .where('department', isEqualTo: department)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('NO OPPORTUNITIES FOUND'),
                        );
                      }

                      final docs = snap.data!.docs.where((d) {
                        return matchesSearch(d.data() as Map<String, dynamic>);
                      }).toList();

                      if (docs.isEmpty) {
                        return const Center(child: Text('NO MATCHING RESULTS'));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          final data = d.data() as Map<String, dynamic>;

                          return _JobTile(
                            data: data,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentJobInternshipViewPage(
                                    jobId: d.id,
                                    jobData: data,
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
class _JobTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _JobTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String type = (data['type'] ?? 'JOB').toString().toUpperCase();
    final bool isJob = type == 'JOB';

    final String role = (data['role'] ?? '').toString().toUpperCase();
    final String title = (data['title'] ?? '').toString().toUpperCase();
    final String description = (data['description'] ?? '').toString();

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color.fromARGB(25, 0, 0, 0), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isJob
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isJob
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF0D9488),
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              role,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: Color(0xFF374151))),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
          ],
        ),
      ),
    );
  }
}
