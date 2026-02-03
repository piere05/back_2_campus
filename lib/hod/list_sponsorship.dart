// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'hod_layout.dart';
import 'add_edit_sponsorship.dart';
import 'view_sponsorship.dart';

class ListSponsorshipPage extends StatelessWidget {
  const ListSponsorshipPage({super.key});

  String formatDate(Timestamp ts) {
    return DateFormat('dd/MM/yyyy').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('sponsorships');

    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Sponsorship',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditSponsorshipPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Add Sponsorship',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// TABLE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: col.orderBy('created_at', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No sponsorship found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              data['created_at'] != null
                                  ? formatDate(data['created_at'])
                                  : '',
                            ),
                          ),
                          DataCell(Text(data['title'] ?? '')),
                          DataCell(
                            SizedBox(
                              width: 300,
                              child: Text(
                                data['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ViewSponsorshipPage(data: data),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditSponsorshipPage(
                                          docId: d.id,
                                          data: data,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Sponsorship'),
                                        content: const Text('Are you sure?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await col.doc(d.id).delete();
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
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
}
