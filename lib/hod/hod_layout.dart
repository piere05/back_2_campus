// ignore_for_file: unused_field, prefer_final_fields

import 'package:flutter/material.dart';

import '../logout.dart';
import 'add_job_intership.dart';
import 'add_staff_page.dart';
import 'hod_dashboard.dart';
import 'hod_profile_page.dart';
import 'list_job_intership.dart';
import 'list_staff_page.dart';

class HodLayout extends StatefulWidget {
  final Widget child;

  const HodLayout({super.key, required this.child});

  @override
  State<HodLayout> createState() => _HodLayoutState();
}

class _HodLayoutState extends State<HodLayout> {
  int _bottomIndex = 0;

  final Color primary = const Color(0xFF1E3A8A);
  final Color accent = const Color(0xFF2563EB);
  final Color bg = const Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'HOD Dashboard',
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
                  Image.asset('assets/images/logo.png', height: 120),
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
                      MaterialPageRoute(builder: (_) => const HodDashboard()),
                    );
                  }),

                  ExpansionTile(
                    leading: Icon(Icons.campaign, color: primary),
                    title: const Text('Manage Staff'),
                    childrenPadding: const EdgeInsets.only(left: 20),
                    children: [
                      _subMenuItem('Add Staff', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddStaffPage(),
                          ),
                        );
                      }),
                      _subMenuItem('List Staff', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListStaffPage(),
                          ),
                        );
                      }),
                    ],
                  ),

                  ExpansionTile(
                    leading: Icon(Icons.campaign, color: primary),
                    title: const Text('Manage  Job / Intership'),
                    childrenPadding: const EdgeInsets.only(left: 20),
                    children: [
                      _subMenuItem('Add  Job / Intership', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditJobInternshipPage(),
                          ),
                        );
                      }),
                      _subMenuItem('List  Job / Intership', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageJobInternshipPage(),
                          ),
                        );
                      }),
                    ],
                  ),
                  _menuItem(Icons.notifications, 'Notification', () {
                    Navigator.pop(context);
                    setState(() => _bottomIndex = 1);
                  }),

                  _menuItem(Icons.person, 'Profile', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HodProfilePage()),
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
            BoxShadow(color: Color.fromARGB(31, 92, 92, 92), blurRadius: 4),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomIndex,
          selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
          unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 3) {
              CommonLogout.logout(context);
              return;
            }

            if (index == 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HodDashboard()),
                (route) => false,
              );
              return;
            }

            if (index == 2) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HodProfilePage()),
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
        // Home → use passed child (HodDashboard content)
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
