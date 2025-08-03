import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/profile_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewedProductCard extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String? date;
  final String? location;
  final List<String> images;
  final bool isNegotiable;
  final VoidCallback? onTap;

  const ViewedProductCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    this.date,
    this.location,
    required this.images,
    this.isNegotiable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ProfileService().addToViewedList(id);
        if (onTap != null) onTap!();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: const Color(0xFFFAFAFA), // Zinc-50
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Зображення з правильним заокругленням
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 80,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
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
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Договірна',
                        style: const TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFF27272A), // Zinc-800
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      height: 1.40,
                                      letterSpacing: 0.14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                      const SizedBox(width: 12),
                                      Text(
                                        location ?? 'Харків',
                                        style: const TextStyle(
                                          color: Color(0xFF838583),
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          height: 1.30,
                                          letterSpacing: 0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.40,
                              letterSpacing: 0.14,
                            ),
                          ),
                        ],
                      ),
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