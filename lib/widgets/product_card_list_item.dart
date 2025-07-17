import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Assuming AppColors is defined here

class ProductCardListItem extends StatelessWidget {
  final String id; // Add this line
  final String title;
  final String price;
  final String? date;
  final String? location;
  final List<String> images;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap; // Add this line

  const ProductCardListItem({
    super.key,
    required this.id, // Add this line
    required this.title,
    required this.price,
    this.date,
    this.location,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
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
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                  height: 1.4,
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
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onFavoriteToggle != null)
                          GestureDetector(
                            onTap: onFavoriteToggle,
                            child: const _HeartRoundedIcon(),
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

// Додаю кастомний Widget для сердечка
class _HeartRoundedIcon extends StatelessWidget {
  const _HeartRoundedIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _HeartRoundedPainter(),
      ),
    );
  }
}

class _HeartRoundedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF015873)
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