import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For SVG icons
import 'package:withoutname/theme/app_colors.dart'; // Corrected import
import 'package:withoutname/theme/app_text_styles.dart'; // Corrected import

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({Key? key}) : super(key: key);

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 1), // Add 1 for the border
        child: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/chevron-states.svg', // Corrected path for back button icon
              colorFilter: ColorFilter.mode(AppColors.black, BlendMode.srcIn),
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Категорія',
            style: AppTextStyles.heading2Semibold, // Assuming this style exists
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: Size.zero,
            child: Container(
              height: 1.0,
              color: AppColors.zinc200, // Assuming this color exists for the border
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        child: Column(
          children: [
            _buildCategoryButton(
              iconPath: 'assets/icons/grid-01.svg', // Placeholder icon
              title: 'Усі категорії',
              isSelected: true, // Example: mark as selected
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/heart-hand.svg', // Placeholder icon
              title: 'Допомога',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/baby.svg', // Placeholder icon
              title: 'Дитячий світ',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/building-05.svg', // Placeholder icon
              title: 'Нерухомість',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/car-01.svg', // Placeholder icon
              title: 'Авто',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/engine-svgrepo-com 1.svg', // Corrected icon path
              title: 'Запчастини для транспорту',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/briefcase-01.svg', // Placeholder icon
              title: 'Робота',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/dog.svg', // Placeholder icon
              title: 'Тварини',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/sprout.svg', // Placeholder icon
              title: 'Дім і сад',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/monitor-05.svg', // Placeholder icon
              title: 'Електроніка',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/file-check-02.svg', // Placeholder icon
              title: 'Бізнес та послуги',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/home-03.svg', // Placeholder icon
              title: 'Житло подобово',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/handshake.svg', // Placeholder icon
              title: 'Оренда та прокат',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/shirt.svg', // Placeholder icon
              title: 'Мода і стиль',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/dumbbell.svg', // Placeholder icon
              title: 'Хобі, відпочинок і спорт',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/gift-01.svg', // Placeholder icon
              title: 'Віддам безкоштовно',
            ),
            const SizedBox(height: 12),
            _buildCategoryButton(
              iconPath: 'assets/icons/users-round.svg', // Placeholder icon
              title: 'Знайомства',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required String iconPath,
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.zinc50 : AppColors.white,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(16, 24, 40, 0.05),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.zinc200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(AppColors.zinc400, BlendMode.srcIn),
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body1Semibold, // Assuming this style exists
              ),
            ),
            if (isSelected)
              SvgPicture.asset(
                'assets/icons/check.svg', // Placeholder for check icon
                colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn), // Assuming primary color for check
                width: 20,
                height: 20,
              ),
            if (!isSelected)
              SvgPicture.asset(
                'assets/icons/chevron-down.svg', // Placeholder for chevron icon
                colorFilter: ColorFilter.mode(AppColors.black, BlendMode.srcIn),
                width: 20,
                height: 20,
              ),
          ],
        ),
      ),
    );
  }
} 