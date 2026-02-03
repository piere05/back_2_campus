// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_import

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'add_student.dart';
import 'staff_layout.dart';

class StaffListStudentsPage extends StatefulWidget {
  const StaffListStudentsPage({super.key});

  @override
  State<StaffListStudentsPage> createState() => _StaffListStudentsPageState();
}

class _StaffListStudentsPageState extends State<StaffListStudentsPage> {
  final TextEditingController searchCtrl = TextEditingController();

  bool loading = true;
  String hodEmail = '';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filtered = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD DATA =================
  Future<void> _loadStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    // get staff -> hodEmail
    final staffSnap = await FirebaseFirestore.instance
        .collection('staff')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (staffSnap.docs.isEmpty) {
      setState(() => loading = false);
      return;
    }

    hodEmail = staffSnap.docs.first['hodEmail'] ?? '';

    // get students for this hod
    final stuSnap = await FirebaseFirestore.instance
        .collection('students')
        .where('hodEmail', isEqualTo: hodEmail)
        .get();

    students = stuSnap.docs.map((d) => {...d.data(), 'uid': d.id}).toList();

    filtered = List.from(students);

    if (mounted) setState(() => loading = false);
  }

  // ================= SEARCH =================
  void _search(String v) {
    final q = v.toLowerCase();

    setState(() {
      filtered = students.where((s) {
        final batch = '${s['from_year'] ?? ''}-${s['to_year'] ?? ''}'
            .toLowerCase();

        return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
            (s['email'] ?? '').toString().toLowerCase().contains(q) ||
            (s['contact'] ?? '').toString().toLowerCase().contains(q) ||
            batch.contains(q);
      }).toList();
    });
  }

  // ================= PDF =================
  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'Students List',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['Name', 'Contact', 'Email', 'Batch'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            data: filtered.map((s) {
              return [
                s['name'] ?? '',
                s['contact'] ?? '',
                s['email'] ?? '',
                '${s['from_year'] ?? ''}-${s['to_year'] ?? ''}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: 'students_list.pdf');
    }
  }

  // ================= DELETE =================
  Future<void> _delete(String uid) async {
    await FirebaseFirestore.instance.collection('students').doc(uid).delete();
    _loadStudents();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return StaffLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    const Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: filtered.isEmpty ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // SEARCH
                TextField(
                  controller: searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, contact or batch',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No students found'),
                        ),
                      )
                    : Expanded(child: _table()),
              ],
            ),
    );
  }

  // ================= TABLE =================
  Widget _table() {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: c.maxWidth / 12,
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Contact')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Batch')),
              DataColumn(label: Text('Action')),
            ],
            rows: filtered.map((s) {
              return DataRow(
                cells: [
                  DataCell(Text(s['name'] ?? '')),
                  DataCell(Text(s['contact'] ?? '')),
                  DataCell(Text(s['email'] ?? '')),
                  DataCell(
                    Text('${s['from_year'] ?? ''}-${s['to_year'] ?? ''}'),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StaffAddEditStudentPage(
                                  uid: s['uid'],
                                  data: s,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Student'),
                                content: const Text('Are you sure?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _delete(s['uid']);
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
    );
  }
}
