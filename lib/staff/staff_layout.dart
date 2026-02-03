// ignore_for_file: unused_field, prefer_final_fields

import 'package:flutter/material.dart';

import '../logout.dart';

// STAFF PAGES (adjust imports if names differ)
import 'staff_change_password_page.dart';
import 'staff_dashboard.dart';
import 'staff_notification.dart';
import 'staff_profile_page.dart';

class StaffLayout extends StatefulWidget {
  final Widget child;

  const StaffLayout({super.key, required this.child});

  @override
  State<StaffLayout> createState() => _StaffLayoutState();
}

class _StaffLayoutState extends State<StaffLayout> {
  int _bottomIndex = 0;

  // ===== STAFF COLORS (NO LAVENDER) =====
  final Color primary = const Color(0xFF064E3B); // dark teal
  final Color accent = const Color(0xFF0D9488); // emerald
  final Color bg = const Color(0xFFF5F7FA); // clean light grey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      // ================= DRAWER =================
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
                      MaterialPageRoute(builder: (_) => const StaffDashboard()),
                    );
                  }),

                  // ===== MANAGE NOTIFICATION =====
                  ExpansionTile(
                    leading: Icon(Icons.notifications, color: primary),
                    title: const Text('Manage Notification'),
                    childrenPadding: const EdgeInsets.only(left: 20),
                    children: [
                      _subMenuItem('Add Notification', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffDashboard(),
                          ),
                        );
                      }),
                      _subMenuItem('List Notification', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffDashboard(),
                          ),
                        );
                      }),
                    ],
                  ),

                  // ===== MANAGE STUDENTS =====
                  ExpansionTile(
                    leading: Icon(Icons.school, color: primary),
                    title: const Text('Manage Students'),
                    childrenPadding: const EdgeInsets.only(left: 20),
                    children: [
                      _subMenuItem('Add Student', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffDashboard(),
                          ),
                        );
                      }),
                      _subMenuItem('List Students', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffDashboard(),
                          ),
                        );
                      }),
                    ],
                  ),

                  // ===== VIEW ALUMNI =====
                  _menuItem(Icons.people, 'View Alumni', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StaffDashboard()),
                    );
                  }),

                  // ===== CHANGE PASSWORD =====
                  _menuItem(Icons.lock, 'Change Password', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaffChangePasswordPage(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),

      // ================= BOTTOM NAV =================
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
                MaterialPageRoute(builder: (_) => const StaffDashboard()),
                (route) => false,
              );
              return;
            }

            if (index == 1) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffNotificationPage(),
                ),
                (route) => false,
              );
              return;
            }

            if (index == 2) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const StaffProfilePage()),
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

  // ================= BODY SWITCH =================
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

  // ================= MENU HELPERS =================
  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _subMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
