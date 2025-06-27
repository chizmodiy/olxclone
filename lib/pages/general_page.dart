import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Page'),
      ),
      body: Center(
        child: Text('Selected Page: ${_selectedIndex == 0 ? "Головна" : _selectedIndex == 1 ? "Обране" : _selectedIndex == 2 ? "Проглянуті" : "Чат"}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle the central plus button tap
        },
        backgroundColor: AppColors.primaryColor,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          'assets/icons/plus.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              iconPath: 'assets/icons/home-02.svg',
              label: 'Головна',
              index: 0,
            ),
            _buildNavItem(
              iconPath: 'assets/icons/heart-rounded.svg',
              label: 'Обране',
              index: 1,
            ),
            const SizedBox(width: 48), // Placeholder for the FAB
            _buildNavItem(
              iconPath: 'assets/icons/book-open-01.svg',
              label: 'Проглянуті',
              index: 2,
            ),
            _buildNavItemWithNotification(
              iconPath: 'assets/icons/message-circle-01.svg',
              label: 'Чат',
              index: 3,
              hasNotification: true, // Example: set to true to show dot
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
    final Color iconColor = isSelected ? AppColors.primaryColor : AppColors.color5; // color5 is Zinc-400
    final Color textColor = isSelected ? AppColors.color2 : AppColors.color8; // color2 is similar to Black, color8 is Zinc-600

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
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