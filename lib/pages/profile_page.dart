import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import './active_listings_page.dart';
import './inactive_listings_page.dart';
import './favorite_listings_page.dart';
import './personal_data_page.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../widgets/logout_confirmation_bottom_sheet.dart';
import '../widgets/delete_account_confirmation_bottom_sheet.dart';
import '../utils/avatar_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  String? _profileImageUrl; // URL фото профілю
  bool _hasProfileImage = false; // Чи є фото профілю

  @override
  void initState() {
    super.initState();
    print('ProfilePage.initState called');
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('ProfilePage: Post frame callback executed');
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        print('ProfilePage: Current user found: ${currentUser.id}');
        final userStatus = await _profileService.getUserStatus();
        print('ProfilePage: User status: $userStatus');
        if (userStatus == 'blocked') {
          _showBlockedUserBottomSheet();
        }
        
        // Завантажуємо фото профілю
        print('ProfilePage: Loading profile image');
        await _loadProfileImage();
      } else {
        print('ProfilePage: No current user found');
      }
    });
  }

  Future<void> _loadProfileImage() async {
    print('ProfilePage._loadProfileImage called');
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        print('Loading profile image for user: ${currentUser.id}');
        final profile = await _profileService.getUser(currentUser.id);
        print('Profile loaded in ProfilePage: ${profile?.avatarUrl}');
        
        if (AvatarUtils.isValidAvatarUrl(profile?.avatarUrl)) {
          print('Setting profile image to: ${profile!.avatarUrl}');
          setState(() {
            _profileImageUrl = profile.avatarUrl;
            _hasProfileImage = true;
          });
        } else {
          print('No valid profile image, setting to null');
          setState(() {
            _profileImageUrl = null;
            _hasProfileImage = false;
          });
        }
      } else {
        print('No current user in ProfilePage');
      }
    } catch (e) {
      print('ProfilePage._loadProfileImage error: $e');
      setState(() {
        _profileImageUrl = null;
        _hasProfileImage = false;
      });
    }
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

  void _showLogoutConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const LogoutConfirmationBottomSheet(),
    );
  }

  void _showDeleteAccountConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const DeleteAccountConfirmationBottomSheet(),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF52525B),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.16,
            height: 1.5,
          ),
        ),
      );

  Widget _profileButton({
    required String text,
    required VoidCallback onTap,
  }) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x10102828),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black, size: 20),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    print('ProfilePage.build called, _hasProfileImage=$_hasProfileImage, _profileImageUrl=$_profileImageUrl');
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
                appBar: PreferredSize(
        preferredSize: const Size.fromHeight(128),
        child: Container(
          width: double.infinity,
          height: 128,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
          ),
          child: Column(
            children: [
              // Верхня частина AppBar (синя)
              Container(
                width: double.infinity,
                height: 80,
                padding: const EdgeInsets.fromLTRB(13, 16, 13, 0),
                child: Stack(
                  children: [
                    Positioned(
                      left: 13,
                      top: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          'assets/icons/chevron-states.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Нижня частина AppBar (біла)
              Container(
                width: double.infinity,
                height: 48, // 128 - 80 = 48
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 13, right: 13, top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6), // Місце для аватара
                // Головне
                _sectionTitle('Головне'),
                _profileButton(
                  text: 'Особисті данні',
                  onTap: () async { // Make onTap async
                    print('ProfilePage: Navigating to PersonalDataPage');
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PersonalDataPage()),
                    );
                    print('ProfilePage: PersonalDataPage returned: $result');
                    if (result == true) {
                      print('ProfilePage: Reloading profile image');
                      _loadProfileImage(); // Reload the image if personal data was updated
                    }
                  },
                ),
                _profileButton(
                  text: 'Вийти з облікового запису',
                  onTap: () {
                    _showLogoutConfirmationBottomSheet();
                  },
                ),
                _profileButton(
                  text: 'Видалити обліковий запис',
                  onTap: () {
                    _showDeleteAccountConfirmationBottomSheet();
                  },
                ),
                const SizedBox(height: 20),
                // (Аватар між блоками видалено)
                // Мої оголошення
                _sectionTitle('Мої оголошення'),
                _profileButton(
                  text: 'Активні',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ActiveListingsPage()),
                    );
                  },
                ),
                _profileButton(
                  text: 'Неактивні',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => InactiveListingsPage()),
                    );
                  },
                ),
                _profileButton(
                  text: 'Улюблені оголошення',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => FavoriteListingsPage()),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        // Аватар поверх усього
        Positioned(
          top: 46, // Позиція аватара - на межі між синім та білим (80 - 34)
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                border: _hasProfileImage 
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
              ),
              child: AvatarUtils.buildAvatar(
                avatarUrl: _hasProfileImage ? _profileImageUrl : null,
                size: 66, // 68 - 2 для контуру
                backgroundColor: Colors.grey[300],
                iconColor: Colors.white,
                iconSize: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 