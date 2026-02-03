import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import 'hod_layout.dart';
import 'list_alumni.dart';

class ManageAlumniPage extends StatefulWidget {
  final String? uid;
  final Map<String, dynamic>? data;

  const ManageAlumniPage({super.key, this.uid, this.data});

  @override
  State<ManageAlumniPage> createState() => _ManageAlumniPageState();
}

class _ManageAlumniPageState extends State<ManageAlumniPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final fromYearCtrl = TextEditingController();
  final toYearCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    if (d != null) {
      nameCtrl.text = (d['name'] ?? '').toString();
      contactCtrl.text = (d['contact'] ?? '').toString();
      emailCtrl.text = (d['email'] ?? '').toString();
      dobCtrl.text = (d['dob'] ?? '').toString();
      fromYearCtrl.text = (d['from_year'] ?? '').toString();
      toYearCtrl.text = (d['to_year'] ?? '').toString();
    }
  }

  Future<void> pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      dobCtrl.text = DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    final alumniCol = FirebaseFirestore.instance.collection('alumni');

    /// ✅ REAL HOD EMAIL (PRIMARY AUTH – NEVER CHANGES)
    final hodEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    /// ADD ALUMNI
    if (widget.uid == null) {
      // 🔐 SECONDARY AUTH INSTANCE
      final secondaryApp = await Firebase.initializeApp(
        name: 'Secondary',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: dobCtrl.text.trim(),
      );

      await alumniCol.doc(cred.user!.uid).set({
        'name': nameCtrl.text.trim(),
        'contact': contactCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'dob': dobCtrl.text.trim(),
        'from_year': fromYearCtrl.text.trim(),
        'to_year': toYearCtrl.text.trim(),
        'hodEmail': hodEmail, // ✅ ALWAYS HOD
        'created_at': Timestamp.now(),
      });

      await secondaryApp.delete(); // 🔥 cleanup
    }
    /// UPDATE
    else {
      await alumniCol.doc(widget.uid).update({
        'name': nameCtrl.text.trim(),
        'contact': contactCtrl.text.trim(),
        'from_year': fromYearCtrl.text.trim(),
        'to_year': toYearCtrl.text.trim(),
        'updated_at': Timestamp.now(),
      });
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ListAlumniPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.uid == null ? 'Add Alumni' : 'Edit Alumni',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(nameCtrl, 'Name'),
                _gap(),
                _field(contactCtrl, 'Contact'),
                _gap(),
                _field(emailCtrl, 'Email', enabled: widget.uid == null),
                _gap(),
                TextFormField(
                  controller: dobCtrl,
                  readOnly: true,
                  onTap: pickDob,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  decoration: _dec('DOB (Password)'),
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(child: _field(fromYearCtrl, 'From Year')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(toYearCtrl, 'To Year')),
                  ],
                ),
                _gap(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      widget.uid == null ? 'Save' : 'Update',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool enabled = true}) {
    return TextFormField(
      controller: c,
      enabled: enabled,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
