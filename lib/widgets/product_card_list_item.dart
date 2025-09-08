import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_service.dart';

class ProductCardListItem extends StatefulWidget {
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
  State<ProductCardListItem> createState() => _ProductCardListItemState();
}

class _ProductCardListItemState extends State<ProductCardListItem> {
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
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.zinc200,
                                child: const Icon(Icons.broken_image, color: AppColors.color5),
                              ),
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.zinc200,
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: AppColors.color5),
                          ),
                        ),
                ),
                // Індикатор пагінації (до 3 крапок)
                if (widget.images.length > 1)
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.2),
                          backgroundBlendMode: BlendMode.overlay,
                        ),
                        child: Builder(
                          builder: (context) {
                            final total = widget.images.length;
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
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
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
                // Мітка "Договірна"
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
                                widget.title,
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
                                widget.price,
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
                    // Дата та локація
                    Row(
                      children: [
                        Text(
                          widget.date ?? '12 Березня 16:00',
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
                            widget.region ?? 'Харків',
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

