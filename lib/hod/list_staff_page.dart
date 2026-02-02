// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_staff_page.dart';
import 'hod_layout.dart';

class ListStaffPage extends StatefulWidget {
  const ListStaffPage({super.key});

  @override
  State<ListStaffPage> createState() => _ListStaffPageState();
}

class _ListStaffPageState extends State<ListStaffPage> {
  String search = '';
  String hodEmail = '';

  @override
  void initState() {
    super.initState();
    hodEmail = FirebaseAuth.instance.currentUser!.email!;
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search staff...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (v) => setState(() => search = v.toLowerCase()),
          ),

          const SizedBox(height: 20),

          // 📊 Staff Table
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('staff')
                  .where('hodEmail', isEqualTo: hodEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No staff found'));
                }

                final staffDocs = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final name = (d['name'] ?? '').toString().toLowerCase();
                  final email = (d['email'] ?? '').toString().toLowerCase();
                  final designation = (d['designation'] ?? '')
                      .toString()
                      .toLowerCase();
                  final contact = (d['contact'] ?? '').toString();

                  return name.contains(search) ||
                      email.contains(search) ||
                      designation.contains(search) ||
                      contact.contains(search);
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        _headerRow(),
                        ...staffDocs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return _dataRow(doc.id, d);
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER ROW =================
  Widget _headerRow() {
    return Row(
      children: [
        _cell('Profile', 70, header: true, center: true),
        _cell('Name', 160, header: true),
        _cell('Email', 220, header: true),
        _cell('Designation', 160, header: true),
        _cell('Contact', 140, header: true),
        _cell('Action', 120, header: true, center: true),
      ],
    );
  }

  // ================= DATA ROW =================
  Widget _dataRow(String docId, Map<String, dynamic> d) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _profileImage(d['profileImage']),
        ),
        _cell(d['name'] ?? '', 160),
        _cell(d['email'] ?? '', 220),
        _cell(d['designation'] ?? '', 160),
        _cell(d['contact']?.toString() ?? '', 140),
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddStaffPage(staffDoc: null),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(docId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= CELL =================
  Widget _cell(
    String text,
    double width, {
    bool header = false,
    bool center = false,
  }) {
    return Container(
      width: width,
      height: 48,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: header ? Colors.grey.shade200 : null,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ================= PROFILE IMAGE =================
  Widget _profileImage(String? base64) {
    if (base64 == null || base64.isEmpty) {
      return const CircleAvatar(radius: 16, child: Icon(Icons.person));
    }
    return CircleAvatar(
      radius: 16,
      backgroundImage: MemoryImage(base64Decode(base64)),
    );
  }

  // ================= DELETE =================
  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Staff'),
        content: const Text('Are you sure you want to delete this staff?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance.collection('staff').doc(docId).delete();
    }
  }
}
