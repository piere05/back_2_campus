// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_layout.dart';

class StudentInterestedJobInternshipPage extends StatefulWidget {
  const StudentInterestedJobInternshipPage({super.key});

  @override
  State<StudentInterestedJobInternshipPage> createState() =>
      _StudentInterestedJobInternshipPageState();
}

class _StudentInterestedJobInternshipPageState
    extends State<StudentInterestedJobInternshipPage> {
  final email = FirebaseAuth.instance.currentUser!.email!;
  bool loading = true;
  String search = '';

  List<Map<String, dynamic>> allData = [];

  @override
  void initState() {
    super.initState();
    loadInterestedJobs();
  }

  Future<void> loadInterestedJobs() async {
    final jobsSnap = await FirebaseFirestore.instance
        .collection('job_internships')
        .get();

    final List<Map<String, dynamic>> temp = [];

    for (final jobDoc in jobsSnap.docs) {
      final interestSnap = await jobDoc.reference
          .collection('interested')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (interestSnap.docs.isNotEmpty) {
        final interest = interestSnap.docs.first.data();

        temp.add({
          'title': (jobDoc['title'] ?? '').toString(),
          'role': (jobDoc['role'] ?? '').toString(),
          'company': (jobDoc['company'] ?? '').toString(),
          'date': interest['timestamp'],
        });
      }
    }

    setState(() {
      allData = temp;
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filteredData {
    if (search.isEmpty) return allData;

    final q = search.toLowerCase();
    return allData.where((d) {
      return d['title'].toLowerCase().contains(q) ||
          d['role'].toLowerCase().contains(q) ||
          d['company'].toLowerCase().contains(q);
    }).toList();
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
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

                filteredData.isEmpty
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
                              DataColumn(label: Text('INTERESTED DATE')),
                            ],
                            rows: filteredData.map((d) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(d['title'].toUpperCase())),
                                  DataCell(Text(d['role'].toUpperCase())),
                                  DataCell(Text(d['company'].toUpperCase())),
                                  DataCell(Text(formatDate(d['date']))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}
