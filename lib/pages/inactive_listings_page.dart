import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/product_card_list_item.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:developer';
import '../services/listing_service.dart';
import '../widgets/common_header.dart';
import '../models/listing.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class InactiveListingsPage extends StatefulWidget {
  const InactiveListingsPage({super.key});

  @override
  State<InactiveListingsPage> createState() => _InactiveListingsPageState();
}

class _InactiveListingsPageState extends State<InactiveListingsPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  int? _openedActionIndex;
  final Duration _swipeAnimDuration = const Duration(milliseconds: 250);
  final ListingService _listingService = ListingService(Supabase.instance.client);
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
    

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Оновлюємо список при поверненні на сторінку
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_currentUserId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _productService.getUserProducts(_currentUserId!);
      // Фільтруємо по status == 'inactive'
      final filtered = products.where((p) => p.status == 'inactive').toList();
      setState(() {
        _products = filtered;
        _filteredProducts = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = query.isEmpty
          ? _products
          : _products.where((p) => p.title.toLowerCase().contains(query)).toList();
      log('Filtered products count:  [32m[32m${_filteredProducts.length} [0m');
    });
  }

  void _closeAction() {
    setState(() {
      _openedActionIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 13, right: 13, top: 24, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Хедер з іконкою повернення та кнопкою оновлення
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Неактивні',
                      style: TextStyle(
                        color: Color(0xFF161817),
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
                    onPressed: () => _loadProducts(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Пошук
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, color: Color(0xFF838583), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Пошук',
                          hintStyle: TextStyle(
                            color: Color(0xFF838583),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            letterSpacing: 0.16,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Список оголошень
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text('Помилка: $_errorMessage'))
                        : _filteredProducts.isEmpty
                            ? const Center(child: Text('Немає неактивних оголошень'))
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final isOpened = _openedActionIndex == index;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _InactiveSwipeableCard(
                                      isOpened: isOpened,
                                      onOpen: () => setState(() => _openedActionIndex = index),
                                      onClose: _closeAction,
                                      productId: product.id,
                                      productTitle: product.title,
                                      onRemove: () {
                                        setState(() {
                                          _products.removeWhere((p) => p.id == product.id);
                                          _filteredProducts.removeWhere((p) => p.id == product.id);
                                        });
                                      },
                                      listingService: _listingService,
                                      child: ProductCardListItem(
                                        id: product.id,
                                        title: product.title,
                                        price: product.formattedPrice,
                                        images: product.photos,
                                        isNegotiable: product.isNegotiable,
                                        
                                        onTap: () async {
                                          await Navigator.of(context).pushNamed(
                                            '/product-detail',
                                            arguments: {'id': product.id},
                                          );
                                          // Оновлюємо список при поверненні
                                          _loadProducts();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SwipeableCard для неактивних оголошень
class _InactiveSwipeableCard extends StatefulWidget {
  final Widget child;
  final bool isOpened;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final String productId;
  final String productTitle;
  final VoidCallback? onRemove;
  final ListingService listingService;
  const _InactiveSwipeableCard({
    required this.child,
    required this.isOpened,
    required this.onOpen,
    required this.onClose,
    required this.productId,
    required this.productTitle,
    required this.listingService,
    this.onRemove,
  });

  @override
  State<_InactiveSwipeableCard> createState() => _InactiveSwipeableCardState();
}

class _InactiveSwipeableCardState extends State<_InactiveSwipeableCard> {
  bool _actionVisible = false;
  static const double overlayWidth = 364.0;
  static const double cardHeight = 105.0;

  @override
  void didUpdateWidget(covariant _InactiveSwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpened && _actionVisible) {
      setState(() {
        _actionVisible = false;
      });
    }
    if (widget.isOpened && !_actionVisible) {
      setState(() {
        _actionVisible = true;
      });
    }
  }

  double _dragDx = 0;
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDx += details.delta.dx;
      if (_dragDx < -40) {
        _actionVisible = true;
        widget.onOpen();
        _dragDx = 0;
      } else if (_dragDx > 40) {
        _actionVisible = false;
        widget.onClose();
        _dragDx = 0;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          return SizedBox(
            height: cardHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Основна картка (нерухома)
                SizedBox(
                  height: cardHeight,
                  child: widget.child,
                ),
                // Overlay: фон + кнопки
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  right: _actionVisible ? 0 : -width,
                  top: 0,
                  width: width,
                  height: cardHeight,
                  child: Container(
                    width: width,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: const Color(0x3F09090B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Container(
                          height: cardHeight,
                          width: width * 0.4, // 40% від ширини екрану
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(200),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    await widget.listingService.updateListingStatus(widget.productId, 'active');
                                    setState(() {
                                      _actionVisible = false;
                                      widget.onClose();
                                    });
                                    if (widget.onRemove != null) widget.onRemove!();
                                  },
                                  child: const _CheckIcon(),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(200),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirmed = await showModalBottomSheet<bool>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => _DeleteConfirmModal(
                                        title: widget.productTitle,
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await widget.listingService.deleteListing(widget.productId);
                                      setState(() {
                                        _actionVisible = false;
                                        widget.onClose();
                                      });
                                      if (widget.onRemove != null) widget.onRemove!();
                                    }
                                  },
                                  child: _trySvgOrIcon('assets/icons/trash-01.svg', Icons.delete_outline),
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
          );
        },
      ),
    );
  }
}

Widget _trySvgOrIcon(String asset, IconData fallback, {Color color = const Color(0xFF27272A)}) {
  try {
    return SvgPicture.asset(
      asset,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  } catch (e) {
    return Icon(fallback, color: color, size: 20);
  }
}

// Додаю кастомний Widget для галочки
class _CheckIcon extends StatelessWidget {
  const _CheckIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CheckPainter(),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF27272A)
      ..strokeWidth = 1.66667
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    path.moveTo(size.width * 0.8333, size.height * 0.25); // 16.6668, 5
    path.lineTo(size.width * 0.375, size.height * 0.7083); // 7.5, 14.1667
    path.lineTo(size.width * 0.1667, size.height * 0.5); // 3.3335, 10
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Модальне вікно підтвердження видалення (копія)
class _DeleteConfirmModal extends StatelessWidget {
  final String title;
  const _DeleteConfirmModal({required this.title});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: const EdgeInsets.only(top: 8, bottom: 36, left: 13, right: 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Видалити оголошення',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ви впевнені що бажаєте видалити "$title" з ваших оголошень?',
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0.16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF27272A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015873),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(200),
                  side: const BorderSide(color: Color(0xFF015873)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Видалити',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE4E4E7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(200),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Скасувати',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 