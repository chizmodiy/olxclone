import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Assuming AppColors is defined here

class ProductCardListItem extends StatelessWidget {
  final String id; // Add this line
  final String title;
  final String price;
  final String date;
  final String location;
  final List<String> images;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap; // Add this line

  const ProductCardListItem({
    super.key,
    required this.id, // Add this line
    required this.title,
    required this.price,
    required this.date,
    required this.location,
    required this.images,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // Wrap with InkWell
      onTap: onTap, // Pass the onTap callback
      borderRadius: BorderRadius.circular(12), // Match the container's border radius
      child: Container(
        width: double.infinity, // Adjust width as per parent constraints
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA), // Zinc-50
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 104,
                height: 104,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                                  height: 1.4, // 19.60px / 14px
                                  letterSpacing: 0.14,
                                ),
                                maxLines: 2, // Limit title to 2 lines
                                overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                              ),
                              const SizedBox(height: 2), // Gap 2px
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  height: 1.3, // 26px / 20px
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isFavorite ? AppColors.primaryColor : const Color(0xFF27272A), // Zinc-800
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Gap 8px
                    Row(
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            color: Color(0xFF838583), // Gray-600 (or similar, based on design)
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.3, // 15.60px / 12px
                            letterSpacing: 0.24,
                          ),
                        ),
                        const SizedBox(width: 8), // Gap 8px
                        Text(
                          location,
                          style: const TextStyle(
                            color: Color(0xFF838583), // Gray-600
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.3, // 15.60px / 12px
                            letterSpacing: 0.24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 