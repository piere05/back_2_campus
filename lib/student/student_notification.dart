import 'package:flutter/material.dart';
import '../notification_page.dart';
import 'student_layout.dart';

class StudentNotificationPage extends StatelessWidget {
  const StudentNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
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
          NotificationBody(),
        ],
      ),
    );
  }
}
