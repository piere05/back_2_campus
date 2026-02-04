// ignore_for_file: unnecessary_import, deprecated_member_use

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'staff_layout.dart';

class StaffViewAlumniTablePage extends StatefulWidget {
  const StaffViewAlumniTablePage({super.key});

  @override
  State<StaffViewAlumniTablePage> createState() =>
      _StaffViewAlumniTablePageState();
}

class _StaffViewAlumniTablePageState extends State<StaffViewAlumniTablePage> {
  bool loading = true;
  String hodEmail = '';

  final String staffEmail = FirebaseAuth.instance.currentUser!.email!.trim();

  final TextEditingController searchCtrl = TextEditingController();

  final ScrollController _xScroll = ScrollController();
  final ScrollController _yScroll = ScrollController();

  List<Map<String, dynamic>> alumniList = [];
  List<Map<String, dynamic>> filteredList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _xScroll.dispose();
    _yScroll.dispose();
    super.dispose();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    try {
      final staffSnap = await FirebaseFirestore.instance
          .collection('staff')
          .where('email', isEqualTo: staffEmail)
          .limit(1)
          .get();

      if (staffSnap.docs.isEmpty) {
        setState(() => loading = false);
        return;
      }

      hodEmail = (staffSnap.docs.first.data()['hodEmail'] ?? '')
          .toString()
          .trim();

      final alumniSnap = await FirebaseFirestore.instance
          .collection('alumni')
          .where('hodEmail', isEqualTo: hodEmail)
          .get();

      alumniList = alumniSnap.docs
          .map((e) => Map<String, dynamic>.from(e.data()))
          .toList();

      filteredList = List.from(alumniList);
    } catch (e) {
      debugPrint('ERROR: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  // ================= SEARCH =================
  void _search(String value) {
    final q = value.toLowerCase();

    setState(() {
      filteredList = alumniList.where((a) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        final email = (a['email'] ?? '').toString().toLowerCase();
        final contact = (a['contact'] ?? '').toString().toLowerCase();
        final batch = '${a['from_year'] ?? ''} - ${a['to_year'] ?? ''}'
            .toLowerCase();

        return name.contains(q) ||
            email.contains(q) ||
            contact.contains(q) ||
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
        build: (context) => [
          pw.Text(
            'Alumni List',
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
            data: filteredList.map((a) {
              return [
                a['name']?.toString() ?? '',
                a['contact']?.toString() ?? '',
                a['email']?.toString() ?? '',
                '${a['from_year'] ?? ''} - ${a['to_year'] ?? ''}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: 'alumni_list.pdf');
    }
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Alumni',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: filteredList.isEmpty ? null : _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
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
                ),
                const SizedBox(height: 12),
                filteredList.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No alumni found'),
                        ),
                      )
                    : Expanded(child: _table()),
              ],
            ),
    );
  }

  // ================= TABLE WITH X SCROLL =================
  Widget _table() {
    return Scrollbar(
      controller: _xScroll,
      thumbVisibility: true,
      notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _xScroll,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 900, // 👈 forces horizontal scroll on small screens
          child: Scrollbar(
            controller: _yScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _yScroll,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade200,
                ),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Contact')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Batch')),
                ],
                rows: filteredList.map((a) {
                  return DataRow(
                    cells: [
                      DataCell(Text(a['name']?.toString() ?? '')),
                      DataCell(Text(a['contact']?.toString() ?? '')),
                      DataCell(Text(a['email']?.toString() ?? '')),
                      DataCell(
                        Text('${a['from_year'] ?? ''} - ${a['to_year'] ?? ''}'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
