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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonHeader(),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: ViewedContent(key: key),
      ),
    );
  }
}

class ViewedContent extends StatefulWidget {
  const ViewedContent({super.key});

  @override
  State<ViewedContent> createState() => ViewedContentState();
}

class ViewedContentState extends State<ViewedContent> {
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
      
      
      if (viewedProductIds.isEmpty) {
        
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      // Fetch product details for each ID
      final products = await _productService.getProductsByIds(viewedProductIds);
      

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
      
    }
  }

  void _onScroll() {
    // No pagination for viewed products, so no need to load more on scroll
  }

  // Метод для оновлення списку проглянутих оголошень
  void refreshProducts() {
    setState(() {
      _products.clear();
      _errorMessage = null;
    });
    _loadViewedProducts();
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
                              color: const Color(0xFF838583),
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
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _products = [];
                        _errorMessage = null;
                      });
                      await _loadViewedProducts();
                    },
                    child: filteredProducts.isEmpty && !_isLoading
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
                            padding: const EdgeInsets.only(top: 0),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                              return ViewedProductCard(
                                  id: product.id,
                                  title: product.title,
                                  price: product.formattedPrice,
                            date: DateFormat('dd MMMM HH:mm').format(product.createdAt),
                                  region: product.region,
                            images: product.images,
                                  isNegotiable: product.isNegotiable,
                                  onTap: () async {
                                    await Navigator.of(context).pushNamed(
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
    );
  }
}