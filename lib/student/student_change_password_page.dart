import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_layout.dart';

class StudentChangePasswordPage extends StatefulWidget {
  const StudentChangePasswordPage({super.key});

  @override
  State<StudentChangePasswordPage> createState() =>
      _StudentChangePasswordPageState();
}

class _StudentChangePasswordPageState extends State<StudentChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool loading = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email!;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordCtrl.text.trim(),
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordCtrl.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
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
    return StudentLayout(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color.fromARGB(25, 0, 0, 0), blurRadius: 8),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // CURRENT PASSWORD
                  _passwordField(
                    controller: _currentPasswordCtrl,
                    label: 'Current Password',
                    show: showCurrent,
                    toggle: () => setState(() => showCurrent = !showCurrent),
                  ),

                  const SizedBox(height: 14),

                  // NEW PASSWORD
                  _passwordField(
                    controller: _newPasswordCtrl,
                    label: 'New Password',
                    show: showNew,
                    toggle: () => setState(() => showNew = !showNew),
                  ),

                  const SizedBox(height: 14),

                  // CONFIRM PASSWORD
                  _passwordField(
                    controller: _confirmPasswordCtrl,
                    label: 'Confirm Password',
                    show: showConfirm,
                    toggle: () => setState(() => showConfirm = !showConfirm),
                    confirm: true,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: loading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 2, 195, 163),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= PASSWORD FIELD =================
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback toggle,
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (!confirm && value.length < 6) {
          return 'Minimum 6 characters';
        }
        if (confirm && value != _newPasswordCtrl.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
