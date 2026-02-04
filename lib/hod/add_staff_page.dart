// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'hod_layout.dart';
import 'list_staff_page.dart';

class AddStaffPage extends StatefulWidget {
  final DocumentSnapshot? staffDoc;

  const AddStaffPage({super.key, this.staffDoc});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final qualificationCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();

  Uint8List? imageBytes;
  String? profileImageBase64;

  String hodEmail = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadHodDetails();

    if (widget.staffDoc != null) {
      final d = widget.staffDoc!.data() as Map<String, dynamic>;
      nameCtrl.text = d['name'];
      emailCtrl.text = d['email'];
      dobCtrl.text = d['dob'];
      qualificationCtrl.text = d['qualification'];
      designationCtrl.text = d['designation'];
      contactCtrl.text = d['contact'];
      departmentCtrl.text = d['department'];
      hodEmail = d['hodEmail'];
      profileImageBase64 = d['profileImage'];
    }
  }

  // 🔐 Load department from logged-in HOD
  Future<void> _loadHodDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    hodEmail = user.email ?? '';

    final hodSnap = await FirebaseFirestore.instance
        .collection('hod')
        .where('email', isEqualTo: hodEmail)
        .limit(1)
        .get();

    if (hodSnap.docs.isNotEmpty) {
      final dept = hodSnap.docs.first['department'];
      setState(() {
        departmentCtrl.text = dept;
      });
    }
  }

  // 🖼 Image Picker (Web + Android)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        profileImageBase64 = base64Encode(bytes);
      });
    }
  }

  // 🔐 Create staff auth without logging out HOD
  Future<void> _createStaffAuth(String email, String password) async {
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'Secondary',
      options: Firebase.app().options,
    );

    final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(
      app: secondaryApp,
    );

    await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await secondaryAuth.signOut();
    await secondaryApp.delete();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final staffEmail = emailCtrl.text.trim();
    final staffPassword = dobCtrl.text.trim();

    try {
      if (widget.staffDoc == null) {
        // 🔐 Create Auth only for NEW staff
        await _createStaffAuth(staffEmail, staffPassword);
      }

      final staffData = {
        'name': nameCtrl.text.trim(),
        'email': staffEmail,
        'dob': staffPassword,
        'qualification': qualificationCtrl.text.trim(),
        'designation': designationCtrl.text.trim(),
        'contact': contactCtrl.text.trim(),
        'department': departmentCtrl.text.trim(),
        'hodEmail': hodEmail,
        'profileImage': profileImageBase64,
        'createdAt': Timestamp.now(),
      };

      if (widget.staffDoc == null) {
        await FirebaseFirestore.instance.collection('staff').add(staffData);
      } else {
        await FirebaseFirestore.instance
            .collection('staff')
            .doc(widget.staffDoc!.id)
            .update(staffData);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ListStaffPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staffDoc != null;

    return HodLayout(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Update Staff' : 'Add Staff',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 🖼 Profile Image
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImageBase64 != null
                          ? MemoryImage(base64Decode(profileImageBase64!))
                          : null,
                      child: profileImageBase64 == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),

                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Photo'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _input(nameCtrl, 'Name'),
              _input(emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
              _input(dobCtrl, 'DOB (DD/MM/YYYY)'),
              _input(qualificationCtrl, 'Qualification'),
              _input(designationCtrl, 'Designation'),
              _input(contactCtrl, 'Contact No', keyboard: TextInputType.phone),

              _readonlyDepartment(),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator()
                      : Text(isEdit ? 'Update Staff' : 'Add Staff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Styled Inputs
  Widget _input(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _readonlyDepartment() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: departmentCtrl,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Department',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
