import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_bottom_sheet.dart';
import '../services/profile_service.dart'; // Import ProfileService
import '../services/profile_notifier.dart'; // Import ProfileNotifier
import '../utils/avatar_utils.dart'; // Import AvatarUtils

class CommonHeader extends StatefulWidget implements PreferredSizeWidget {
  const CommonHeader({super.key});

  @override
  State<CommonHeader> createState() => _CommonHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

class _CommonHeaderState extends State<CommonHeader> {
  String? _avatarUrl;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // init
    _loadAvatarUrl();
    ProfileNotifier().addListener(_onProfileUpdate); // Add listener
    // listener added
  }

  @override
  void dispose() {
    // dispose
    ProfileNotifier().removeListener(_onProfileUpdate); // Remove listener
    // listener removed
    super.dispose();
  }

  void _onProfileUpdate() {
    // profile update
    _loadAvatarUrl(); // Reload avatar when profile is updated
  }

  Future<void> _loadAvatarUrl() async {
    // load avatar
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // loading avatar
      final profile = await _profileService.getUser(user.id);
      // profile loaded
      if (mounted) {
        setState(() {
          // Перевіряємо, чи URL не порожній
          final avatarUrl = profile?.avatarUrl;
          final isValidAvatar = AvatarUtils.isValidAvatarUrl(avatarUrl);
          _avatarUrl = isValidAvatar ? avatarUrl : null;
        });
      }
    } else {
      // no current user
    }
  }

  @override
  Widget build(BuildContext context) {
    // build
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = _avatarUrl ?? user?.userMetadata?['avatar_url'] as String?;
    final isValidAvatar = AvatarUtils.isValidAvatarUrl(avatarUrl);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 42, 13, 16),
      color: AppColors.primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Лого
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          // Аватар користувача
          GestureDetector(
            onTap: () {
              if (user == null) {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                        // Bottom sheet
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AuthBottomSheet(
                            title: 'Тут буде ваш профіль',
                            subtitle: 'Увійдіть у профіль, щоб керувати своїми даними та налаштуваннями.',
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
              } else {
                Navigator.pushNamed(context, '/profile');
              }
            },
            child: AvatarUtils.buildAvatar(
              avatarUrl: isValidAvatar ? avatarUrl : null,
              size: 48,
              backgroundColor: Colors.grey[300],
              iconColor: Colors.white,
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }
} 