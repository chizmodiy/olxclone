import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/pages/add_listing_page.dart';
import 'package:withoutname/pages/home_page.dart';
import 'package:withoutname/pages/viewed_page.dart';
import 'package:withoutname/pages/favorites_page.dart';
import '../models/region.dart';
import '../services/region_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'chat_page.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomePage(),
    const FavoritesPage(),
    const ViewedPage(),
    const ChatPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(23, 6, 23, 36),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.10),
              offset: Offset(0, 4),
              blurRadius: 16,
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.zinc200, width: 1.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: _buildNavItem(
                iconPath: 'assets/icons/home-02.svg',
                label: 'Головна',
                index: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavItem(
                iconPath: 'assets/icons/heart-rounded.svg',
                label: 'Обране',
                index: 1,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.primaryColor, width: 1),
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddListingPage()));
                  if (result == true && _selectedIndex == 0) {
                    // _homeContentKey.currentState?.refreshProducts(); // This line is removed
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                shape: const CircleBorder(),
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavItem(
                iconPath: 'assets/icons/book-open-01.svg',
                label: 'Проглянуті',
                index: 2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavItemWithNotification(
                iconPath: 'assets/icons/message-circle-01.svg',
                label: 'Чат',
                index: 3,
                hasNotification: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? AppColors.primaryColor : AppColors.color5;
    final Color textColor = isSelected ? AppColors.color2 : AppColors.color8;

    return InkWell(
      onTap: () => _onItemTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.captionRegular.copyWith(color: textColor, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithNotification({
    required String iconPath,
    required String label,
    required int index,
    required bool hasNotification,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? AppColors.primaryColor : AppColors.color5;
    final Color textColor = isSelected ? AppColors.color2 : AppColors.color8;

    return InkWell(
      onTap: () => _onItemTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                if (hasNotification)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SvgPicture.asset(
                      'assets/icons/notification_dot.svg',
                      width: 6,
                      height: 6,
                      colorFilter: ColorFilter.mode(AppColors.notificationDotColor, BlendMode.srcIn),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.captionRegular.copyWith(color: textColor, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}