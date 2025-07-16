import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/product_card_list_item.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:developer';

class ActiveListingsPage extends StatefulWidget {
  const ActiveListingsPage({Key? key}) : super(key: key);

  @override
  State<ActiveListingsPage> createState() => _ActiveListingsPageState();
}

class _ActiveListingsPageState extends State<ActiveListingsPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  int? _openedActionIndex;
  final Duration _swipeAnimDuration = const Duration(milliseconds: 250);

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

  Future<void> _loadProducts() async {
    if (_currentUserId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _productService.getProducts(
        limit: 100,
        offset: 0,
        // Додаємо фільтр по userId та status
      );
      // Фільтруємо по userId та status == 'active' (якщо поле status є)
      final filtered = products.where((p) => p.userId == _currentUserId && (p.customAttributes?['status'] == 'active' || p.customAttributes?['status'] == null)).toList();
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
      log('Filtered products count:  [32m${_filteredProducts.length} [0m');
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
          padding: const EdgeInsets.only(left: 13, right: 13, top: 24, bottom: 39),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Хедер з іконкою повернення
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Активні',
                    style: TextStyle(
                      color: Color(0xFF161817),
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.20,
                    ),
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
                            ? const Center(child: Text('Немає активних оголошень'))
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final isOpened = _openedActionIndex == index;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _SwipeableCard(
                                      isOpened: isOpened,
                                      onOpen: () => setState(() => _openedActionIndex = index),
                                      onClose: _closeAction,
                                      child: ProductCardListItem(
                                        id: product.id,
                                        title: product.title,
                                        price: product.formattedPrice,
                                        date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                        location: product.location,
                                        images: product.photos,
                                        isFavorite: false, // Можна додати логіку улюбленого
                                        onFavoriteToggle: null,
                                        onTap: () {
                                          // TODO: Перехід до деталей оголошення
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

// SwipeableCard widget
class _SwipeableCard extends StatefulWidget {
  final Widget child;
  final bool isOpened;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  const _SwipeableCard({required this.child, required this.isOpened, required this.onOpen, required this.onClose});

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> {
  double _offset = 0;
  bool _actionVisible = false;
  static const double maxOffset = 80.0; // ширина кнопок
  static const double cardHeight = 104.0;

  @override
  void didUpdateWidget(covariant _SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpened && _actionVisible) {
      setState(() {
        _offset = 0;
        _actionVisible = false;
      });
    }
    if (widget.isOpened && !_actionVisible) {
      setState(() {
        _offset = -maxOffset;
        _actionVisible = true;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      if (_offset < -maxOffset) _offset = -maxOffset;
      if (_offset > 0) _offset = 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_offset < -maxOffset / 2) {
      setState(() {
        _offset = -maxOffset;
        _actionVisible = true;
      });
      widget.onOpen();
    } else {
      setState(() {
        _offset = 0;
        _actionVisible = false;
      });
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight, // Висота картки + бекграунду
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Бекграунд з кнопками
          AnimatedOpacity(
            opacity: _actionVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_actionVisible,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x3F09090B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.all(14),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFAFAFA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(200),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Block/Deactivate
                              widget.onClose();
                            },
                            child: _trySvgOrIcon('assets/icons/slash-circle-01.svg', Icons.block),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFAFAFA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(200),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Delete
                              widget.onClose();
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
          // Основна картка
          Transform.translate(
            offset: Offset(_offset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: SizedBox(
                height: cardHeight,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _trySvgOrIcon(String asset, IconData fallback) {
  try {
    return SvgPicture.asset(
      asset,
      width: 20,
      height: 20,
      colorFilter: const ColorFilter.mode(Color(0xFF27272A), BlendMode.srcIn),
    );
  } catch (e) {
    return Icon(fallback, color: const Color(0xFF27272A), size: 20);
  }
} 