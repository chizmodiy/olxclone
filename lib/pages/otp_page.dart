import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ZENO/theme/app_colors.dart';
import 'package:ZENO/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final bool isSignUp;

  const OtpPage({super.key, required this.phoneNumber, required this.isSignUp});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();
  final TextEditingController _otpController5 = TextEditingController();
  final TextEditingController _otpController6 = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final userStatus = await _profileService.getUserStatus();
        if (userStatus == 'blocked') {
          _showBlockedUserBottomSheet();
        }
      }
    });
  }

  void _showBlockedUserBottomSheet() async {
    // Отримуємо профіль користувача з причиною блокування
    final userProfile = await _profileService.getCurrentUserProfile();
    final blockReason = userProfile?['block_reason'];
    
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false, // Неможливо закрити
        enableDrag: false, // Неможливо перетягувати
        builder: (context) => BlockedUserBottomSheet(blockReason: blockReason),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // Disabled snackbar messages
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final otp = _otpController1.text.trim() +
          _otpController2.text.trim() +
          _otpController3.text.trim() +
          _otpController4.text.trim() +
          _otpController5.text.trim() +
          _otpController6.text.trim();
      final smth = await _supabase.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: otp,
        type: OtpType.sms,
      );
      if (smth.session != null) {
        if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        _showSnackBar('OTP verification failed.', isError: true);
      }
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
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    _otpController5.dispose();
    _otpController6.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/ellipse_1520.svg',
              width: 52,
              height: 52,
            ),
            const SizedBox(height: 20),
            Text(
              widget.isSignUp ? 'Створити акаунт' : 'Увійти в акаунт',
              style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isSignUp
                  ? 'Ми надіслали Вам код на номер ${widget.phoneNumber}'
                  : 'Уведіть ПІН-код',
              style: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOtpInputField(context, _otpController1),
                const SizedBox(width: 4),
                _buildOtpInputField(context, _otpController2),
                const SizedBox(width: 4),
                _buildOtpInputField(context, _otpController3),
                const SizedBox(width: 4),
                _buildOtpInputField(context, _otpController4),
                const SizedBox(width: 4),
                _buildOtpInputField(context, _otpController5),
                const SizedBox(width: 4),
                _buildOtpInputField(context, _otpController6),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(200),
                    side: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Підтвердити',
                        style: AppTextStyles.body1Medium.copyWith(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Resend OTP functionality - to be implemented
                _showSnackBar('Resending OTP...');
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all(Size.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: Text(
                widget.isSignUp ? 'Надіслати повторно' : 'Забули ПІН-код?',
                style: AppTextStyles.body1Medium.copyWith(
                  color: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInputField(BuildContext context, TextEditingController controller) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.zinc50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.zinc200, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.05),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
          style: AppTextStyles.heading1Medium.copyWith(color: AppColors.color2),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintText: '0',
            hintStyle: AppTextStyles.heading1Medium.copyWith(color: AppColors.color5),
          ),
          onChanged: (value) {
            if (value.length == 1) {
              FocusScope.of(context).nextFocus();
            }
            if (value.isEmpty) {
              FocusScope.of(context).previousFocus();
            }
          },
        ),
      ),
    );
  }
} 