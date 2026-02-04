// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'alumni_layout.dart';
import 'alumni_sponsorship_payment_page.dart';

class AlumniSponsorshipListPage extends StatefulWidget {
  const AlumniSponsorshipListPage({super.key});

  @override
  State<AlumniSponsorshipListPage> createState() =>
      _AlumniSponsorshipListPageState();
}

class _AlumniSponsorshipListPageState extends State<AlumniSponsorshipListPage> {
  final String email = FirebaseAuth.instance.currentUser!.email!;
  String department = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartment();
  }

  Future<void> _loadDepartment() async {
    final snap = await FirebaseFirestore.instance
        .collection('alumni')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      department = snap.docs.first['department'];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlumniLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sponsorships')
                  .where('department', isEqualTo: department)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'NO SPONSORSHIPS AVAILABLE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    final doc = snap.data!.docs[i];
                    final data = doc.data() as Map<String, dynamic>;

                    // ✅ FIXED PAYMENT PARSING (LIST, NOT MAP)
                    final rawPayments = data['payments'];

                    final List<Map<String, dynamic>> payments =
                        rawPayments is List
                        ? rawPayments
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList()
                        : [];

                    final myPayment = payments.firstWhere(
                      (p) => p['email'] == email,
                      orElse: () => {},
                    );

                    final bool hasPaid = myPayment.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(30, 0, 0, 0),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _statusBadge(
                                hasPaid
                                    ? myPayment['status'] ?? 'PAID'
                                    : 'NOT PAID',
                              ),
                              const Spacer(),

                              // 👁️ VIEW PAYMENT
                              if (hasPaid)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_red_eye,
                                    color: Color(0xFF2563EB),
                                  ),
                                  onPressed: () =>
                                      _showPaymentModal(context, myPayment),
                                ),

                              // 💳 PAY NOW
                              if (!hasPaid)
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AlumniSponsorshipPaymentPage(
                                                sponsorshipId: doc.id,
                                                title: data['title'],
                                                department: data['department'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Pay Now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _statusBadge(String status) {
    final bool paid = status == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: paid ? const Color(0xFF166534) : const Color(0xFF2563EB),
        ),
      ),
    );
  }

  void _showPaymentModal(BuildContext context, Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _row('Amount', payment['amount']),
                _row('Mode', payment['payment_mode']),
                _row('Status', payment['status']),
                if (payment['account_no'] != null)
                  _row('Account No', payment['account_no']),
                if (payment['branch'] != null)
                  _row('Branch', payment['branch']),
                if (payment['ifsc'] != null) _row('IFSC', payment['ifsc']),
                if (payment['proof_image'] != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Proof',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(payment['proof_image']),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 4, child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }
}
