import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App started');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔥 Firebase initialized');

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
  String status = 'Testing Firestore connection...';

  @override
  void initState() {
    super.initState();
    debugPrint('📦 FirestoreTestPage loaded');
    testFirestoreConnection();
  }

  Future<void> testFirestoreConnection() async {
    try {
      debugPrint('🧪 Writing to Firestore...');

      DocumentReference ref = await FirebaseFirestore.instance
          .collection('connection_test')
          .add({'status': 'connected', 'time': Timestamp.now()});

      debugPrint('📄 Document written: ${ref.id}');

      debugPrint('🧪 Reading from Firestore...');

      DocumentSnapshot snap = await ref.get();

      debugPrint('📥 Read data: ${snap.data()}');

      setState(() {
        status = '✅ Firestore CONNECTED\nDocument ID:\n${ref.id}';
      });
    } catch (e, s) {
      debugPrint('❌ Firestore FAILED');
      debugPrint(e.toString());
      debugPrint(s.toString());

      setState(() {
        status = '❌ Firestore FAILED\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
