import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Assuming AppColors is defined here
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_service.dart';

class ProductCardListItem extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String? date;
  final String? location;
  final List<String> images;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProductCardListItem({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    this.date,
    this.location,
    required this.images,
    this.isFavorite = false,
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
                        if (onFavoriteToggle != null)
                          GestureDetector(
                            onTap: onFavoriteToggle,
                            child: _HeartRoundedIcon(isFavorite: isFavorite),
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

// Додаю кастомний Widget для сердечка
class _HeartRoundedIcon extends StatelessWidget {
  final bool isFavorite;
  
  const _HeartRoundedIcon({super.key, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _HeartRoundedPainter(isFavorite: isFavorite),
      ),
    );
  }
}

class _HeartRoundedPainter extends CustomPainter {
  final bool isFavorite;
  
  const _HeartRoundedPainter({required this.isFavorite});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isFavorite ? const Color(0xFF015873) : const Color(0xFF838583)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width * 0.6713, size.height * 0.125); // 13.4259, 2.5
    path.cubicTo(
      size.width * 0.8181, size.height * 0.125, // 16.3611, 2.5
      size.width * 0.9167, size.height * 0.264, // 18.3334, 5.29375
      size.width * 0.9167, size.height * 0.395, // 18.3334, 7.9
    );
    path.cubicTo(
      size.width * 0.9167, size.height * 0.6589, // 18.3334, 13.1781
      size.width * 0.5074, size.height * 0.875, // 10.1482, 17.5
      size.width * 0.5, size.height * 0.875, // 10, 17.5
    );
    path.cubicTo(
      size.width * 0.4926, size.height * 0.875, // 9.85187, 17.5
      size.width * 0.0833, size.height * 0.6589, // 1.66669, 13.1781
      size.width * 0.0833, size.height * 0.395, // 1.66669, 7.9
    );
    path.cubicTo(
      size.width * 0.0833, size.height * 0.264, // 1.66669, 5.29375
      size.width * 0.1819, size.height * 0.125, // 3.63891, 2.5
      size.width * 0.3287, size.height * 0.125, // 6.57409, 2.5
    );
    path.cubicTo(
      size.width * 0.4129, size.height * 0.125, // 8.25928, 2.5
      size.width * 0.4681, size.height * 0.1766, // 9.36113, 3.35312
      size.width * 0.5, size.height * 0.2052, // 10, 4.10312
    );
    path.cubicTo(
      size.width * 0.5319, size.height * 0.1766, // 10.6389, 3.35312
      size.width * 0.5871, size.height * 0.125, // 11.7408, 2.5
      size.width * 0.6713, size.height * 0.125, // 13.4259, 2.5
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 

 