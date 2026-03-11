import 'package:flutter/material.dart';
import 'package:medigo_delivery/pages/requests_tab.dart'; 
import 'package:medigo_delivery/pages/active_orders_tab.dart'; 
import 'package:medigo_delivery/pages/profile_tab.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const RequestsTab(),      // 0: New Orders
      const ActiveOrdersTab(),  // 1: My Deliveries
      const ProfileTab(),       // 2: Profile
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: "New Orders"),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: "My Deliveries"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}