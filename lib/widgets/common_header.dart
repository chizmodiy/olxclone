import 'package:flutter/material.dart';
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AuthBottomSheet(
                    onLoginPressed: () {
                      Navigator.of(context).pop(); // Закриваємо bottom sheet
                      Navigator.of(context).pushNamed('/auth');
                    },
                    onCancelPressed: () {
                      Navigator.of(context).pop(); // Закриваємо bottom sheet
                    },
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