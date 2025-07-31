import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AuthBottomSheet extends StatelessWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onCancelPressed;

  const AuthBottomSheet({
    super.key,
    this.onLoginPressed,
    this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.zinc200,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onCancelPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                ),
                                 child: SvgPicture.asset(
                   'assets/icons/x-close.svg',
                   width: 20,
                   height: 20,
                   colorFilter: const ColorFilter.mode(AppColors.color8, BlendMode.srcIn),
                 ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Column(
            children: [
              // Circle with primary color
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 20),
              // Text content
              Column(
                children: [
                  Text(
                    'Тут будуть ваші сповіщення',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1Semibold.copyWith(
                      color: Colors.black,
                      fontSize: 24,
                      height: 28.8 / 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Увійдіть у свій профіль, щоб перевірити, чи не отримали ви важливих оновлень.',
                    textAlign: TextAlign.center,
                                         style: AppTextStyles.body1Regular.copyWith(
                       color: AppColors.color7,
                       height: 22.4 / 16,
                       letterSpacing: 0.16,
                     ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    elevation: 0,
                    shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                  ),
                  child: Text(
                    'Увійти або створити акаунт',
                    style: AppTextStyles.body1Medium.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: onCancelPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: AppColors.zinc200, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    elevation: 0,
                    shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                  ),
                  child: Text(
                    'Скасувати',
                    style: AppTextStyles.body1Medium.copyWith(
                      color: Colors.black,
                      letterSpacing: 0.16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 