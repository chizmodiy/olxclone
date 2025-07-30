import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/common_header.dart';
import '../widgets/product_card.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../pages/home_page.dart'; // Import ViewMode enum
import '../widgets/product_card_list_item.dart'; // Import ProductCardListItem
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonHeader(),
      body: Padding(
        padding: EdgeInsets.only(top: 20),
        child: FavoritesContent(),
      ),
    );
  }
}

class FavoritesContent extends StatefulWidget {
  const FavoritesContent({super.key});

  @override
  State<FavoritesContent> createState() => _FavoritesContentState();
}

class _FavoritesContentState extends State<FavoritesContent> {
  final ProductService _productService = ProductService();
  final ProfileService _profileService = ProfileService();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _sortBy; // Can be 'price_asc', 'price_desc', or null (for default by date)
  ViewMode _currentViewMode = ViewMode.grid4; // Changed from _isGrid
  String? _errorMessage;
  String? _currentUserId;
  Set<String> _favoriteProductIds = {};
  bool _isViewDropdownOpen = false; // New state variable

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadFavorites().then((_) {
      _loadProducts();
    });
    

    // _scrollController.addListener(_onScroll); // _onScroll is no longer needed as we load all favorites at once
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    // We will always load all favorite products at once, so no pagination needed here
    // However, we still use _isLoading to prevent multiple concurrent fetches
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If favorite IDs are not loaded yet, wait for them. This might happen if _loadProducts is called by _onScroll before _loadFavorites completes.
      if (_favoriteProductIds.isEmpty) {
        await _loadFavorites();
      }

      final products = await _productService.getProductsByIds(
        _favoriteProductIds.toList(),
      );

      setState(() {
        _products = products; // Replace all products with favorites
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error loading favorite products: $_errorMessage');
    }
  }

