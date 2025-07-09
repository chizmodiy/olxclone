import 'package:flutter/material.dart';
import '../widgets/common_header.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/product_card_list_item.dart'; // Import ProductCardListItem

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
  int _currentPage = 0; // Changed to 0 as we'll fetch all viewed IDs first
  String? _sortBy; 
  bool _isGrid = false;
  String? _errorMessage;
  String? _currentUserId;

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

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, color: const Color(0xFF838583), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Пошук',
                          hintStyle: const TextStyle(
                            color: Color(0xFF838583),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        onChanged: (value) {
                          // TODO: Implement search logic here
                        },
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
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _products = [];
                        _currentPage = 0; // Reset to 0 for new fetch
                        _hasMore = true;
                        _errorMessage = null;
                      });
                      await _loadViewedProducts();
                    },
                    child: _products.isEmpty && !_isLoading
                        ? const Center(
                            child: Text('Наразі оголошень немає.'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _products.length + (_hasMore ? 1 : 0), // Add 1 for loading indicator
                            itemBuilder: (context, index) {
                              if (index == _products.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final product = _products[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10), // Space between list items
                                child: ProductCardListItem(
                                  id: product.id, // Pass product ID
                                  title: product.title,
                                  price: NumberFormat.currency(locale: 'uk_UA', symbol: '₴').format(product.priceValue),
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
          ),
        ],
      ),
    );
  }
}