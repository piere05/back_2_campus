import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirestoreTestPage(),
    );
  }
}

class FirestoreTestPage extends StatefulWidget {
  const FirestoreTestPage({super.key});

  @override
  State<FirestoreTestPage> createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  @override
  void initState() {
    super.initState();
    testFirestoreConnection();
  }

  Future<void> testFirestoreConnection() async {
    try {
      await FirebaseFirestore.instance
          .collection('connection_test')
          .doc('test')
          .set({
            'status': 'connected',
            'time': DateTime.now().toIso8601String(),
          });

      print('✅ Firestore connected successfully');
    } catch (e) {
      print('❌ Firestore connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Check console logs for Firestore status',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
