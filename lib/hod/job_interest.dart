// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import 'hod_layout.dart';

class InterestedUsersPage extends StatefulWidget {
  final String jobId;

  const InterestedUsersPage({super.key, required this.jobId});

  @override
  State<InterestedUsersPage> createState() => _InterestedUsersPageState();
}

class _InterestedUsersPageState extends State<InterestedUsersPage> {
  String search = '';
  bool loading = true;

  static const int pageSize = 10;
  DocumentSnapshot? lastDoc;
  bool hasMore = true;

  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData({bool loadMore = false}) async {
    if (!hasMore && loadMore) return;

    Query query = FirebaseFirestore.instance
        .collection('job_internships')
        .doc(widget.jobId)
        .collection('interested')
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    if (loadMore && lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    }

    final snap = await query.get();

    if (snap.docs.isEmpty) {
      setState(() {
        hasMore = false;
        loading = false;
      });
      return;
    }

    lastDoc = snap.docs.last;

    final List<Map<String, dynamic>> temp = [];

    for (final d in snap.docs) {
      final interest = d.data() as Map<String, dynamic>;
      final email = interest['email'];

      final studentSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (studentSnap.docs.isNotEmpty) {
        final student = studentSnap.docs.first.data();

        temp.add({
          'type': interest['type'] ?? '',
          'name': student['name'] ?? '',
          'email': email ?? '',
          'contact': student['contact'] ?? '',
          'resume': student['resume'],
        });
      }
    }

    setState(() {
      rows.addAll(temp);
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filteredRows {
    if (search.isEmpty) return rows;
    final q = search.toLowerCase();

    return rows.where((r) {
      return r['name'].toLowerCase().contains(q) ||
          r['email'].toLowerCase().contains(q) ||
          r['type'].toLowerCase().contains(q);
    }).toList();
  }

  // ✅ FINAL UNIVERSAL PDF VIEW (WEB + ANDROID)
  Future<void> viewResume(String base64Pdf) async {
    final bytes = base64Decode(base64Pdf);

    // 🌐 WEB → FORCE DOWNLOAD (ONLY RELIABLE OPTION)
    if (kIsWeb) {
      final uri = Uri.dataFromBytes(bytes, mimeType: 'application/pdf');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // 📱 ANDROID → OPEN IN SYSTEM PDF VIEWER
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/resume.pdf');
    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔙 BACK + TITLE
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 6),
              const Text(
                'Interested Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 🔍 SEARCH
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name / email',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (v) => setState(() => search = v.toLowerCase()),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredRows.isEmpty
                ? const Center(child: Text('No records found'))
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF1F5F9),
                        ),
                        columns: const [
                          DataColumn(label: Text('TYPE')),
                          DataColumn(label: Text('NAME')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('CONTACT')),
                          DataColumn(label: Text('RESUME')),
                        ],
                        rows: filteredRows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(r['type'].toUpperCase())),
                              DataCell(Text(r['name'].toUpperCase())),
                              DataCell(Text(r['email'])),
                              DataCell(Text(r['contact'])),
                              DataCell(
                                r['resume'] != null &&
                                        r['resume'].toString().isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            viewResume(r['resume']),
                                      )
                                    : const Text('-'),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),

          if (hasMore && !loading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: ElevatedButton(
                  onPressed: () => loadData(loadMore: true),
                  child: const Text('Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
