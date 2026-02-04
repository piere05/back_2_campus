// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'hod_layout.dart';

class ViewSponsorshipPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ViewSponsorshipPage({super.key, required this.data});

  @override
  State<ViewSponsorshipPage> createState() => _ViewSponsorshipPageState();
}

class _ViewSponsorshipPageState extends State<ViewSponsorshipPage> {
  String search = '';

  final Map<String, String> nameCache = {};

  List<Map<String, dynamic>> get payments {
    final raw = widget.data['payments'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get filteredPayments {
    if (search.isEmpty) return payments;
    return payments.where((p) {
      return (p['email'] ?? '').toString().toLowerCase().contains(
        search.toLowerCase(),
      );
    }).toList();
  }

  Future<String> _getNameByEmail(String email) async {
    if (nameCache.containsKey(email)) {
      return nameCache[email]!;
    }

    final snap = await FirebaseFirestore.instance
        .collection('alumni')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final name = snap.docs.isNotEmpty ? snap.docs.first['name'] ?? '-' : '-';
    nameCache[email] = name;
    return name;
  }

  Future<void> exportPdf() async {
    final pdf = pw.Document();
    final rows = <List<String>>[];

    for (final p in filteredPayments) {
      final email = p['email'] ?? '-';
      final name = await _getNameByEmail(email);

      rows.add([
        name,
        email,
        p['amount'] ?? '-',
        p['payment_mode'] ?? '-',
        p['account_no'] ?? '-',
        p['ifsc'] ?? '-',
        p['branch'] ?? '-',
      ]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              widget.data['title'] ?? '',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const [
                'Name',
                'Email',
                'Amount',
                'Mode',
                'Account No',
                'IFSC',
                'Branch',
              ],
              data: rows,
              border: pw.TableBorder.all(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sponsorship Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            widget.data['title'] ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          /// SEARCH
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => search = v),
          ),

          const SizedBox(height: 20),

          /// TABLE / EMPTY STATE
          Expanded(
            child: filteredPayments.isEmpty
                ? const Center(
                    child: Text(
                      'No result found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Mode')),
                        DataColumn(label: Text('Account No')),
                        DataColumn(label: Text('IFSC')),
                        DataColumn(label: Text('Branch')),
                        DataColumn(label: Text('Receipt')),
                      ],
                      rows: filteredPayments.map((p) {
                        final email = p['email'] ?? '-';

                        return DataRow(
                          cells: [
                            DataCell(
                              FutureBuilder<String>(
                                future: _getNameByEmail(email),
                                builder: (c, s) {
                                  if (!s.hasData) return const Text('...');
                                  return Text(s.data!);
                                },
                              ),
                            ),
                            DataCell(Text(email)),
                            DataCell(Text(p['amount'] ?? '-')),
                            DataCell(Text(p['payment_mode'] ?? '-')),
                            DataCell(Text(p['account_no'] ?? '-')),
                            DataCell(Text(p['ifsc'] ?? '-')),
                            DataCell(Text(p['branch'] ?? '-')),
                            DataCell(
                              p['proof_image'] != null
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_red_eye),
                                      onPressed: () =>
                                          _showReceipt(p['proof_image']),
                                    )
                                  : const Text('-'),
                            ),
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

  void _showReceipt(String base64) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.memory(base64Decode(base64), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
