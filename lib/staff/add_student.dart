// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import 'staff_layout.dart';
import 'list_student.dart';

class StaffAddEditStudentPage extends StatefulWidget {
  final String? uid;
  final Map<String, dynamic>? data;

  const StaffAddEditStudentPage({super.key, this.uid, this.data});

  @override
  State<StaffAddEditStudentPage> createState() =>
      _StaffAddEditStudentPageState();
}

class _StaffAddEditStudentPageState extends State<StaffAddEditStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final fromYearCtrl = TextEditingController();
  final toYearCtrl = TextEditingController();

  final departmentCtrl = TextEditingController();
  final hodNameCtrl = TextEditingController();

  String hodEmail = '';

  @override
  void initState() {
    super.initState();

    final d = widget.data;
    if (d != null) {
      nameCtrl.text = d['name'] ?? '';
      contactCtrl.text = d['contact'] ?? '';
      emailCtrl.text = d['email'] ?? '';
      dobCtrl.text = d['dob'] ?? '';
      fromYearCtrl.text = d['from_year'] ?? '';
      toYearCtrl.text = d['to_year'] ?? '';
      departmentCtrl.text = d['department'] ?? '';
      hodNameCtrl.text = d['hod_name'] ?? '';
      hodEmail = d['hodEmail'] ?? '';
    }

    _loadStaffAndHod();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    contactCtrl.dispose();
    emailCtrl.dispose();
    dobCtrl.dispose();
    fromYearCtrl.dispose();
    toYearCtrl.dispose();
    departmentCtrl.dispose();
    hodNameCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD STAFF → HOD =================
  Future<void> _loadStaffAndHod() async {
    final staffUser = FirebaseAuth.instance.currentUser;
    if (staffUser == null || staffUser.email == null) return;

    final staffSnap = await FirebaseFirestore.instance
        .collection('staff')
        .where('email', isEqualTo: staffUser.email)
        .limit(1)
        .get();

    if (staffSnap.docs.isEmpty) return;

    final staffData = staffSnap.docs.first.data();

    departmentCtrl.text = staffData['department'] ?? '';
    hodEmail = staffData['hodEmail'] ?? '';

    final hodSnap = await FirebaseFirestore.instance
        .collection('hod')
        .where('email', isEqualTo: hodEmail)
        .limit(1)
        .get();

    if (hodSnap.docs.isNotEmpty) {
      hodNameCtrl.text = hodSnap.docs.first['name'] ?? '';
    }

    if (mounted) setState(() {});
  }

  // ================= DOB PICKER =================
  Future<void> pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      dobCtrl.text = DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // ================= SAVE =================
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    final studentsCol = FirebaseFirestore.instance.collection('students');
    final staffUser = FirebaseAuth.instance.currentUser;

    if (widget.uid == null) {
      final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryStudent',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: dobCtrl.text.trim(),
      );

      await studentsCol.doc(cred.user!.uid).set({
        'name': nameCtrl.text.trim(),
        'contact': contactCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'dob': dobCtrl.text.trim(),
        'from_year': fromYearCtrl.text.trim(),
        'to_year': toYearCtrl.text.trim(),
        'department': departmentCtrl.text,
        'hod_name': hodNameCtrl.text,
        'staff_mail': staffUser?.email,
        'hodEmail': hodEmail,
        'created_at': Timestamp.now(),
      });

      await secondaryApp.delete();
    } else {
      await studentsCol.doc(widget.uid).update({
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
      MaterialPageRoute(builder: (_) => const StaffListStudentsPage()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return StaffLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.uid == null ? 'Add Student' : 'Edit Student',
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

                _readonlyCtrl('Department', departmentCtrl),
                _gap(),
                _readonlyCtrl('HOD Name', hodNameCtrl),

                _gap(),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      widget.uid == null ? 'Save' : 'Update',
                      style: const TextStyle(color: Colors.white),
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

  // ================= HELPERS =================
  Widget _field(TextEditingController c, String label, {bool enabled = true}) {
    return TextFormField(
      controller: c,
      enabled: enabled,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: _dec(label),
    );
  }

  Widget _readonlyCtrl(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      enabled: false,
      decoration: _dec(label),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _gap() => const SizedBox(height: 14);
}
