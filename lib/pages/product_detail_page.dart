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
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height * 0.35; // 35% від висоти екрану

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
          SizedBox(
            width: double.infinity,
            height: size.height,
            child: Stack(
              children: [
                // Image gallery section
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: Container(
                    height: imageHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      children: [
                        // Image PageView
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
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                );
                              },
                            );
                          },
                        ),
                        // Page indicators
                        if (_product!.photos.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20,
                            child: Center(
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
                          ),
                      ],
                    ),
                  ),
                ),
                // Navigation buttons
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).padding.top + 16,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavigationButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildNavigationButton(
                          icon: Icons.share,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функція поділитися буде додана незабаром'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Content section
                Positioned(
                  left: 0,
                  right: 0,
                  top: imageHeight - 20,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 38),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1
                          Container(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date
                                Text(
                                  _product!.formattedDate,
                                  style: const TextStyle(
                                    color: Color(0xFF838583),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.3, // line-height: 15.60px
                                    letterSpacing: 0.24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Title and Price with Favorite button
                                Container(
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(right: 48), // Даємо місце для кнопки
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _product!.title,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                height: 1.5,
                                                letterSpacing: 0.16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _product!.formattedPrice,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 24,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Favorite button
                                      Positioned(
                                        right: 0,
                                        top: 9,
                                        child: GestureDetector(
                                          onTap: () {
                                            // TODO: Implement favorite toggle
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF4F4F5),
                                              borderRadius: BorderRadius.circular(200),
                                              border: Border.all(
                                                color: const Color(0xFFF4F4F5),
                                              ),
                                            ),
                                            child: const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Icon(
                                                Icons.favorite_border,
                                                size: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Categories
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF83DAF5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Мода і стиль',
                                        style: const TextStyle(
                                          color: Color(0xFF015873),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          height: 1.43, // line-height: 20px
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAFAFA),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Жіночий одяг',
                                        style: const TextStyle(
                                          color: Color(0xFF52525B),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          height: 1.43, // line-height: 20px
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40), // Spacing between sections
                          
                          // Section 2
                          Container(
                            // Second section content will go here
                          ),
                          
                          const SizedBox(height: 40), // Spacing between sections
                          
                          // Section 3
                          Container(
                            // Third section content will go here
                          ),
                          
                          const SizedBox(height: 40), // Spacing between sections
                          
                          // Section 4
                          Container(
                            // Fourth section content will go here
                          ),
                          
                          const SizedBox(height: 40), // Spacing between sections
                          
                          // Section 5
                          Container(
                            // Fifth section content will go here
                          ),
                          
                          const SizedBox(height: 40), // Spacing between sections
                          
                          // Section 6
                          Container(
                            // Sixth section content will go here
                          ),
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

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: Color(0xFFE4E4E7),
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
        child: Icon(icon),
      ),
    );
  }
} 