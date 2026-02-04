// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class AlumniSponsorshipPaymentPage extends StatefulWidget {
  final String sponsorshipId;
  final String title;
  final String department;

  const AlumniSponsorshipPaymentPage({
    super.key,
    required this.sponsorshipId,
    required this.title,
    required this.department,
  });

  @override
  State<AlumniSponsorshipPaymentPage> createState() =>
      _AlumniSponsorshipPaymentPageState();
}

class _AlumniSponsorshipPaymentPageState
    extends State<AlumniSponsorshipPaymentPage> {
  final amountCtrl = TextEditingController();
  final accountCtrl = TextEditingController();
  final branchCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();

  final picker = ImagePicker();
  Razorpay? _razorpay;

  String mode = 'ONLINE';
  String? proofBase64;
  bool loading = false;
  String? description;

  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadDescription();

    // Razorpay only for mobile
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    amountCtrl.dispose();
    accountCtrl.dispose();
    branchCtrl.dispose();
    ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDescription() async {
    final snap = await FirebaseFirestore.instance
        .collection('sponsorships')
        .doc(widget.sponsorshipId)
        .get();

    if (snap.exists) {
      setState(() => description = snap.data()?['description']);
    }
  }

  Future<void> pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => proofBase64 = base64Encode(bytes));
  }

  Future<bool> alreadyPaid() async {
    final doc = await FirebaseFirestore.instance
        .collection('sponsorships')
        .doc(widget.sponsorshipId)
        .get();

    final payments = doc.data()?['payments'] as List<dynamic>? ?? [];
    return payments.any((p) => p['email'] == user.email);
  }

  // ================= ONLINE PAYMENT =================
  void openRazorpay() {
    if (kIsWeb) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Online payment is not supported on Web. Please use Account Transfer.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final options = {
      'key': 'rzp_test_S6S0e6VGPJ5FMo',
      'amount': int.parse(amountCtrl.text.trim()) * 100,
      'name': 'Back To Campus',
      'description': widget.title,
      'prefill': {'email': user.email},
    };

    _razorpay!.open(options);
  }

  Future<void> _onSuccess(PaymentSuccessResponse res) async {
    await savePayment('ONLINE', paymentId: res.paymentId);
    setState(() => loading = false);
    Navigator.pop(context);
  }

  void _onError(PaymentFailureResponse res) {
    setState(() => loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment Failed')));
  }

  // ================= SAVE PAYMENT =================
  Future<void> savePayment(String mode, {String? paymentId}) async {
    await FirebaseFirestore.instance
        .collection('sponsorships')
        .doc(widget.sponsorshipId)
        .update({
          'payments': FieldValue.arrayUnion([
            {
              'email': user.email,
              'department': widget.department,
              'amount': amountCtrl.text.trim(),
              'payment_mode': mode,
              'status': 'PAID',
              'razorpay_id': paymentId,
              'account_no': accountCtrl.text.trim().isEmpty
                  ? null
                  : accountCtrl.text.trim(),
              'branch': branchCtrl.text.trim().isEmpty
                  ? null
                  : branchCtrl.text.trim(),
              'ifsc': ifscCtrl.text.trim().isEmpty
                  ? null
                  : ifscCtrl.text.trim(),
              'proof_image': proofBase64,
              'paid_at': Timestamp.now(),
            },
          ]),
        });
  }

  // ================= SUBMIT =================
  Future<void> submit() async {
    if (amountCtrl.text.trim().isEmpty) return;

    if (await alreadyPaid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already paid for this sponsorship'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mode == 'ACCOUNT_TRANSFER' && proofBase64 == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload payment proof')));
      return;
    }

    setState(() => loading = true);

    if (mode == 'ONLINE') {
      openRazorpay();
    } else {
      await savePayment('ACCOUNT_TRANSFER');
      setState(() => loading = false);
      Navigator.pop(context);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 248, 255),
      appBar: AppBar(
        title: const Text('Sponsorship Payment'),
        backgroundColor: const Color.fromARGB(255, 0, 163, 101),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(description!, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              Column(
                children: [
                  _field(amountCtrl, 'Amount'),
                  const SizedBox(height: 14),
                  DropdownButtonFormField(
                    value: mode,
                    decoration: _dec('Payment Mode'),
                    items: const [
                      DropdownMenuItem(
                        value: 'ONLINE',
                        child: Text('Online (Razorpay)'),
                      ),
                      DropdownMenuItem(
                        value: 'ACCOUNT_TRANSFER',
                        child: Text('Account Transfer'),
                      ),
                    ],
                    onChanged: (v) => setState(() => mode = v!),
                  ),
                ],
              ),
            ),
            if (mode == 'ACCOUNT_TRANSFER') ...[
              const SizedBox(height: 16),
              _card(
                Column(
                  children: [
                    _field(accountCtrl, 'Account No (optional)'),
                    const SizedBox(height: 10),
                    _field(branchCtrl, 'Branch (optional)'),
                    const SizedBox(height: 10),
                    _field(ifscCtrl, 'IFSC (optional)'),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.upload),
                      label: Text(
                        proofBase64 == null ? 'Upload Proof' : 'Change Proof',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        mode == 'ONLINE'
                            ? 'Pay with Razorpay'
                            : 'Submit Payment',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: child,
  );

  Widget _field(TextEditingController c, String label) =>
      TextField(controller: c, decoration: _dec(label));

  InputDecoration _dec(String label) =>
      InputDecoration(border: OutlineInputBorder(), labelText: label);
}
