import 'package:flutter/material.dart';
import '../widgets/common_header.dart';
import '../widgets/product_card.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';

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
  bool _isGrid = true;
  String? _errorMessage;
  String? _currentUserId;
  Set<String> _favoriteProductIds = {};

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
      _isGrid = !_isGrid;
      // No need to clear products and reload, just change view
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
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isGrid ? Icons.grid_view : Icons.view_list,
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
                    child: _products.isEmpty && !_isLoading
                        ? const Center(
                            child: Text('Наразі оголошень немає.'),
                          )
                        : _isGrid
                            ? GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(top: 0),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
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
                                    title: product.title,
                                    price: product.price,
                                    date: DateFormat.yMMMd().format(product.createdAt),
                                    location: product.location,
                                    images: product.images,
                                    isFavorite: _favoriteProductIds.contains(product.id),
                                    onFavoriteToggle: () => _toggleFavorite(product),
                                  );
                                },
                              )
                            : ListView.builder(
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
                                    child: ProductCard(
                                      title: product.title,
                                      price: product.price,
                                      date: DateFormat.yMMMd().format(product.createdAt),
                                      location: product.location,
                                      images: product.images,
                                      isFavorite: _favoriteProductIds.contains(product.id),
                                      onFavoriteToggle: () => _toggleFavorite(product),
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