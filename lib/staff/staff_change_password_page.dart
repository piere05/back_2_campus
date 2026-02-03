import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'staff_layout.dart';

class StaffChangePasswordPage extends StatefulWidget {
  const StaffChangePasswordPage({super.key});

  @override
  State<StaffChangePasswordPage> createState() =>
      _StaffChangePasswordPageState();
}

class _StaffChangePasswordPageState extends State<StaffChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool loading = false;
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email!;

      // 🔐 Re-authentication
      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPasswordCtrl.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      // 🔁 Update password
      await user.updatePassword(newPasswordCtrl.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      currentPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Password update failed'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffLayout(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),

              _passwordField(
                controller: currentPasswordCtrl,
                label: 'Current Password',
                hidden: hideCurrent,
                toggle: () => setState(() => hideCurrent = !hideCurrent),
              ),

              _passwordField(
                controller: newPasswordCtrl,
                label: 'New Password',
                hidden: hideNew,
                toggle: () => setState(() => hideNew = !hideNew),
              ),

              _passwordField(
                controller: confirmPasswordCtrl,
                label: 'Confirm New Password',
                hidden: hideConfirm,
                toggle: () => setState(() => hideConfirm = !hideConfirm),
                confirm: true,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update Password',
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
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback toggle,
    bool confirm = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: hidden,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';

          if (label == 'New Password' && v.length < 6) {
            return 'Minimum 6 characters';
          }

          if (confirm && v != newPasswordCtrl.text) {
            return 'Passwords do not match';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          suffixIcon: IconButton(
            icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
