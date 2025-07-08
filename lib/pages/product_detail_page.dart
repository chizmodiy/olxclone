import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final PageController _pageController;
  late final ProductService _productService;
  int _currentPage = 0;
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productService = ProductService();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() => _isLoading = true);
      final product = await _productService.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Помилка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Спробувати знову'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Scaffold(
        body: Center(
          child: Text('Товар не знайдено'),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 844,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 390,
                    height: 268,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _product!.photos.length,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _product!.photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                );
                              },
                            );
                          },
                        ),
                        if (_product!.photos.length > 1)
                          Positioned(
                            left: 169,
                            top: 203,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: ShapeDecoration(
                                color: Colors.black.withOpacity(0.25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(_product!.photos.length, (index) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: ShapeDecoration(
                                      color: _currentPage == index 
                                        ? const Color(0xFF015873) 
                                        : Colors.white.withOpacity(0.25),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Navigation buttons
                Positioned(
                  left: 0,
                  top: 71,
                  child: Container(
                    width: 390,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFE4E4E7),
                                ),
                                borderRadius: BorderRadius.circular(200),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x0C101828),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                )
                              ],
                            ),
                            child: const Icon(Icons.arrow_back),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement share functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функція поділитися буде додана незабаром'),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFE4E4E7),
                                ),
                                borderRadius: BorderRadius.circular(200),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x0C101828),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                )
                              ],
                            ),
                            child: const Icon(Icons.share),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content section
                Positioned(
                  left: 0,
                  top: 235,
                  child: Container(
                    width: 390,
                    height: 609,
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 14,
                      right: 14,
                      bottom: 56,
                    ),
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO: Add product details content here
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 