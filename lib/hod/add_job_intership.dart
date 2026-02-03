// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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

  String? imageBase64; // ✅ image stored here

  final picker = ImagePicker();
  final email = FirebaseAuth.instance.currentUser!.email!;

  @override
  void initState() {
    super.initState();

    final d = widget.data;
    if (d != null) {
      type = d['type'] ?? 'job';
      status = d['status'] ?? 'ongoing';

      titleCtrl.text = d['title'] ?? '';
      companyCtrl.text = d['company'] ?? '';
      roleCtrl.text = d['role'] ?? '';
      descCtrl.text = d['description'] ?? '';
      contactCtrl.text = d['contact'] ?? '';

      imageBase64 = d['image_base64']; // ✅ load image on edit
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
                    _gap(),

                    /// 🔥 IMAGE FIELD
                    _imagePicker(),

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

  /// ✅ WEB + MOBILE SAFE IMAGE PICK
  Future<void> pickImage() async {
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (img == null) return;

    final bytes = await img.readAsBytes(); // ✅ no dart:io
    setState(() {
      imageBase64 = base64Encode(bytes);
    });
  }

  Widget _imagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageBase64 != null)
          Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: MemoryImage(base64Decode(imageBase64!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: pickImage,
            child: const Text('Select / Change Image'),
          ),
        ),
      ],
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
      'image_base64': imageBase64, // ✅ saved here
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
