// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // adjust path if needed

class CommonLogout {
  static Future<void> logout(BuildContext context) async {
    try {
      // 🔐 Firebase sign out (works for all users)
      await FirebaseAuth.instance.signOut();

      // 🚫 Clear navigation stack & go to Login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }
}
