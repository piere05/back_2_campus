// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'alumni_layout.dart';
import 'alumni_job_internship_view_page.dart';

class AlumniInterestedJobInternshipPage extends StatefulWidget {
  const AlumniInterestedJobInternshipPage({super.key});

  @override
  State<AlumniInterestedJobInternshipPage> createState() =>
      _AlumniInterestedJobInternshipPageState();
}

class _AlumniInterestedJobInternshipPageState
    extends State<AlumniInterestedJobInternshipPage> {
  final String email = FirebaseAuth.instance.currentUser!.email!;
  bool loading = true;
  String search = '';

  List<QueryDocumentSnapshot> jobDocs = [];

  @override
  void initState() {
    super.initState();
    loadInterestedJobs();
  }

  Future<void> loadInterestedJobs() async {
    final jobsSnap = await FirebaseFirestore.instance
        .collection('job_internships')
        .get();

    final List<QueryDocumentSnapshot> temp = [];

    for (final jobDoc in jobsSnap.docs) {
      final interestSnap = await jobDoc.reference
          .collection('interested')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (interestSnap.docs.isNotEmpty) {
        temp.add(jobDoc);
      }
    }

    if (!mounted) return;

    setState(() {
      jobDocs = temp;
      loading = false;
    });
  }

  bool matchesSearch(Map<String, dynamic> data) {
    final q = search.toLowerCase();
    return (data['title'] ?? '').toString().toLowerCase().contains(q) ||
        (data['role'] ?? '').toString().toLowerCase().contains(q) ||
        (data['company'] ?? '').toString().toLowerCase().contains(q);
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlumniLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 SEARCH
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'SEARCH TITLE / ROLE / COMPANY',
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

                jobDocs.isEmpty
                    ? const Expanded(
                        child: Center(
                          child: Text(
                            'NO RECORD FOUND',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 28,
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xFFF1F5F9),
                            ),
                            columns: const [
                              DataColumn(label: Text('TITLE')),
                              DataColumn(label: Text('ROLE')),
                              DataColumn(label: Text('COMPANY')),
                              DataColumn(label: Text('VIEW')),
                            ],
                            rows: jobDocs
                                .where((d) {
                                  final data = d.data() as Map<String, dynamic>;
                                  return matchesSearch(data);
                                })
                                .map((d) {
                                  final data = d.data() as Map<String, dynamic>;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          (data['title'] ?? '')
                                              .toString()
                                              .toUpperCase(),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          (data['role'] ?? '')
                                              .toString()
                                              .toUpperCase(),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          (data['company'] ?? '')
                                              .toString()
                                              .toUpperCase(),
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_red_eye,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AlumniJobInternshipViewPage(
                                                      jobId: d.id,
                                                      jobData: data,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}
