import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BlockedUserBottomSheet extends StatelessWidget {
  const BlockedUserBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
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
              color: const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Column(
            children: [
              // Circle with slash icon
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCDC2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.block,
                    color: Color(0xFFB42318),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Text content
              Column(
                children: [
                  const Text(
                    'Ваш акаунт заблокований!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                      color: Colors.black,
                      height: 28.8 / 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ваш акаунт тимчасово заблоковано за рішенням адміністратора.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      color: Color(0xFF71717A),
                      fontWeight: FontWeight.w400,
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
              // Primary button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Детальніше - можна додати логіку
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                    backgroundColor: const Color(0xFF015873),
                    side: const BorderSide(color: Color(0xFF015873)),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Детальніше',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.16,
                      height: 24 / 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Скасувати - можна додати логіку
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Скасувати',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.16,
                      height: 24 / 16,
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