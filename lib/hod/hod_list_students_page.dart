// ignore_for_file: deprecated_member_use, unused_import

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'hod_layout.dart';

class HodListStudentsPage extends StatefulWidget {
  const HodListStudentsPage({super.key});

  @override
  State<HodListStudentsPage> createState() => _HodListStudentsPageState();
}

class _HodListStudentsPageState extends State<HodListStudentsPage> {
  String hodEmail = '';
  String search = '';

  final Map<String, String> staffNameCache = {};

  @override
  void initState() {
    super.initState();
    hodEmail = FirebaseAuth.instance.currentUser!.email!;
  }

  Future<String> _getStaffName(String staffMail) async {
    if (staffNameCache.containsKey(staffMail)) {
      return staffNameCache[staffMail]!;
    }

    final snap = await FirebaseFirestore.instance
        .collection('staff')
        .where('email', isEqualTo: staffMail)
        .limit(1)
        .get();

    final name = snap.docs.isNotEmpty
        ? snap.docs.first['name'] ?? 'Staff'
        : 'Staff';

    staffNameCache[staffMail] = name;
    return name;
  }

  // ================= PDF =================
  Future<void> exportPdf(List<Map<String, dynamic>> rows) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Students List',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Name', 'Contact', 'Email', 'Added By', 'Batch'],
            data: rows.map((e) {
              return [
                e['name'],
                e['contact'],
                e['email'],
                e['staff'],
                e['batch'],
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: pw.TextStyle(font: font),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Students',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // ===== SEARCH =====
          TextField(
            onChanged: (v) => setState(() => search = v.toLowerCase()),
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('hodEmail', isEqualTo: hodEmail)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No students found'));
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    docs.map((d) async {
                      final data = d.data() as Map<String, dynamic>;
                      final staff = await _getStaffName(
                        data['staff_mail'] ?? '',
                      );

                      return {
                        'name': data['name'] ?? '',
                        'contact': data['contact'] ?? '',
                        'email': data['email'] ?? '',
                        'staff': staff,
                        'batch':
                            '${data['from_year'] ?? ''} - ${data['to_year'] ?? ''}',
                      };
                    }),
                  ),
                  builder: (context, rowsSnap) {
                    if (!rowsSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rows = rowsSnap.data!.where((r) {
                      final text =
                          [
                                r['name'],
                                r['contact'],
                                r['email'],
                                r['staff'],
                                r['batch'],
                              ]
                              .map((e) => (e ?? '').toString().toLowerCase())
                              .join(' ');
                      return text.contains(search);
                    }).toList();

                    /// ✅ EMPTY SEARCH RESULT
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text(
                          'No records found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => exportPdf(rows),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export PDF'),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ===== TABLE =====
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.grey.shade100,
                                ),
                                dividerThickness: 1,
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Contact')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Added By')),
                                  DataColumn(label: Text('Batch')),
                                ],
                                rows: rows.map((r) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(r['name'])),
                                      DataCell(Text(r['contact'])),
                                      DataCell(Text(r['email'])),
                                      DataCell(Text(r['staff'])),
                                      DataCell(Text(r['batch'])),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
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
