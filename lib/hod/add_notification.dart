// ignore_for_file: non_constant_identifier_names

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'hod_layout.dart';
import 'list_notification.dart';

class AddEditNotificationPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AddEditNotificationPage({super.key, this.docId, this.data});

  @override
  State<AddEditNotificationPage> createState() =>
      _AddEditNotificationPageState();
}

class _AddEditNotificationPageState extends State<AddEditNotificationPage> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String hod_name = '';

  @override
  void initState() {
    super.initState();

    final d = widget.data;
    if (d != null) {
      titleCtrl.text = d['title'] ?? '';
      descCtrl.text = d['description'] ?? '';
    }

    _loadHodDetails(); // ✅ IMPORTANT
  }

  Future<void> _loadHodDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hodEmail = user.email;
    if (hodEmail == null) return;

    final hodSnap = await FirebaseFirestore.instance
        .collection('hod')
        .where('email', isEqualTo: hodEmail)
        .limit(1)
        .get();

    if (hodSnap.docs.isNotEmpty) {
      setState(() {
        hod_name = hodSnap.docs.first['name']; // ✅ FIXED
      });
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'Createdby': 'HOD',
      'Createdname': hod_name,
      'Createdemail': FirebaseAuth.instance.currentUser?.email,
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
      MaterialPageRoute(builder: (_) => const NotificationListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
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
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {int max = 1}) {
    return TextFormField(
      controller: c,
      maxLines: max,
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
