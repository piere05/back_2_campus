// ignore_for_file: deprecated_member_use, unnecessary_cast

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hod_layout.dart';

class HodProfilePage extends StatefulWidget {
  const HodProfilePage({super.key});

  @override
  State<HodProfilePage> createState() => _HodProfilePageState();
}

class _HodProfilePageState extends State<HodProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final qualificationCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();

  String? profileBase64;
  String? docId;
  bool loading = true;

  final loggedInEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    contactCtrl.dispose();
    designationCtrl.dispose();
    qualificationCtrl.dispose();
    departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('hod')
        .where('email', isEqualTo: loggedInEmail)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      final d = snap.docs.first;
      final data = d.data() as Map<String, dynamic>;
      docId = d.id;

      nameCtrl.text = data['name'] ?? '';
      emailCtrl.text = data['email'] ?? '';
      contactCtrl.text = data['contact'] ?? '';
      designationCtrl.text = data['designation'] ?? '';
      qualificationCtrl.text = data['qualification'] ?? '';
      departmentCtrl.text = data['department'] ?? '';
      profileBase64 = data['profileImageBase64'];
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null || !mounted) return;

    final bytes = await img.readAsBytes();
    if (!mounted) return;

    setState(() {
      profileBase64 = base64Encode(bytes);
    });
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate() || docId == null) return;

    await FirebaseFirestore.instance.collection('hod').doc(docId).update({
      'name': nameCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
      'designation': designationCtrl.text.trim(),
      'qualification': qualificationCtrl.text.trim(),
      'profileImageBase64': profileBase64,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile Updated')));
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOD Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundImage: profileBase64 == null
                                      ? null
                                      : MemoryImage(
                                          base64Decode(profileBase64!),
                                        ),
                                  child: profileBase64 == null
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                TextButton.icon(
                                  onPressed: pickImage,
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('Change Photo'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          _field(nameCtrl, 'Name'),
                          _field(emailCtrl, 'Email', enabled: false),
                          _field(contactCtrl, 'Contact No'),
                          _field(qualificationCtrl, 'Qualification'),
                          _field(designationCtrl, 'Designation'),
                          _field(departmentCtrl, 'Department', enabled: false),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: updateProfile,
                              child: const Text(
                                'Update Profile',
                                style: TextStyle(color: Colors.black),
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

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
