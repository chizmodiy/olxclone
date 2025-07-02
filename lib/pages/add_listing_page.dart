import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'dart:io';
import 'dart:ui';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select a maximum of 7 images.')),
      );
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 7) {
          _selectedImages.removeRange(7, _selectedImages.length);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 70.0,
        centerTitle: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(10),
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                iconSize: 20,
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Додати оголошення',
                style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider
            Container(
              height: 1,
              color: AppColors.zinc200,
            ),
            const SizedBox(height: 20),

            // Add Photo Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Додайте фото',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                ),
                Text(
                  '${_selectedImages.length}/7',
                  style: AppTextStyles.captionMedium.copyWith(color: AppColors.color5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12), // Apply borderRadius to InkWell for visual feedback
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: AppColors.zinc200, // Replace with your desired color
                  strokeWidth: 1.0,
                  dashWidth: 13.0, // Length of dashes
                  gapWidth: 13.0, // Length of gaps
                  borderRadius: 12.0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.zinc50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          'assets/icons/Featured icon.svg',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Перемістіть зображення',
                        style: AppTextStyles.body1Medium.copyWith(color: AppColors.color2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG (max. 200MB)',
                        style: AppTextStyles.captionRegular.copyWith(color: AppColors.color8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // Title Input Field
            Text(
              'Заголовок',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть текст',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5), // Zinc-400
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Input Field
            Text(
              'Опис',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
            Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть текст',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5), // Zinc-400
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            Text(
              'Категорія',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Оберіть категорію',
                      style: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/chevron_down.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Location Section
            Text(
              'Локація',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Оберіть область',
                      style: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/chevron_down.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Map Placeholder
            Container(
              width: double.infinity,
              height: 364,
              decoration: BoxDecoration(
                color: AppColors.zinc200,
                borderRadius: BorderRadius.circular(12),
                // Image will be added here later
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/map_placeholder.png', // Placeholder image
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(left: 13, bottom: 13, child: Image.asset('assets/images/google_logo.png', width: 111.11, height: 25)),
                  Positioned(
                    right: 16,
                    top: 192,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(16, 24, 40, 0.05),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/mark.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(16, 24, 40, 0.05),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/plus.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(16, 24, 40, 0.05),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/minus.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 202,
                    top: 121,
                    child: SvgPicture.asset(
                      'assets/icons/pin_marker.svg', // Pin marker
                      width: 24,
                      height: 32,
                      // The fill color in the SVG needs to be adjusted via a custom SvgPicture.builder if dynamic color is needed.
                      // For now, it's hardcoded in the SVG itself from the design.
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // My Location Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc100,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc100, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/marker_pin_04.svg',
                    width: 21,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Моє місцезнаходження',
                    style: AppTextStyles.body2Semibold.copyWith(color: AppColors.color2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sell/Free Switch
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.zinc100,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc50, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(200),
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
                        child: Text(
                          'Продати',
                          style: AppTextStyles.body2Semibold.copyWith(color: AppColors.color2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Center(
                        child: Text(
                          'Безкоштовно',
                          style: AppTextStyles.body2Semibold.copyWith(color: AppColors.color7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Currency Switch
            Text(
              'Валюта',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(color: AppColors.primaryColor, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/currency_grivna.svg',
                            width: 21,
                            height: 20,
                            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ГРН',
                            style: AppTextStyles.body2Semibold.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(color: AppColors.zinc200, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/currency_euro.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color5, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EUR',
                            style: AppTextStyles.body2Semibold.copyWith(color: AppColors.color8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(color: AppColors.zinc200, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/currency_dollar.svg',
                            width: 21,
                            height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color5, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'USD',
                            style: AppTextStyles.body2Semibold.copyWith(color: AppColors.color8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Price Input Field
            Text(
              'Ціна',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                keyboardType: TextInputType.number,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: '0.0₴',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Negotiable Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Договірна',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color12),
                ),
                SvgPicture.asset(
                  'assets/icons/toggle_off.svg', // Placeholder for toggle switch
                  width: 40,
                  height: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              color: AppColors.zinc200,
            ),
            const SizedBox(height: 20),

            // Contact Form Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Котактна форма',
                  style: AppTextStyles.body1Medium.copyWith(color: AppColors.color2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Оберіть спосіб зв\’язку',
                  style: AppTextStyles.body2Regular.copyWith(color: AppColors.color7),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.zinc100,
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: AppColors.zinc100, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/whatsapp.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color5, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.zinc100,
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: AppColors.zinc100, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/telegram.svg',
                    width: 20,
                    height: 20,
                    // Telegram icon has its own gradient, no need for colorFilter
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.zinc100,
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: AppColors.zinc100, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/viber.svg',
                    width: 20,
                    height: 20,
                    // Viber icon has its own colors, no need for colorFilter
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: AppColors.primaryColor, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/phone.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.zinc100,
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: AppColors.zinc100, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/message_circle_01.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ua.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                      decoration: InputDecoration(
                        hintText: '+380',
                        hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm and Cancel Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle confirm action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                      elevation: 2,
                    ),
                    child: Text(
                      'Підтвердити',
                      style: AppTextStyles.body1Medium.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle cancel action
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(200),
                        side: BorderSide(color: AppColors.zinc200, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                      elevation: 2,
                    ),
                    child: Text(
                      'Скасувати',
                      style: AppTextStyles.body1Medium.copyWith(color: AppColors.color2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gapWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final Path path = Path();
    path.addRRect(rRect);

    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DashedBorderPainter) {
      return oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.dashWidth != dashWidth ||
          oldDelegate.gapWidth != gapWidth ||
          oldDelegate.borderRadius != borderRadius;
    }
    return true;
  }
} 