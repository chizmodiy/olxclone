import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/profile_service.dart';

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
  late final CategoryService _categoryService;
  late final ProfileService _profileService;
  int _currentPage = 0;
  Product? _product;
  bool _isLoading = true;
  String? _error;
  String? _categoryName;
  String? _subcategoryName;
  String? _currentUserId;
  bool _isFavorite = false;

  // Мапа категорій
  final Map<String, String> _categories = {
    '066e2754-e51c-4395-9e3f-f78503444704': 'Знайомства',
    '0eb7b6db-e505-4503-8bc0-020914a3ebcf': 'Бізнес та послуги',
    '261d5661-f4c6-408e-b1f3-8d9a04f68081': 'Тварини',
    '2b33ab6e-94b3-4268-b8b8-5c23d7ba2d2b': 'Оренда та прокат',
    '30934dd8-8fb3-4e24-91a4-6cf137bd7412': 'Дім і сад',
    '3d668ce4-969f-49ad-96c2-7152c2184567': 'Робота',
    '63ca90d1-6735-4fff-b469-94f325b99900': 'Авто',
    '7065bc9d-d34f-4394-9a08-e8da1f8c6a98': 'Нерухомість',
    '7515a738-62eb-4a8b-bcfd-872a10a72e25': 'Віддам безкоштовно',
    '85e264dd-3456-42a8-a6ca-6123e2a07d40': 'Житло подобово',
    '90d34cdb-7617-4b17-8106-9c94d802f812': 'Мода і стиль',
    'c785ac08-c2f0-4766-af8d-0b09cb0c3d94': 'Запчастини для транспорту',
    'cce00594-36b9-482b-b21f-43818155de2b': 'Хобі, відпочинок і спорт',
    'cf21cd87-d2e6-45d2-bea3-d68931ca5f97': 'Електроніка',
    'e34417la-a607-4fc3-b6e9-7ad049c1fdc5': 'Допомога',
    'ffa87acb-45fb-42b3-bfc6-00609ec6e879': 'Дитячий світ',
  };

  // Мапа підкатегорій
  final Map<String, String> _subcategories = {
    'women_clothing': 'Жіночий одяг',
    'men_clothing': 'Чоловічий одяг',
    'phones': 'Телефони',
    'computers': 'Комп\'ютери',
    'furniture': 'Меблі',
    // Додайте інші підкатегорії за потреби
  };

  String _getCategoryName(String categoryId) {
    return _categories[categoryId] ?? 'Інше';
  }

  String _getSubcategoryName(String subcategoryId) {
    return _subcategories[subcategoryId] ?? 'Інше';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productService = ProductService();
    _categoryService = CategoryService();
    _profileService = ProfileService();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadProduct();
    _loadFavoriteStatus();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() => _isLoading = true);
      final product = await _productService.getProductById(widget.productId);
      final categoryName = await _categoryService.getCategoryNameCached(product.categoryId);
      final subcategoryName = await _categoryService.getSubcategoryNameCached(product.subcategoryId);
      
      setState(() {
        _product = product;
        _categoryName = categoryName;
        _subcategoryName = subcategoryName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (_currentUserId == null) return;
    try {
      final favoriteIds = await _profileService.getFavoriteProductIds();
      setState(() {
        _isFavorite = favoriteIds.contains(widget.productId);
      });
    } catch (e) {
      print('Error loading favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      print('User not logged in. Cannot toggle favorite.');
      return;
    }

    try {
      if (_isFavorite) {
        await _profileService.removeFavoriteProduct(widget.productId);
      } else {
        await _profileService.addFavoriteProduct(widget.productId);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      print('Error toggling favorite: $e');
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
                                          onTap: _toggleFavorite,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF4F4F5),
                                              borderRadius: BorderRadius.circular(200),
                                              border: Border.all(
                                                color: const Color(0xFFF4F4F5),
                                              ),
                                            ),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Icon(
                                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                                size: 20,
                                                color: _isFavorite ? const Color(0xFF015873) : Colors.black,
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
                                        _categoryName ?? 'Інше',
                                        style: const TextStyle(
                                          color: Color(0xFF015873),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          height: 1.43,
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
                                        _subcategoryName ?? 'Інше',
                                        style: const TextStyle(
                                          color: Color(0xFF52525B),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                
                                // Description section
                                Container(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Опис',
                                        style: TextStyle(
                                          color: Color(0xFF52525B),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                          letterSpacing: 0.14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _product!.description ?? 'Опис відсутній',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          letterSpacing: 0.16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                
                                // Location section
                                Container(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Location header with icon
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            child: const Icon(
                                              Icons.location_on_outlined,
                                              color: Color(0xFFA1A1AA), // Zinc-400
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            _product!.location,
                                            style: const TextStyle(
                                              color: Color(0xFF101828), // Gray-900
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w500,
                                              height: 1.5,
                                              letterSpacing: 0.16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Map placeholder
                                      Container(
                                        width: double.infinity,
                                        height: 362,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE4E4E7), // Zinc-200
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Map controls
                                            Positioned(
                                              right: 16,
                                              top: 190,
                                              child: Column(
                                                children: [
                                                  // Current location button
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(200),
                                                      border: Border.all(
                                                        color: const Color(0xFFE4E4E7), // Zinc-200
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFF101828).withOpacity(0.05),
                                                          blurRadius: 2,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.gps_fixed,
                                                      size: 20,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Zoom controls
                                                  Column(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(200),
                                                          border: Border.all(
                                                            color: const Color(0xFFE4E4E7), // Zinc-200
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xFF101828).withOpacity(0.05),
                                                              blurRadius: 2,
                                                              offset: const Offset(0, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.add,
                                                          size: 20,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(200),
                                                          border: Border.all(
                                                            color: const Color(0xFFE4E4E7), // Zinc-200
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xFF101828).withOpacity(0.05),
                                                              blurRadius: 2,
                                                              offset: const Offset(0, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.remove,
                                                          size: 20,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Location pin
                                            const Positioned(
                                              left: 267,
                                              top: 113,
                                              child: Icon(
                                                Icons.location_on,
                                                size: 32,
                                                color: Color(0xFF015873), // Primary color
                                              ),
                                            ),
                                            // Map attribution
                                            Positioned(
                                              left: 13,
                                              bottom: 13,
                                              child: Container(
                                                width: 111,
                                                height: 25,
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                
                                // User section
                                Container(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Користувач',
                                            style: TextStyle(
                                              color: Color(0xFF52525B),
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                              letterSpacing: 0.14,
                                            ),
                                          ),
                                          // Report button
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(200),
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                // TODO: Implement report functionality
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Функція скарги буде додана незабаром'),
                                                  ),
                                                );
                                              },
                                              child: const Icon(
                                                Icons.flag_outlined,
                                                size: 20,
                                                color: Color(0xFF27272A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // User info
                                      Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(240),
                                              color: const Color(0xFFE4E4E7), // Zinc-200
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              size: 24,
                                              color: Color(0xFF71717A), // Zinc-500
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // User name
                                          Expanded(
                                            child: FutureBuilder<UserProfile?>(
                                              future: _profileService.getUser(_product!.userId),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Text(
                                                    'Завантаження...',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w600,
                                                      height: 1.5,
                                                      letterSpacing: 0.16,
                                                    ),
                                                  );
                                                }
                                                
                                                final user = snapshot.data;
                                                return Text(
                                                  user?.fullName ?? 'Користувач',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.5,
                                                    letterSpacing: 0.16,
                                                  ),
                                                );
                                              },
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