import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test Page',
          style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.arrow_back,
            color: AppColors.color2,
            size: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Блок створення локації',
              style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
            ),
            const SizedBox(height: 32),
            
            // Тут буде новий блок створення локації
            
          ],
        ),
      ),
    );
  }
} 