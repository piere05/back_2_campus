import 'package:flutter/material.dart';
import 'hod_layout.dart';

class ViewSponsorshipPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ViewSponsorshipPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sponsorship Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          Text(
            data['title'] ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(data['description'] ?? ''),
          const SizedBox(height: 20),

          const Divider(),

          const Text(
            'Alumni Contributions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Alumni list and paid amount will be shown here later.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
