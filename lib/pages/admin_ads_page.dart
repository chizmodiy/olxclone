import 'package:flutter/material.dart';

class AdminAdsPage extends StatelessWidget {
  const AdminAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Header block
          Container(
            width: 1280,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Оголошення',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                Row(
                  children: [
                    // Search field
                    SizedBox(
                      width: 320,
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Color(0xFF52525B)),
                          hintText: 'Пошук',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.16,
                            fontFamily: 'Inter',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F3F3),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(200),
                            borderSide: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(200),
                            borderSide: const BorderSide(color: Color(0xFF015873), width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
                      label: const Text(
                        'Фільтр',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.16,
                          fontFamily: 'Inter',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        elevation: 1,
                        shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Table block (заглушка)
          Expanded(
            child: Container(
              width: 1280,
              color: Colors.transparent,
              child: const Center(
                child: Text(
                  'Тут буде таблиця оголошень',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 