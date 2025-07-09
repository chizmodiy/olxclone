import 'package:flutter/material.dart';
import '../widgets/common_header.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/product_card_list_item.dart'; // Import ProductCardListItem
import 'dart:async'; // Import Timer

class ViewedPage extends StatelessWidget {
  const ViewedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonHeader(),
      body: Padding(
        padding: EdgeInsets.only(top: 20),
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
      
      if (viewedProductIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      // Fetch product details for each ID
      // This might need a new method in ProductService to get multiple products by IDs
      // For now, let's assume getProducts can take a list of IDs or we iterate
      // For simplicity, let's modify getProducts temporarily or add a new one
      final products = await _productService.getProductsByIds(viewedProductIds);

      setState(() {
        _products = products; // Directly assign as we're not paginating here based on viewed IDs
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
          const SizedBox(height: 20),
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Text('Помилка завантаження товарів: $_errorMessage'),
                  )
                : filteredProducts.isEmpty
                    ? const Center(child: Text('Немає переглянутих товарів'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Padding(
                                padding: const EdgeInsets.only(bottom: 10), // Space between list items
                                child: ProductCardListItem(
                                  id: product.id, // Pass product ID
                                  title: product.title,
                                  price: product.formattedPrice,
                                  date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                  location: product.location,
                                  images: product.photos,
                                  isFavorite: false, // No favorite logic
                                  onFavoriteToggle: () {
                                    // No-op for viewed products
                                  },
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