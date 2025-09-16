import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/profile_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatefulWidget {
  final String id;
  final String title;
  final String price;
  final bool isFree;
  final String date;
  final String? region;
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
    this.region,
    required this.images,
    this.showLabel = false,
    this.labelText,
    this.isFavorite = false,
    this.isNegotiable = false,
    this.onFavoriteToggle,
    this.onTap,
    this.isFree = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ProfileService().addToViewedList(widget.id);
        if (widget.onTap != null) widget.onTap!();
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
                    child: widget.images.isNotEmpty
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: widget.images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imageUrl = widget.images[index];
                              final image = CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration(milliseconds: 0),
                                fadeOutDuration: Duration(milliseconds: 0),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.zinc200,
                                  child: Icon(Icons.broken_image, color: AppColors.color5),
                                ),
                                placeholder: (context, url) => Container(color: AppColors.zinc200),
                              );
                              if (index == 0) {
                                return Hero(
                                  tag: 'product-photo-${widget.id}',
                                  child: image,
                                );
                              }
                              return image;
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
                // Pagination dots - показуємо тільки якщо є більше 1 зображення
                if (widget.images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.2),
                          backgroundBlendMode: BlendMode.overlay,
                        ),
                        child: Builder(
                          builder: (context) {
                            final total = widget.images.length;
                            // Вікно до 3 крапок навколо поточної
                            int start = 0;
                            int count = total;
                            if (total > 3) {
                              if (_currentImageIndex <= 0) {
                                start = 0;
                              } else if (_currentImageIndex >= total - 1) {
                                start = total - 3;
                              } else {
                                start = _currentImageIndex - 1;
                              }
                              count = 3;
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                count,
                                (i) {
                                  final dotIndex = start + i;
                                  final isActive = dotIndex == _currentImageIndex;
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? AppColors.primaryColor
                                          : Colors.white.withValues(alpha: 0.25),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (widget.showLabel && widget.labelText != null)
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
                        widget.labelText!,
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
                if (widget.isFree)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Безкоштовно',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                if (widget.isNegotiable)
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
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isFree)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
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
                        ),
                        GestureDetector(
                          onTap: widget.onFavoriteToggle,
                          child: Icon(
                            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: widget.isFavorite ? const Color(0xFF015873) : const Color(0xFF27272A),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      widget.title,
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
                  if (widget.isFree)
                    const Text(
                      'Безкоштовно',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 20,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.price,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (widget.onFavoriteToggle != null)
                          GestureDetector(
                            onTap: widget.onFavoriteToggle,
                            child: Icon(
                              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: widget.isFavorite ? const Color(0xFF015873) : const Color(0xFF27272A),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.date,
                        style: const TextStyle(
                          color: Color(0xFF838583),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          letterSpacing: 0.24,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.region ?? '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF838583),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.3,
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
          ],
        ),
      ),
    );
  }
} 