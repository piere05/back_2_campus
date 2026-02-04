// ignore_for_file: unused_field, prefer_final_fields

import 'package:flutter/material.dart';

import '../logout.dart';

// ALUMNI PAGES
import 'alumni_add_edit_job_internship_page.dart';
import 'alumni_change_password_page.dart';
import 'alumni_dashboard.dart';
import 'alumni_interested_job_internship_page.dart';
import 'alumni_manage_job_internship_page.dart';
import 'alumni_notification.dart';
import 'alumni_profile_page.dart';
import 'alumni_sponsorship_list_page.dart';

class AlumniLayout extends StatefulWidget {
  final Widget child;

  const AlumniLayout({super.key, required this.child});

  @override
  State<AlumniLayout> createState() => _AlumniLayoutState();
}

class _AlumniLayoutState extends State<AlumniLayout> {
  int _bottomIndex = 0;

  final Color primary = const Color(0xFF1E3A8A);
  final Color bg = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Alumni Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              width: double.infinity,
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 110),
                  const SizedBox(height: 12),
                  const Text(
                    'Back 2 Campus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _menuItem(Icons.home, 'Home', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlumniDashboard(),
                      ),
                    );
                  }),

                  _menuItem(Icons.work, 'Add Job / Internship', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlumniAddEditJobInternshipPage(),
                      ),
                    );
                  }),

                  _menuItem(Icons.list, 'List Job / Internship', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlumniManageJobInternshipPage(),
                      ),
                    );
                  }),

                  _menuItem(Icons.handshake, 'Manage Sponsorship', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlumniSponsorshipListPage(),
                      ),
                    );
                  }),
                  _menuItem(Icons.favorite, 'My Interests Jobs', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AlumniInterestedJobInternshipPage(),
                      ),
                    );
                  }),
                  _menuItem(Icons.lock, 'Change Password', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlumniChangePasswordPage(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Color.fromARGB(30, 0, 0, 0), blurRadius: 4),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 3) {
              CommonLogout.logout(context);
              return;
            }

            if (index == 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AlumniDashboard()),
                (route) => false,
              );
              return;
            }

            if (index == 1) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AlumniNotificationPage(),
                ),
                (route) => false,
              );
              return;
            }

            if (index == 2) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AlumniProfilePage()),
                (route) => false,
              );
              return;
            }

            setState(() {
              _bottomIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notify',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_bottomIndex) {
      case 0:
        return widget.child;
      case 1:
        return const Center(
          child: Text('Notifications', style: TextStyle(fontSize: 18)),
        );
      case 2:
        return const Center(
          child: Text('Profile', style: TextStyle(fontSize: 18)),
        );
      default:
        return widget.child;
    }
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}
