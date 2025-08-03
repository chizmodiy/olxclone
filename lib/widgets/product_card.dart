import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/profile_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String date;
  final String location;
  final List<String> images;
  final bool showLabel;
  final String? labelText;
  final bool isFavorite;
  final bool isNegotiable;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    required this.date,
    required this.location,
    required this.images,
    this.showLabel = false,
    this.labelText,
    this.isFavorite = false,
    this.isNegotiable = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ProfileService().addToViewedList(id);
        if (onTap != null) onTap!();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: 250, maxHeight: 250), // Set fixed height for the card
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
                  height: 100, // Changed from 120 to 100
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: images.isNotEmpty
                        ? Hero(
                            tag: 'product-photo-$id',
                            child: CachedNetworkImage(
                              imageUrl: images.first,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.zinc200,
                                child: Icon(Icons.broken_image, color: AppColors.color5),
                              ),
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          )
                        : Container(
                            color: AppColors.zinc200, // Placeholder color
                            child: Center(
                              child: Icon(Icons.image, size: 40, color: AppColors.color5), // Placeholder icon
                            ),
                          ),
                  ),
                ),
                // Pagination dots - показуємо тільки якщо є більше 1 зображення
                if (images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Center(
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
                            // Максимум 3 крапки
                            images.length > 3 ? 3 : images.length,
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
                if (isNegotiable && price == 'Договірна')
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
                        'Договірна',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), // Changed from 8 to 5
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
                    maxLines: 2, // Limit title to 2 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
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
                      GestureDetector(
                        onTap: onFavoriteToggle,
                        child: SizedBox(width: 20, height: 20, child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? const Color(0xFF015873) : const Color(0xFF27272A),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Changed from 8 to 12
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
      ),
    );
  }
} 