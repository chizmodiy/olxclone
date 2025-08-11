import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart'; // Import AppColors

class FullScreenImageSliderPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageSliderPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
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
          Positioned(top: 40, right: 20, child: _buildCloseButton(context)),

          // Left arrow button
          Positioned(
            left: 30, // Increased padding from edge
            top: MediaQuery.of(context).size.height / 2 - 24, // Center vertically
            child: _buildNavigationArrow(
              Icons.arrow_back_ios,
              _currentIndex > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn) : null,
            ),
          ),

          // Right arrow button
          Positioned(
            right: 30, // Increased padding from edge
            top: MediaQuery.of(context).size.height / 2 - 24, // Center vertically
            child: _buildNavigationArrow(
              Icons.arrow_forward_ios,
              _currentIndex < widget.imageUrls.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn) : null,
            ),
          ),

          // Image counter
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2), // More transparent white background
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withOpacity(0.3)), // Subtle white border
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 24),
      ),
    );
  }

  // New method for navigation arrows
  Widget _buildNavigationArrow(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0), // Symmetric padding for both icons
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2), // Same style as close button
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5), size: 24),
      ),
    );
  }
} 