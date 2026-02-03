// ignore_for_file: deprecated_member_use, unnecessary_cast, use_build_context_synchronously, unnecessary_import

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'student_layout.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final fromYearCtrl = TextEditingController();
  final toYearCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();

  String? profileImage; // base64
  String? resumeBase64; // base64 pdf
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
    fromYearCtrl.dispose();
    toYearCtrl.dispose();
    departmentCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: loggedInEmail)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      final d = snap.docs.first;
      final data = d.data();
      docId = d.id;

      nameCtrl.text = data['name'] ?? '';
      emailCtrl.text = data['email'] ?? '';
      contactCtrl.text = data['contact'] ?? '';
      fromYearCtrl.text = data['fromYear'] ?? '';
      toYearCtrl.text = data['toYear'] ?? '';
      departmentCtrl.text = data['department'] ?? '';
      profileImage = data['profileImage'];
      resumeBase64 = data['resume'];
    }

    setState(() => loading = false);
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null || !mounted) return;

    final bytes = await img.readAsBytes();
    setState(() {
      profileImage = base64Encode(bytes);
    });
  }

  // ================= PICK RESUME =================
  Future<void> pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;

    // 🔴 Firestore HARD LIMIT (1MB)
    if (bytes.length > 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume must be under 1 MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      resumeBase64 = base64Encode(bytes);
    });
  }

  // ================= VIEW RESUME (WEB + ANDROID SAFE) =================
  Future<void> viewResume() async {
    if (resumeBase64 == null) return;

    final bytes = base64Decode(resumeBase64!);

    if (kIsWeb) {
      final uri = Uri.parse('data:application/pdf;base64,$resumeBase64');
      await launchUrl(uri);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/resume.pdf');
    await file.writeAsBytes(bytes, flush: true);

    final uri = Uri.file(file.path);
    await launchUrl(uri);
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate() || docId == null) return;

    await FirebaseFirestore.instance.collection('students').doc(docId).update({
      'name': nameCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
      'fromYear': fromYearCtrl.text.trim(),
      'toYear': toYearCtrl.text.trim(),
      'profileImage': profileImage,
      'resume': resumeBase64,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile Updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (profileImage != null) {
      imageBytes = base64Decode(profileImage!);
    }

    return StudentLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Change Photo'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _field(nameCtrl, 'Name'),
                    _field(emailCtrl, 'Email', enabled: false),
                    _field(contactCtrl, 'Contact Number'),
                    _field(fromYearCtrl, 'From Year'),
                    _field(toYearCtrl, 'To Year'),
                    _field(departmentCtrl, 'Department', enabled: false),

                    const SizedBox(height: 10),

                    // ===== RESUME =====
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(
                        resumeBase64 == null
                            ? 'Upload Resume (PDF)'
                            : 'Resume Uploaded',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (resumeBase64 != null)
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              onPressed: viewResume,
                            ),
                          TextButton(
                            onPressed: pickResume,
                            child: const Text('Upload'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
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
