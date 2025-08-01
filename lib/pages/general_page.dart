import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/pages/add_listing_page.dart';
import 'package:withoutname/pages/home_page.dart';
import 'package:withoutname/pages/viewed_page.dart';
import 'package:withoutname/pages/favorites_page.dart';
import 'chat_page.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../widgets/auth_bottom_sheet.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();
  final GlobalKey<HomeContentState> _homeContentKey = GlobalKey<HomeContentState>();

  // Додаємо MapPage як другу вкладку
  late final List<Widget> _pages = [
    HomePage(key: _homeContentKey),
    const FavoritesPage(),
    const ViewedPage(),
    const ChatPage(),
  ];

  // У GeneralPage: визначити, чи є непрочитані повідомлення
  // Додати змінну hasUnreadMessages, яка визначається на основі ChatPage або глобального стану
  // Для прикладу, якщо є доступ до ChatPage._chats:
  bool get hasUnreadMessages {
    // Тут має бути логіка перевірки наявності непрочитаних повідомлень
    // Наприклад, якщо є глобальний провайдер або можна отримати список чатів
    // Псевдокод:
    // return chats.any((chat) => chat['unreadCount'] > 0);
    return false; // TODO: замінити на реальну перевірку
  }

  @override
  void initState() {
    super.initState();
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final userStatus = await _profileService.getUserStatus();
        if (userStatus == 'blocked') {
          _showBlockedUserBottomSheet();
        }
      }
    });
  }

  void _onItemTapped(int index) {
    // Перевіряємо, чи це кнопка чату (індекс 3) і чи користувач не авторизований
    if (index == 3) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        // Показуємо AuthBottomSheet для неавторизованих користувачів
        _showAuthBottomSheet();
        return;
      }
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAuthBottomSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Затемнення фону з блюром
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AuthBottomSheet(
                onLoginPressed: () {
                  Navigator.of(context).pop(); // Закриваємо bottom sheet
                  Navigator.of(context).pushNamed('/auth');
                },
                onCancelPressed: () {
                  Navigator.of(context).pop(); // Закриваємо bottom sheet
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockedUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Неможливо закрити
      enableDrag: false, // Неможливо перетягувати
      builder: (context) => const BlockedUserBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(23, 6, 23, MediaQuery.of(context).size.width >= 450 ? 36 : 20),
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
                  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                  if (currentUserId == null) {
                    // Показати AuthBottomSheet для авторизації
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            // Затемнення фону з блюром
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom sheet
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: AuthBottomSheet(
                                title: 'Тут будуть ваші оголошення',
                                subtitle: 'Увійдіть у профіль, щоб переглядати, створювати або зберігати оголошення.',
                                onLoginPressed: () {
                                  Navigator.of(context).pop(); // Закриваємо bottom sheet
                                  Navigator.of(context).pushNamed('/auth');
                                },
                                onCancelPressed: () {
                                  Navigator.of(context).pop(); // Закриваємо bottom sheet
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    return;
                  }
                  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddListingPage()));
                  if (result == true && _selectedIndex == 0) {
                    // Додаємо невелику затримку для забезпечення оновлення
                    await Future.delayed(const Duration(milliseconds: 500));
                    _homeContentKey.currentState?.refreshProducts();
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
                hasNotification: hasUnreadMessages,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final showText = screenWidth >= 450;

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
            if (showText) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.captionRegular.copyWith(color: textColor, letterSpacing: 0.2),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final showText = screenWidth >= 450;

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
            if (showText) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.captionRegular.copyWith(color: textColor, letterSpacing: 0.2),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}