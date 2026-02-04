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
import 'package:open_filex/open_filex.dart';

import 'alumni_layout.dart';

class AlumniProfilePage extends StatefulWidget {
  const AlumniProfilePage({super.key});

  @override
  State<AlumniProfilePage> createState() => _AlumniProfilePageState();
}

class _AlumniProfilePageState extends State<AlumniProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  final hodCtrl = TextEditingController();

  String? profileImage;
  String? resumeBase64;
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
    departmentCtrl.dispose();
    hodCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('alumni')
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
      departmentCtrl.text = data['department'] ?? '';
      hodCtrl.text = data['hod'] ?? '';
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
    setState(() => profileImage = base64Encode(bytes));
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

    if (bytes.length > 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume must be under 1 MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => resumeBase64 = base64Encode(bytes));
  }

  // ================= VIEW RESUME (SAME LOGIC AS HOD PAGE) =================
  Future<void> viewResume() async {
    if (resumeBase64 == null) return;

    final bytes = base64Decode(resumeBase64!);

    if (kIsWeb) {
      final uri = Uri.dataFromBytes(bytes, mimeType: 'application/pdf');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/resume.pdf');
    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(file.path);
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate() || docId == null) return;

    await FirebaseFirestore.instance.collection('alumni').doc(docId).update({
      'name': nameCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
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

    return AlumniLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alumni Profile',
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
                    _field(departmentCtrl, 'Department', enabled: false),
                    _field(hodCtrl, 'HOD', enabled: false),

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
        validator: enabled
            ? (v) => v == null || v.isEmpty ? 'Required' : null
            : null,
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
