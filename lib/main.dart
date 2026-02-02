import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'login_page.dart';
import 'student/student_dashboard.dart';
import 'staff/staff_dashboard.dart';
import 'hod/hod_dashboard.dart';
import 'alumni/alumni_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getHome() async {
    final user = FirebaseAuth.instance.currentUser;

    // not logged in
    if (user == null) {
      return const LoginPage();
    }

    final email = user.email!;

    Future<bool> existsIn(String col) async {
      final snap = await FirebaseFirestore.instance
          .collection(col)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    }

    if (await existsIn('students')) {
      return const StudentDashboard();
    }
    if (await existsIn('staff')) {
      return const StaffDashboard();
    }
    if (await existsIn('hod')) {
      return const HodDashboard();
    }
    if (await existsIn('alumni')) {
      return const AlumniDashboard();
    }

    // logged in but no role
    await FirebaseAuth.instance.signOut();
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _getHome(),
        builder: (context, snap) {
          if (!snap.hasData) {
            // NO loading UI, just white
            return const Scaffold(backgroundColor: Colors.white);
          }
          return snap.data!;
        },
      ),
    );
  }
}
