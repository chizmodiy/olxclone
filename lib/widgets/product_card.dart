import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String date;
  final String location;
  final List<String> images;
  final bool showLabel;
  final String? labelText;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.date,
    required this.location,
    required this.images,
    this.showLabel = false,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with pagination dots
          Stack(
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: images.isNotEmpty
                      ? Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.zinc200,
                              child: Icon(Icons.broken_image, color: AppColors.color5),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.zinc200, // Placeholder color
                          child: Center(
                            child: Icon(Icons.image, size: 40, color: AppColors.color5), // Placeholder icon
                          ),
                        ),
                ),
              ),
              // Pagination dots
              Positioned(
                bottom: 14,
                left: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.2),
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      // Use a safe length for pagination dots, e.g., min(images.length, 3)
                      images.isNotEmpty ? images.length : 1, // At least one dot if no images
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 0
                              ? AppColors.primaryColor
                              : Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showLabel && labelText != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      labelText!,
                      style: const TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0.14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.16,
                      ),
                    ),
                    const SizedBox(width: 20, height: 20, child: Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Color(0xFF27272A),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF838583),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    letterSpacing: 0.24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    color: Color(0xFF838583),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    letterSpacing: 0.24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 