import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:withoutname/pages/otp_page.dart';
import 'package:flutter/services.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _showSignUp = true; // true for Sign Up, false for Log In
  bool _isLoading = false;
  final TextEditingController _phoneNumberController = TextEditingController();
  final _supabase = Supabase.instance.client;

  void _toggleAuthMode() {
    setState(() {
      _showSignUp = !_showSignUp;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final phone = '+380' + _phoneNumberController.text.trim();
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
      _showSnackBar('OTP sent to $phone. Please check your phone.');
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => OtpPage(phoneNumber: phone, isSignUp: _showSignUp)));
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('An unexpected error occurred', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final phone = '+380' + _phoneNumberController.text.trim();
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
      _showSnackBar('OTP sent to $phone. Please check your phone.');
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => OtpPage(phoneNumber: phone, isSignUp: _showSignUp)));
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('An unexpected error occurred', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  decoration: InputDecoration(
                    hintText: '(XX XXX XX XX)',
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
            onPressed: _isLoading ? null : _handleSignUp,
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
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  decoration: InputDecoration(
                    hintText: '(XX XXX XX XX)',
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
            onPressed: _isLoading ? null : _handleLogIn,
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
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
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
          style: ButtonStyle( // Using ButtonStyle for more control over states
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            minimumSize: MaterialStateProperty.all(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashFactory: NoSplash.splashFactory, // Remove splash effect
            overlayColor: MaterialStateProperty.all(Colors.transparent), // Remove overlay/highlight effect
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