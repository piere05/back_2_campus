import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student/student_dashboard.dart';
import 'staff/staff_dashboard.dart';
import 'hod/hod_dashboard.dart';
import 'alumni/alumni_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool hidePassword = true;
  final Color gold = const Color(0xFFD4AF37);

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.black));
  }

  Future<bool> _existsIn(String col, String email) async {
    final snap = await FirebaseFirestore.instance
        .collection(col)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  void _go(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
    );
  }

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty) {
      _error("Email is required");
      return;
    }
    if (!email.contains('@')) {
      _error("Enter a valid email");
      return;
    }
    if (password.isEmpty) {
      _error("Password is required");
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (await _existsIn('students', email)) {
        _go(const StudentDashboard());
        return;
      }
      if (await _existsIn('staff', email)) {
        _go(const StaffDashboard());
        return;
      }
      if (await _existsIn('hod', email)) {
        _go(const HodDashboard());
        return;
      }
      if (await _existsIn('alumni', email)) {
        _go(const AlumniDashboard());
        return;
      }

      await FirebaseAuth.instance.signOut();
      _error("No role assigned to this account");
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error("No account found with this email");
          break;
        case 'wrong-password':
          _error("Incorrect password");
          break;
        case 'invalid-email':
          _error("Invalid email format");
          break;
        default:
          _error("Login failed");
      }
    } catch (_) {
      _error("Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 40),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passCtrl,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
