import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart'; // Import AppColors

class FullScreenImageSliderPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final bool showNavigation; // Додаємо параметр для показу/приховування навігації

  const FullScreenImageSliderPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.showNavigation = true, // За замовчуванням показуємо навігацію
  });

  @override
  State<FullScreenImageSliderPage> createState() => _FullScreenImageSliderPageState();
}

class _FullScreenImageSliderPageState extends State<FullScreenImageSliderPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor.withOpacity(0.9), // Darker, slightly transparent primary color
      body: Stack(
        children: [
          // PageView for images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              );
            },
          ),

          // Close button
          Positioned(top: 48, right: 20, child: _buildCloseButton(context)),

          // Left arrow button - показуємо тільки якщо showNavigation = true і є більше одного зображення
          if (widget.showNavigation && widget.imageUrls.length > 1)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  Icons.chevron_left,
                  _currentIndex > 0 
                    ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300), 
                        curve: Curves.easeIn
                      )
                    : () {}, // Empty function when disabled
                  isEnabled: _currentIndex > 0,
                ),
              ),
            ),

          // Right arrow button - показуємо тільки якщо showNavigation = true і є більше одного зображення
          if (widget.showNavigation && widget.imageUrls.length > 1)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  Icons.chevron_right,
                  _currentIndex < widget.imageUrls.length - 1
                    ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300), 
                        curve: Curves.easeIn
                      )
                    : () {}, // Empty function when disabled
                  isEnabled: _currentIndex < widget.imageUrls.length - 1,
                ),
              ),
            ),

          // Image counter - показуємо тільки якщо showNavigation = true і є більше одного зображення
          if (widget.showNavigation && widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close, 
          color: Colors.white, 
          size: 20,
        ),
      ),
    );
  }

  // Перестворена кнопка навігації
  Widget _buildNavigationButton(IconData icon, VoidCallback onTap, {bool isEnabled = true}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(isEnabled ? 0.3 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: isEnabled ? Colors.white : Colors.white.withOpacity(0.3), 
          size: 24,
        ),
      ),
    );
  }
} 