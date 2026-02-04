// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'alumni_layout.dart';

class AlumniJobInternshipViewPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const AlumniJobInternshipViewPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<AlumniJobInternshipViewPage> createState() =>
      _AlumniJobInternshipViewPageState();
}

class _AlumniJobInternshipViewPageState
    extends State<AlumniJobInternshipViewPage> {
  bool interested = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    checkInterest();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ================= CHECK INTEREST =================
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

  // ================= ADD INTEREST =================
  Future<void> addInterest() async {
    if (interested) return;

    final email = FirebaseAuth.instance.currentUser!.email!;

    final alumni = await FirebaseFirestore.instance
        .collection('alumni')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final name = (alumni.docs.first['name'] ?? '').toString();

    await FirebaseFirestore.instance
        .collection('job_internships')
        .doc(widget.jobId)
        .collection('interested')
        .add({
          'type': 'ALUMNI',
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

    return AlumniLayout(
      child: CupertinoScrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 20),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
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
                  const Icon(
                    Icons.business,
                    size: 18,
                    color: Color(0xFF0D9488),
                  ),
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

              const SizedBox(height: 8),

              Text(
                "Contact: " + contact,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 24),

              // 🔥 SAME ANIMATED BUTTON
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
        ),
      ),
    );
  }
}
