import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hod_layout.dart';

class HodChangePasswordPage extends StatefulWidget {
  const HodChangePasswordPage({super.key});

  @override
  State<HodChangePasswordPage> createState() => _HodChangePasswordPageState();
}

class _HodChangePasswordPageState extends State<HodChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool loading = false;

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user');
      }

      /// 🔐 re-authenticate using STORED login email
      final credential = EmailAuthProvider.credential(
        email: user.email!, // ✅ email from login session
        password: oldPassCtrl.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      /// 🔁 update password
      await user.updatePassword(newPassCtrl.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      oldPassCtrl.clear();
      newPassCtrl.clear();
      confirmPassCtrl.clear();
    } on FirebaseAuthException catch (e) {
      String message = 'Password update failed';

      if (e.code == 'wrong-password') {
        message = 'Old password is incorrect';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please login again and try';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _passwordField(oldPassCtrl, 'Old Password'),
                _gap(),
                _passwordField(newPassCtrl, 'New Password'),
                _gap(),
                _passwordField(
                  confirmPassCtrl,
                  'Confirm New Password',
                  confirm: true,
                ),
                _gap(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Update Password',
                            style: TextStyle(color: Colors.black),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String hint, {
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (confirm && v != newPassCtrl.text) {
          return 'Passwords do not match';
        }
        if (!confirm && hint == 'New Password' && v.length < 6) {
          return 'Minimum 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 14);
}
