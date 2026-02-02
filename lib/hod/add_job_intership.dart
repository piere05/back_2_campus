// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hod_layout.dart';

class AddEditJobInternshipPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AddEditJobInternshipPage({super.key, this.docId, this.data});

  @override
  State<AddEditJobInternshipPage> createState() =>
      _AddEditJobInternshipPageState();
}

class _AddEditJobInternshipPageState extends State<AddEditJobInternshipPage> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  String type = 'job';
  String status = 'ongoing';

  final email = FirebaseAuth.instance.currentUser!.email!;

  @override
  void initState() {
    super.initState();

    /// ✅ SAFE INIT (NO CRASH EVEN IF DATA IS NULL)
    final d = widget.data;
    if (d != null) {
      type = d['type']?.toString() ?? 'job';
      status = d['status']?.toString() ?? 'ongoing';

      titleCtrl.text = d['title']?.toString() ?? '';
      companyCtrl.text = d['company']?.toString() ?? '';
      roleCtrl.text = d['role']?.toString() ?? '';
      descCtrl.text = d['description']?.toString() ?? '';
      contactCtrl.text = d['contact']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.docId == null
                ? 'Add Job / Internship'
                : 'Update Job / Internship',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _dropdown(
                      value: type,
                      hint: 'Type',
                      items: const [
                        DropdownMenuItem(value: 'job', child: Text('Job')),
                        DropdownMenuItem(
                          value: 'internship',
                          child: Text('Internship'),
                        ),
                      ],
                      onChanged: (v) => setState(() => type = v!),
                    ),
                    _gap(),
                    _field(titleCtrl, 'Title'),
                    _gap(),
                    _field(companyCtrl, 'Company Name'),
                    _gap(),
                    _field(roleCtrl, 'Role'),
                    _gap(),
                    _dropdown(
                      value: status,
                      hint: 'Status',
                      items: const [
                        DropdownMenuItem(
                          value: 'ongoing',
                          child: Text('Ongoing'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (v) => setState(() => status = v!),
                    ),
                    _gap(),
                    _field(descCtrl, 'Description', max: 4),
                    _gap(),
                    _field(contactCtrl, 'Contact'),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: save,
                        child: Text(
                          widget.docId == null ? 'Save' : 'Update',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'type': type,
      'status': status,
      'title': titleCtrl.text.trim(),
      'company': companyCtrl.text.trim(),
      'role': roleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
      'created_by': 'hod',
      'created_email': email,
      'updated_at': Timestamp.now(),
    };

    final col = FirebaseFirestore.instance.collection('job_internships');

    if (widget.docId == null) {
      await col.add({...payload, 'created_at': Timestamp.now()});
    } else {
      await col.doc(widget.docId).update(payload);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String hint, {int max = 1}) {
    return TextFormField(
      controller: c,
      maxLines: max,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: _dec(hint),
    );
  }

  Widget _dropdown({
    required String value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: _dec(hint),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _gap() => const SizedBox(height: 14);
}
