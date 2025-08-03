import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/common_header.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/viewed_product_card.dart'; // Import ProductCardListItem
import 'dart:async'; // Import Timer
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ViewedPage extends StatelessWidget {
  const ViewedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonHeader(),
      body: Padding(
        padding: EdgeInsets.only(top: 20, bottom: 8),
        child: ViewedContent(),
      ),
    );
  }
}

class ViewedContent extends StatefulWidget {
  const ViewedContent({super.key});

  @override
  State<ViewedContent> createState() => _ViewedContentState();
}

class _ViewedContentState extends State<ViewedContent> {
  final ProductService _productService = ProductService();
  final ProfileService _profileService = ProfileService();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _currentPage = 0; // Changed to 0 as we'll fetch all viewed IDs first
  String? _sortBy; 
  bool _isGrid = false;
  String? _errorMessage;
  String? _currentUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadViewedProducts(); // Call new method to load viewed products
    _scrollController.addListener(_onScroll);
    

  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadViewedProducts() async {
    if (_isLoading) return; // Removed _hasMore check here as we'll get all IDs at once

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final viewedProductIds = await _profileService.getViewedList();
      print('Debug: Found ${viewedProductIds.length} viewed product IDs: $viewedProductIds');
      
      if (viewedProductIds.isEmpty) {
        print('Debug: No viewed products found');
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      // Fetch product details for each ID
      final products = await _productService.getProductsByIds(viewedProductIds);
      print('Debug: Loaded ${products.length} products from ${viewedProductIds.length} IDs');

      // Фільтруємо тільки активні оголошення
      final activeProducts = products.where((p) => p.status == 'active' || p.status == null).toList();

      setState(() {
        _products = activeProducts; // Directly assign as we're not paginating here based on viewed IDs
        _isLoading = false;
        _hasMore = false; // No more pages, all loaded at once
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error loading viewed products: $_errorMessage');
    }
  }

  void _onScroll() {
    // No pagination for viewed products, so no need to load more on scroll
  }

  void _onSortChanged(String? newSortBy) {
    // Sorting logic can be implemented here if needed for viewed list
    setState(() {
      if (_sortBy == 'price_asc') {
        _sortBy = 'price_desc';
      } else if (_sortBy == 'price_desc') {
        _sortBy = null;
      } else {
        _sortBy = 'price_asc';
      }
      // Re-sort existing products or reload if sorting needs backend support
      _products = []; // Clear for re-fetch or re-sort
      _loadViewedProducts(); // Reload with new sort preference
    });
  }

  void _toggleView() {
    setState(() {
      _isGrid = !_isGrid;
      _products = []; // Clear for re-fetch or re-render based on view type
      _loadViewedProducts();
    });
  }

  void _onSearchChanged(String value) {
    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer!.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = value;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    final filteredProducts = _searchQuery.isEmpty
        ? _products
        : _products.where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: [
          // Title and buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Переглянуті', // Changed title
                style: TextStyle(
                  color: Color(0xFF161817),
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
          // Показуємо пошук тільки для авторизованих користувачів
          if (_currentUserId != null) ...[
            const SizedBox(height: 20),
            Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, color: const Color(0xFF838583), size: 20),
                      SizedBox(width: 8),
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
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Text('Помилка завантаження товарів: $_errorMessage'),
                  )
                : _currentUserId == null
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
                                    // Featured icon with book
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
                                          'assets/icons/book-open-01.svg',
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
                                          'Історія переглядів',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.heading1Semibold.copyWith(
                                            color: Colors.black,
                                            fontSize: 24,
                                            height: 28.8 / 24,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Увійдіть або створіть профіль, щоб бачити історію переглянутих товарів.',
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
                    : filteredProducts.isEmpty
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
                    : ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Padding(
                                padding: const EdgeInsets.only(bottom: 10), // Space between list items
                                child: ViewedProductCard(
                                  id: product.id,
                                  title: product.title,
                                  price: product.formattedPrice,
                                  date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                  location: product.location,
                                  images: product.photos,
                                  isNegotiable: product.isNegotiable,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      '/product-detail',
                                      arguments: {'id': product.id},
                                    );
                                  },
                                ),
                              );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}