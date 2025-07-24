import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_ads_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedTab = 0; // 0 - Оголошення, 1 - Скарги, 2 - Користувачі
  bool _showLogoutMenu = false;

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_selectedTab == 0) {
      content = const AdminAdsPage();
    } else if (_selectedTab == 1) {
      content = const Center(child: Text('Скарги', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)));
    } else {
      content = const Center(child: Text('Користувачі', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          AdminHeader(
            selectedTab: _selectedTab,
            onTabSelected: _onTabSelected,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

// ... AdminHeader and _AdminTabButton classes ... 