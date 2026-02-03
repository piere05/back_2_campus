import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_job_intership.dart';
import 'hod_layout.dart';
import 'job_interest.dart';

class ManageJobInternshipPage extends StatefulWidget {
  const ManageJobInternshipPage({super.key});

  @override
  State<ManageJobInternshipPage> createState() =>
      _ManageJobInternshipPageState();
}

class _ManageJobInternshipPageState extends State<ManageJobInternshipPage> {
  String search = '';

  String _s(dynamic v) => (v ?? '').toString().toLowerCase();

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Job / Internship',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),

          TextField(
            decoration: InputDecoration(
              hintText: 'Search by Title / Company',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (v) => setState(() => search = v.toLowerCase()),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('job_internships')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No records found'));
                }

                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return _s(data['title']).contains(search) ||
                      _s(data['company']).contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No records found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Contact')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                data['type'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                data['title'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                data['company'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Text(
                                data['role'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Text(
                                data['contact'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AddEditJobInternshipPage(
                                              docId: d.id,
                                              data: data, // ✅ REQUIRED
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _delete(d.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const InterestedUsersSamplePage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance
        .collection('job_internships')
        .doc(id)
        .delete();
  }
}
