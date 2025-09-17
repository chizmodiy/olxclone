import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ComplaintSuccessBottomSheet extends StatelessWidget {
  const ComplaintSuccessBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Логотип
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: SvgPicture.asset(
              'assets/icons/olxclone-green.svg',
              width: 136,
              height: 32,
            ),
          ),
          const SizedBox(height: 24),
          // Заголовок
          Text(
            'Скарга успішно створена!',
            style: AppTextStyles.heading3Medium.copyWith(color: AppColors.color2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Опис (необов'язково, можна додати, якщо потрібно більше деталей)
          Text(
            'Ваша скарга була успішно надіслана. Ми розглянемо її найближчим часом.',
            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Кнопка "Повернутись"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закриваємо BottomSheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Повернутись',
                style: AppTextStyles.body1Semibold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 