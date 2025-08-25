import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_service.dart';

class ProductCardListItem extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String? date;
  final String? region;
  final List<String> images;
  final bool isFavorite;
  final bool isNegotiable;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProductCardListItem({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    this.date,
    this.region,
    required this.images,
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
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          children: [
            // Зображення
            Stack(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: images.first,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.zinc200,
                            child: const Icon(Icons.broken_image, color: AppColors.color5),
                          ),
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Container(
                          color: AppColors.zinc200,
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: AppColors.color5),
                          ),
                        ),
                ),
                // Мітка "Договірна"
                if (isNegotiable)
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
            // Контент
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Назва та ціна
                    Row(
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
                                  height: 1.40,
                                  letterSpacing: 0.14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  height: 1.30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onFavoriteToggle != null)
                          GestureDetector(
                            onTap: onFavoriteToggle,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isFavorite ? const Color(0xFF015873) : const Color(0xFF27272A),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Дата та локація
                    Row(
                      children: [
                        Text(
                          date ?? '12 Березня 16:00',
                          style: const TextStyle(
                            color: Color(0xFF838583),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.30,
                            letterSpacing: 0.24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            region ?? 'Харків',
                            style: const TextStyle(
                              color: Color(0xFF838583),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.30,
                              letterSpacing: 0.24,
                            ),
                            overflow: TextOverflow.ellipsis,
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

