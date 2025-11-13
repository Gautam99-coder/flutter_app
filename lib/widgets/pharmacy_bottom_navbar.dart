import 'package:abc_app/screens/pharmacy/pharmacy_profile_page.dart'; // <-- Import the new profile page
import 'package:abc_app/screens/pharmacy/pharmacy_store_page.dart';
import 'package:flutter/material.dart';

import '../screens/pharmacy/pharmacy_homepage.dart';
import '../screens/pharmacy/pharmacy_orders_page.dart';

class PharmacyBottomNavbar extends StatefulWidget {
  const PharmacyBottomNavbar({super.key});

  @override
  State<PharmacyBottomNavbar> createState() => _PharmacyBottomNavbarState();
}

class _PharmacyBottomNavbarState extends State<PharmacyBottomNavbar> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const PharmacyHomepage(),
    const PharmacyOrdersPage(), // Placeholder
    const PharmacyStorePage(), // Placeholder
    const PharmacyProfilePage(), // <-- Use the new PharmacyProfilePage here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}