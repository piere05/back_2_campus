// ignore_for_file: deprecated_member_use, unnecessary_cast

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'staff_layout.dart';

class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({super.key});

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final qualificationCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  final hodNameCtrl = TextEditingController();

  String? profileImage; // base64 image
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
    hodNameCtrl.dispose();
    super.dispose();
  }

  // ================= SAFE BASE64 DECODE =================
  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      final cleaned = base64String
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      return base64Decode(cleaned);
    } catch (e) {
      debugPrint('Image decode error: $e');
      return null;
    }
  }

  // ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    final staffSnap = await FirebaseFirestore.instance
        .collection('staff')
        .where('email', isEqualTo: loggedInEmail)
        .limit(1)
        .get();

    if (!mounted) return;

    if (staffSnap.docs.isNotEmpty) {
      final d = staffSnap.docs.first;
      final data = d.data() as Map<String, dynamic>;
      docId = d.id;

      nameCtrl.text = data['name'] ?? '';
      emailCtrl.text = data['email'] ?? '';
      contactCtrl.text = data['contact'] ?? '';
      designationCtrl.text = data['designation'] ?? '';
      qualificationCtrl.text = data['qualification'] ?? '';
      departmentCtrl.text = data['department'] ?? '';
      profileImage = data['profileImage'];

      // ===== FETCH HOD NAME =====
      final hodEmail = data['hodEmail'];
      if (hodEmail != null) {
        final hodSnap = await FirebaseFirestore.instance
            .collection('hod')
            .where('email', isEqualTo: hodEmail)
            .limit(1)
            .get();

        if (hodSnap.docs.isNotEmpty) {
          hodNameCtrl.text =
              (hodSnap.docs.first.data() as Map<String, dynamic>)['name'] ?? '';
        }
      }
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null || !mounted) return;

    final bytes = await img.readAsBytes();
    if (!mounted) return;

    setState(() {
      profileImage = base64Encode(bytes).replaceAll('\n', '');
    });
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate() || docId == null) return;

    await FirebaseFirestore.instance.collection('staff').doc(docId).update({
      'name': nameCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
      'designation': designationCtrl.text.trim(),
      'qualification': qualificationCtrl.text.trim(),
      'profileImage': profileImage,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile Updated')));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeBase64Image(profileImage);

    return StaffLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ===== PROFILE IMAGE =====
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: imageBytes != null
                                      ? MemoryImage(imageBytes)
                                      : null,
                                  child: imageBytes == null
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
                          _field(contactCtrl, 'Contact Number'),
                          _field(qualificationCtrl, 'Qualification'),
                          _field(designationCtrl, 'Designation'),
                          _field(departmentCtrl, 'Department', enabled: false),
                          _field(hodNameCtrl, 'HOD Name', enabled: false),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: updateProfile,
                              child: const Text(
                                'Update Profile',
                                style: TextStyle(color: Colors.white),
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

  // ================= FIELD =================
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
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
