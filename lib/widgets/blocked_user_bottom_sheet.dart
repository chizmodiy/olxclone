import 'package:flutter/material.dart';

class BlockedUserBottomSheet extends StatefulWidget {
  final String? blockReason;
  
  const BlockedUserBottomSheet({
    super.key,
    this.blockReason,
  });

  @override
  State<BlockedUserBottomSheet> createState() => _BlockedUserBottomSheetState();
}

class _BlockedUserBottomSheetState extends State<BlockedUserBottomSheet> {
  bool _showDetails = false;

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
          
          // Причина блокування (показується після натискання "Детальніше")
          if (_showDetails && widget.blockReason != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCDC2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Причина:',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB42318),
                      letterSpacing: 0.14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.blockReason!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF52525B),
                      letterSpacing: 0.16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          // Buttons
          Column(
            children: [
              // Кнопка "Детальніше" (показується тільки якщо не розкрито деталі)
              if (!_showDetails && widget.blockReason != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showDetails = true;
                      });
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
              
              // Відстань між кнопками (показується тільки якщо є кнопка "Детальніше")
              if (!_showDetails && widget.blockReason != null)
                const SizedBox(height: 12),
              
              // Кнопка "Скасувати" (показується завжди)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Скасувати - можна додати логіку
                    // Попап не закривається для заблокованих користувачів
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