import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _showSignUp = true; // true for Sign Up, false for Log In
  final TextEditingController _phoneNumberController = TextEditingController();

  void _toggleAuthMode() {
    setState(() {
      _showSignUp = !_showSignUp;
    });
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0), // 80px from top
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_showSignUp) _buildSignUpForm(context) else _buildLogInForm(context),
            const SizedBox(height: 40),
            _buildAuthToggleButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/ellipse_1520.svg',
          width: 52,
          height: 52,
        ),
        const SizedBox(height: 20),
        Text(
          'Створити акаунт',
          style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2), // Use color2 for Black
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.zinc50, // Zinc-50
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200, width: 1), // Zinc-200
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(16, 24, 40, 0.05), // rgba(16, 24, 40, 0.05)
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/UA.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+380',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color2), // Black
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2), // Black
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Handle registration logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(200),
                side: BorderSide(color: AppColors.primaryColor, width: 1), // Primary
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            ),
            child: Text(
              'Зареєструватися',
              style: AppTextStyles.body1Medium.copyWith(color: Colors.white), // White
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogInForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/ellipse_1520.svg',
          width: 52,
          height: 52,
        ),
        const SizedBox(height: 20),
        Text(
          'Увійти',
          style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2), // Use color2 for Black
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.zinc50, // Zinc-50
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200, width: 1), // Zinc-200
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(16, 24, 40, 0.05), // rgba(16, 24, 40, 0.05)
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/UA.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+380',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color2), // Black
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2), // Black
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Handle login logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(200),
                side: BorderSide(color: AppColors.primaryColor, width: 1), // Primary
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            ),
            child: Text(
              'Увійти',
              style: AppTextStyles.body1Medium.copyWith(color: Colors.white), // White
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthToggleButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _showSignUp ? 'У Вас є акаунт?' : 'Немає акаунта?',
          style: AppTextStyles.body2Regular.copyWith(color: AppColors.color8), // Zinc-600
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _showSignUp ? 'Увійти' : 'Зареєструватися',
            style: AppTextStyles.body1Medium.copyWith(
              color: AppColors.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}