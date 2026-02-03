// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'staff_layout.dart';
import 'staff_notification_list.dart';

class StaffAddEditNotificationPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const StaffAddEditNotificationPage({super.key, this.docId, this.data});

  @override
  State<StaffAddEditNotificationPage> createState() =>
      _StaffAddEditNotificationPageState();
}

class _StaffAddEditNotificationPageState
    extends State<StaffAddEditNotificationPage> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String staff_name = '';
  String department = ''; // ✅ IMPORTANT

  @override
  void initState() {
    super.initState();

    final d = widget.data;
    if (d != null) {
      titleCtrl.text = d['title'] ?? '';
      descCtrl.text = d['description'] ?? '';
    }

    _loadStaffDetails();
  }

  // ================= LOAD STAFF DETAILS =================
  Future<void> _loadStaffDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final staffSnap = await FirebaseFirestore.instance
        .collection('staff')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (staffSnap.docs.isNotEmpty) {
      final data = staffSnap.docs.first.data();
      setState(() {
        staff_name = data['name'] ?? '';
        department = data['department'] ?? ''; // ✅ FIX
      });
    }
  }

  // ================= SAVE =================
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'Createdby': 'Staff',
      'Createdname': staff_name,
      'Createdemail': FirebaseAuth.instance.currentUser?.email,
      'department': department, // ✅ REQUIRED
      'updated_at': Timestamp.now(),
    };

    final col = FirebaseFirestore.instance.collection('notifications');

    if (widget.docId == null) {
      await col.add({...payload, 'created_at': Timestamp.now()});
    } else {
      await col.doc(widget.docId).update(payload);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StaffNotificationListPage()),
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
            widget.docId == null ? 'Add Notification' : 'Update Notification',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(titleCtrl, 'Title'),
                _gap(),
                _field(descCtrl, 'Description', max: 4),
                _gap(),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: save,
                    child: Text(
                      widget.docId == null ? 'Save' : 'Update',
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
  Widget _field(TextEditingController c, String label, {int max = 1}) {
    return TextFormField(
      controller: c,
      maxLines: max,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: _dec(label),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label, // ✅ labelText as you prefer
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _gap() => const SizedBox(height: 14);
}
