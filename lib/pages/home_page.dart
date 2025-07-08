import 'package:flutter/material.dart';
import '../widgets/common_header.dart';
import '../widgets/product_card.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/product_card_list_item.dart'; // Import ProductCardListItem

enum ViewMode {
  grid8,
  grid4,
  list,
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonHeader(),
      body: Padding(
        padding: EdgeInsets.only(top: 20),
        child: HomeContent(),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ProductService _productService = ProductService();
  final ProfileService _profileService = ProfileService();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _sortBy; // Can be 'price_asc', 'price_desc', or null (for default by date)
  ViewMode _currentViewMode = ViewMode.grid4; // Changed from _isGrid
  String? _errorMessage;
  String? _currentUserId;
  Set<String> _favoriteProductIds = {};
  bool _isViewDropdownOpen = false; // New state variable
  bool _isSortDropdownOpen = false; // New state variable

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadProducts();
    _loadFavorites();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts(
        limit: 10, // Assuming a fixed limit for now
        offset: _currentPage * 10,
        searchQuery: '', // No search query implemented yet
        categoryId: null, // No category filtering implemented yet
        sortBy: _sortBy,
        isFree: false, // No 'isFree' filtering implemented yet
      );

      setState(() {
        _products.addAll(products);
        _currentPage++;
        _hasMore = products.length == 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error loading products: $_errorMessage');
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  void _onSortChanged(String? newSortBy) {
    setState(() {
      _sortBy = newSortBy; // Directly set the sortBy from selected option
      _isSortDropdownOpen = false; // Close dropdown after selection
      _products = [];
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    _loadProducts();
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
      _products = [];
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    _loadProducts();
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
          _buildDropdownMenuItem('Сітка з 8 карток', ViewMode.grid8, Icons.grid_view_outlined),
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

  // Helper method to build the dropdown menu for sorting
  Widget _buildSortDropdown() {
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
          _buildSortDropdownMenuItem('Від новіших', null),
          _buildSortDropdownMenuItem('Від дешевших', 'price_asc'),
          _buildSortDropdownMenuItem('Від дорогих', 'price_desc'),
        ],
      ),
    );
  }

  // Helper method to build individual dropdown menu items for sorting
  Widget _buildSortDropdownMenuItem(String text, String? sortByValue) {
    final bool isSelected = _sortBy == sortByValue;
    return GestureDetector(
      onTap: () => _onSortChanged(sortByValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: isSelected ? const Color(0xFFFAFAFA) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
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
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Помилка: $_errorMessage'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _products = [];
                  _currentPage = 0;
                  _hasMore = true;
                });
                _loadProducts();
              },
              child: const Text('Спробувати знову'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_products.isEmpty && !_isLoading) {
      return const Center(
        child: Text('Немає доступних оголошень'),
      );
    }

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
                    'Головна',
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
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSortDropdownOpen = !_isSortDropdownOpen;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                            boxShadow: _isSortDropdownOpen
                                ? [
                                    BoxShadow(
                                      color: const Color.fromRGBO(16, 24, 40, 0.10),
                                      offset: const Offset(0, 1),
                                      blurRadius: 0, // Changed from 2 to 0
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
                            Icons.sort, // Always show sort icon, regardless of dropdown state
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
                                      blurRadius: 0, // Changed from 2 to 0
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
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Додаємо відступ між пошуком та новими кнопками
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement Map button logic here
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(200),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Карта',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: 0.14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement Filter button logic here
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(200),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_outlined, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Фільтр',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: 0.14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Відступ перед списком товарів
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
                            : _currentViewMode == ViewMode.list
                                ? ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(top: 0),
                                    itemCount: _products.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _products.length) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
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
                                      crossAxisCount: _currentViewMode == ViewMode.grid8 ? 4 : 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: 250,
                                    ),
                                    itemCount: _products.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _products.length) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      final product = _products[index];
                                      return ProductCard(
                                        id: product.id, // Pass product ID
                                        title: product.title,
                                        price: product.isNegotiable
                                            ? 'Ціна договірна'
                                            : product.price == 'Безкоштовно'
                                                ? 'Безкоштовно'
                                                : NumberFormat.currency(locale: 'uk_UA', symbol: '₴').format(product.priceValue),
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
            top: 72, // Changed to 72 (8px below the button)
            right: 13, // Aligned with the right padding
            child: _buildViewModeDropdown(),
          ),
        if (_isSortDropdownOpen)
          Positioned(
            top: 72, // Changed to 72 (8px below the button)
            right: 69, // Aligned with the sort button (13 + 12 + 44)
            child: _buildSortDropdown(),
          ),
      ],
    );
  }
}