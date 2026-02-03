// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_layout.dart';

class StudentJobInternshipViewPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const StudentJobInternshipViewPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<StudentJobInternshipViewPage> createState() =>
      _StudentJobInternshipViewPageState();
}

class _StudentJobInternshipViewPageState
    extends State<StudentJobInternshipViewPage> {
  bool interested = false;

  @override
  void initState() {
    super.initState();
    checkInterest();
  }

  Future<void> checkInterest() async {
    final email = FirebaseAuth.instance.currentUser!.email!;
    final snap = await FirebaseFirestore.instance
        .collection('job_internships')
        .doc(widget.jobId)
        .collection('interested')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      setState(() => interested = true);
    }
  }

  Future<void> addInterest() async {
    if (interested) return;

    final email = FirebaseAuth.instance.currentUser!.email!;
    final student = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final name = (student.docs.first['name'] ?? '').toString();

    await FirebaseFirestore.instance
        .collection('job_internships')
        .doc(widget.jobId)
        .collection('interested')
        .add({
          'type': 'STUDENT',
          'email': email,
          'name': name,
          'timestamp': FieldValue.serverTimestamp(),
        });

    setState(() => interested = true);
  }

  @override
  Widget build(BuildContext context) {
    final String role = (widget.jobData['role'] ?? '').toString().toUpperCase();
    final String title = (widget.jobData['title'] ?? '')
        .toString()
        .toUpperCase();
    final String company = (widget.jobData['company'] ?? '')
        .toString()
        .toUpperCase();
    final String description = (widget.jobData['description'] ?? '').toString();
    final String contact = (widget.jobData['contact'] ?? '').toString();
    final String? img = widget.jobData['image_base64'];

    return StudentLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (img != null && img.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                base64Decode(img),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            role,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.badge, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(title),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.business, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 6),
              Text(company),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'DESCRIPTION',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(description),
          Text(""),
          Text(
            "Contact: " + contact,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),

          // 🔥 SAFE ANIMATED BUTTON
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            decoration: BoxDecoration(
              color: interested
                  ? const Color(0xFF0D9488).withOpacity(0.6)
                  : const Color(0xFF0D9488),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: interested ? null : addInterest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          interested
                              ? Icons.check_circle
                              : Icons.favorite_border,
                          key: ValueKey(interested),
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          interested ? 'ADDED TO INTEREST' : 'ADD INTEREST',
                          key: ValueKey(interested),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
