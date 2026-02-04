import 'package:flutter/material.dart';
import '../notification_page.dart';
import 'hod_layout.dart';

class HodNotificationPage extends StatelessWidget {
  const HodNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HodLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 10),

          /// ✅ THIS IS THE FIX
          Expanded(child: NotificationBody()),
        ],
      ),
    );
  }
}
