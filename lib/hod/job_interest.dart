import 'package:flutter/material.dart';
import 'hod_layout.dart';

class InterestedUsersSamplePage extends StatelessWidget {
  const InterestedUsersSamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Interested Users (Sample)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 20),
          Text('This page will show students / alumni interested list later.'),
        ],
      ),
    );
  }
}
