// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hod_layout.dart';
import 'manage_alumni.dart';

class ListAlumniPage extends StatelessWidget {
  const ListAlumniPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      return const Center(child: Text('User not logged in'));
    }

    return HodLayout(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hod')
            .where('email', isEqualTo: email)
            .limit(1)
            .snapshots(),
        builder: (context, hodSnap) {
          if (!hodSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hodSnap.data!.docs.isEmpty) {
            return const Center(child: Text('HOD record not found'));
          }

          final hodData =
              hodSnap.data!.docs.first.data() as Map<String, dynamic>;

          final String department = hodData['department'] ?? '';
          final String hodEmail = hodData['email'] ?? '';

          final col = FirebaseFirestore.instance
              .collection('alumni')
              .where('department', isEqualTo: department)
              .where('hodEmail', isEqualTo: hodEmail);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Alumni',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageAlumniPage(),
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
                      'Add Alumni',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: col.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text('No alumni found'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Contact')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Batch')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;

                          return DataRow(
                            cells: [
                              DataCell(Text(data['name'] ?? '')),
                              DataCell(Text(data['contact'] ?? '')),
                              DataCell(Text(data['email'] ?? '')),
                              DataCell(
                                Text(
                                  '${data['from_year'] ?? ''} - ${data['to_year'] ?? ''}',
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ManageAlumniPage(
                                              uid: d.id,
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
                                            title: const Text('Delete Alumni'),
                                            content: const Text(
                                              'Are you sure?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('alumni')
                                                      .doc(d.id)
                                                      .delete();
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
          );
        },
      ),
    );
  }
}