  Future<void> _loadFavorites() async {
    if (_currentUserId == null) return;
    try {
      final favoriteIds = await _profileService.getFavoriteProductIds();
      setState(() {
        _favoriteProductIds = favoriteIds;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    if (_currentUserId == null) {
      print('User not logged in. Cannot toggle favorite.');
      return;
    }

    try {
      if (_favoriteProductIds.contains(product.id)) {
        await _profileService.removeFavoriteProduct(product.id);
        setState(() {
          _favoriteProductIds.remove(product.id);
        });
      } else {
        await _profileService.addFavoriteProduct(product.id);
        setState(() {
          _favoriteProductIds.add(product.id);
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _onScroll() {
    // This method is no longer needed as all favorite products are loaded at once.
    // Keep it empty or remove if not used elsewhere.
  }

  void _onSortChanged(String? newSortBy) {
    setState(() {
      if (_sortBy == 'price_asc') {
        _sortBy = 'price_desc';
      } else if (_sortBy == 'price_desc') {
        _sortBy = null; // Back to default (created_at desc)
      } else {
        _sortBy = 'price_asc';
      }
      // Sort the already loaded products instead of reloading
      _products.sort((a, b) {
        if (_sortBy == 'price_asc') {
          return a.priceValue.compareTo(b.priceValue);
        } else if (_sortBy == 'price_desc') {
          return b.priceValue.compareTo(a.priceValue);
        } else {
          // Default sort by date_created desc
          return b.createdAt.compareTo(a.createdAt);
        }
      });
    });
    // _loadProducts(); // No need to reload, just sort existing products
  }

  void _toggleView() {
    setState(() {
      _isViewDropdownOpen = !_isViewDropdownOpen;
    });
  }

  void _onViewModeSelected(ViewMode mode) {
    setState(() {
      _currentViewMode = mode;
      _isViewDropdownOpen = false; // Close dropdown after selection
      // No need to clear products and reload, as favorites are loaded all at once
      // and just the view changes. However, if product display logic depends on it,
      // a slight modification here might be needed. For now, it just changes view.
    });
  }

  // Helper method to build the dropdown menu for view modes
  Widget _buildViewModeDropdown() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(16, 24, 40, 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color.fromRGBO(16, 24, 40, 0.03),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDropdownMenuItem('Сітка з 4 карток', ViewMode.grid4, Icons.grid_view_outlined),
          _buildDropdownMenuItem('Сітка з 8 карток', ViewMode.grid8, Icons.grid_view_outlined), // Added this line
          _buildDropdownMenuItem('Список', ViewMode.list, Icons.view_list_outlined),
        ],
      ),
    );
  }

  // Helper method to build individual dropdown menu items
  Widget _buildDropdownMenuItem(String text, ViewMode mode, IconData icon) {
    final bool isSelected = _currentViewMode == mode;
    return GestureDetector(
      onTap: () => _onViewModeSelected(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: isSelected ? const Color(0xFFFAFAFA) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF101828), size: 20), // Gray-900
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: const Color(0xFF101828), // Gray-900
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.5,
                    letterSpacing: isSelected ? 0.16 : 0,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, size: 20, color: const Color(0xFF015873)), // Primary color
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            children: [
              // Title and buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Обране',
                    style: TextStyle(
                      color: Color(0xFF161817),
                      fontSize: 28,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _toggleView,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                            boxShadow: _isViewDropdownOpen
                                ? [
                                    BoxShadow(
                                      color: const Color.fromRGBO(16, 24, 40, 0.10),
                                      offset: const Offset(0, 1),
                                      blurRadius: 0,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            _currentViewMode == ViewMode.list ? Icons.view_list : Icons.grid_view, // Always show current view mode icon
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _errorMessage != null
                    ? Center(
                        child: Text('Помилка завантаження товарів: $_errorMessage'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _products = [];
                            _errorMessage = null;
                          });
                          await _loadProducts();
                        },
                        child: _currentUserId == null
                            ? Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Content
                                        Column(
                                          children: [
                                            // Featured icon with heart
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: AppColors.zinc100,
                                                borderRadius: BorderRadius.circular(28),
                                                border: Border.all(
                                                  color: AppColors.zinc50,
                                                  width: 8,
                                                ),
                                              ),
                                              child: Center(
                                                child: SvgPicture.asset(
                                                  'assets/icons/heart-rounded.svg',
                                                  width: 24,
                                                  height: 24,
                                                  colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            // Text content
                                            Column(
                                              children: [
                                                Text(
                                                  'Зберігайте тут',
                                                  textAlign: TextAlign.center,
                                                  style: AppTextStyles.heading1Semibold.copyWith(
                                                    color: Colors.black,
                                                    fontSize: 24,
                                                    height: 28.8 / 24,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Увійдіть або створіть профіль, щоб зберігати оголошення та пошукові запити.',
                                                  textAlign: TextAlign.center,
                                                  style: AppTextStyles.body1Regular.copyWith(
                                                    color: AppColors.color7,
                                                    height: 22.4 / 16,
                                                    letterSpacing: 0.16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 40),
                                        // Buttons
                                        Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pushNamed('/auth');
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(200),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                  elevation: 0,
                                                  shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                                                ),
                                                child: Text(
                                                  'Увійти',
                                                  style: AppTextStyles.body1Medium.copyWith(
                                                    color: Colors.white,
                                                    letterSpacing: 0.16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pushNamed('/auth');
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.black,
                                                  side: const BorderSide(color: AppColors.zinc200, width: 1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(200),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                  elevation: 0,
                                                  shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                                                ),
                                                child: Text(
                                                  'Створити акаунт',
                                                  style: AppTextStyles.body1Medium.copyWith(
                                                    color: Colors.black,
                                                    letterSpacing: 0.16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              )
                            : _products.isEmpty && !_isLoading
                                ? Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(top: 40),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              child: Stack(
                                                children: [
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    child: Container(
                                                      width: 52,
                                                      height: 52,
                                                      decoration: const ShapeDecoration(
                                                        color: Color(0xFFFAFAFA),
                                                        shape: OvalBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  const Positioned(
                                                    left: 14,
                                                    top: 14,
                                                    child: Icon(
                                                      Icons.list,
                                                      size: 24,
                                                      color: Color(0xFF52525B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                              width: double.infinity,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: const Text(
                                                      'Список пустий',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Color(0xFF667084),
                                                        fontSize: 16,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w400,
                                                        height: 1.40,
                                                        letterSpacing: 0.16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  )
                            : _currentViewMode == ViewMode.list
                                ? ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(top: 0),
                                    itemCount: _products.length, // No more _hasMore check needed
                                    itemBuilder: (context, index) {
                                      // if (index == _products.length) {
                                      //   return const Center(child: CircularProgressIndicator());
                                      // }
                                      final product = _products[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: ProductCardListItem(
                                          id: product.id, // Pass product ID
                                          title: product.title,
                                          price: product.isNegotiable
                                              ? 'Договірна'
                                              : NumberFormat.currency(locale: 'uk_UA', symbol:
                                              '₴').format(product.priceValue),
                                          date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                          location: product.location,
                                          images: product.photos,
                                          isFavorite: _favoriteProductIds.contains(product.id),
                                          onFavoriteToggle: () => _toggleFavorite(product),
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              '/product-detail',
                                              arguments: {'id': product.id},
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  )
                                : GridView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(top: 0),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _currentViewMode == ViewMode.grid8 ? 4 : 2, // Updated this line
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: 250,
                                    ),
                                    itemCount: _products.length, // No more _hasMore check needed
                                    itemBuilder: (context, index) {
                                      // if (index == _products.length) {
                                      //   return const Center(child: CircularProgressIndicator());
                                      // }
                                      final product = _products[index];
                                      return ProductCard(
                                        id: product.id, // Pass product ID
                                        title: product.title,
                                        price: product.formattedPrice,
                                        date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                        location: product.location,
                                        images: product.images,
                                        isFavorite: _favoriteProductIds.contains(product.id),
                                        onFavoriteToggle: () => _toggleFavorite(product),
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            '/product-detail',
                                            arguments: {'id': product.id},
                                          );
                                        },
                                      );
                                    },
                                  ),
                  ),
          ),
        ],
      ),
        ),
        if (_isViewDropdownOpen)
          Positioned(
            top: 72, // 8px below the button
            right: 13, // Aligned with the right padding
            child: _buildViewModeDropdown(),
          ),
      ],
    );
  }
}