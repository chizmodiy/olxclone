import 'package:flutter/material.dart';

class AvatarUtils {
  /// Перевіряє, чи є URL аватара валідним та не порожнім
  static bool isValidAvatarUrl(String? avatarUrl) {
    print('AvatarUtils.isValidAvatarUrl called with: $avatarUrl');
    
    if (avatarUrl == null) {
      print('Avatar URL is null');
      return false;
    }
    if (avatarUrl.isEmpty) {
      print('Avatar URL is empty');
      return false;
    }
    if (avatarUrl.trim().isEmpty) {
      print('Avatar URL is trimmed empty');
      return false;
    }
    
    // Додаткові перевірки для URL
    try {
      final uri = Uri.parse(avatarUrl);
      final isValid = uri.hasScheme && uri.hasAuthority;
      print('Avatar URL parsed: $uri, isValid: $isValid');
      return isValid;
    } catch (e) {
      print('Avatar URL parsing error: $e');
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
    print('AvatarUtils.getAvatarPlaceholder called with: size=$size, backgroundColor=$backgroundColor, iconColor=$iconColor, iconSize=$iconSize');
    
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
    print('AvatarUtils.buildAvatar called with: $avatarUrl, size: $size');
    
    if (isValidAvatarUrl(avatarUrl)) {
      print('Building avatar with image: $avatarUrl');
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('Image network error: $error');
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
      print('Building avatar with placeholder');
      return getAvatarPlaceholder(
        size: size,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        iconSize: iconSize,
      );
    }
  }
} 