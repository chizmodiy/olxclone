import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_bottom_sheet.dart';

class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  const CommonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

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
                // Показуємо bottom sheet для розлогінених користувачів
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
              } else {
                Navigator.pushNamed(context, '/profile');
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: avatarUrl == null ? Colors.grey[300] : null,
              ),
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
} 