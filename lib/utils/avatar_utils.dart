import 'package:flutter/material.dart';

class AvatarUtils {
  /// Перевіряє, чи є URL аватара валідним та не порожнім
  static bool isValidAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null) {
      return false;
    }
    if (avatarUrl.isEmpty) {
      return false;
    }
    if (avatarUrl.trim().isEmpty) {
      return false;
    }
    
    // Додаткові перевірки для URL
    try {
      final uri = Uri.parse(avatarUrl);
      final isValid = uri.hasScheme && uri.hasAuthority;
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Повертає заглушку для аватара з іконкою користувача
  static Widget getAvatarPlaceholder({
    double size = 48,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[300],
      ),
      child: Icon(
        Icons.person,
        color: iconColor ?? Colors.white,
        size: iconSize ?? (size * 0.5),
      ),
    );
  }

  /// Створює аватар з зображенням або заглушкою
  static Widget buildAvatar({
    required String? avatarUrl,
    required double size,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
    BoxFit fit = BoxFit.cover,
  }) {
    if (isValidAvatarUrl(avatarUrl)) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return getAvatarPlaceholder(
              size: size,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              iconSize: iconSize,
            );
          },
        ),
      );
    } else {
      return getAvatarPlaceholder(
        size: size,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        iconSize: iconSize,
      );
    }
  }
} 