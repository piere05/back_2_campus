import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hod_layout.dart';
import 'list_sponsorship.dart';

class AddEditSponsorshipPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AddEditSponsorshipPage({super.key, this.docId, this.data});

  @override
  State<AddEditSponsorshipPage> createState() => _AddEditSponsorshipPageState();
}

class _AddEditSponsorshipPageState extends State<AddEditSponsorshipPage> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String? hodEmail;
  String? department;

  @override
  void initState() {
    super.initState();

    final d = widget.data;
    if (d != null) {
      titleCtrl.text = d['title'] ?? '';
      descCtrl.text = d['description'] ?? '';
    }

    _loadHodData();
  }

  Future<void> _loadHodData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('hod')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;
    hodEmail = snap.docs.first['email'];
    department = snap.docs.first['department'];
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    final col = FirebaseFirestore.instance.collection('sponsorships');

    final payload = {
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'department': department,
      'hodEmail': hodEmail,
      'updated_at': Timestamp.now(),
    };

    if (widget.docId == null) {
      await col.add({...payload, 'created_at': Timestamp.now()});
    } else {
      await col.doc(widget.docId).update(payload);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ListSponsorshipPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.docId == null ? 'Add Sponsorship' : 'Update Sponsorship',
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
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
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
