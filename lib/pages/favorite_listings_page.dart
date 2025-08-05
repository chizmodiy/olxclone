import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/product_card_list_item.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class FavoriteListingsPage extends StatefulWidget {
  const FavoriteListingsPage({super.key});

  @override
  State<FavoriteListingsPage> createState() => _FavoriteListingsPageState();
}

class _FavoriteListingsPageState extends State<FavoriteListingsPage> {
  final ProductService _productService = ProductService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
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
    _searchController.addListener(_onSearchChanged);
    
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_currentUserId != null) {
        final userStatus = await _profileService.getUserStatus();
        if (userStatus == 'blocked') {
          _showBlockedUserBottomSheet();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_favoriteProductIds.isEmpty) {
        await _loadFavorites();
      }
      final products = await _productService.getProductsByIds(
        _favoriteProductIds.toList(),
      );
      // Фільтруємо тільки активні оголошення
      final activeProducts = products.where((p) => p.status == 'active' || p.status == null).toList();
      setState(() {
        _products = activeProducts;
        _filteredProducts = activeProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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
    if (_currentUserId == null) return;
    try {
      if (_favoriteProductIds.contains(product.id)) {
        await _profileService.removeFavoriteProduct(product.id);
        setState(() {
          _favoriteProductIds.remove(product.id);
          _filteredProducts.removeWhere((p) => p.id == product.id);
          _products.removeWhere((p) => p.id == product.id);
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = query.isEmpty
          ? _products
          : _products.where((p) => p.title.toLowerCase().contains(query)).toList();
    });
  }

  void _showBlockedUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Неможливо закрити
      enableDrag: false, // Неможливо перетягувати
      builder: (context) => const BlockedUserBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 13, right: 13, top: 24, bottom: 20),
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
                  Expanded(
                    child: Text(
                      'Улюблені оголошення',
                      style: const TextStyle(
                        color: Color(0xFF161817),
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.20,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
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
                            ? const Center(child: Text('Немає улюблених оголошень'))
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ProductCardListItem(
                                      id: product.id,
                                      title: product.title,
                                      price: product.formattedPrice,
                                      images: product.photos,
                                      isNegotiable: product.isNegotiable,
                                      isFavorite: _favoriteProductIds.contains(product.id),
                                      onFavoriteToggle: () => _toggleFavorite(product),
                                      onTap: () async {
                                        await Navigator.of(context).pushNamed(
                                          '/product-detail',
                                          arguments: {'id': product.id},
                                        );
                                        // Оновлюємо улюблені при поверненні
                                        _loadFavorites();
                                      },
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