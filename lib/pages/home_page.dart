import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/common_header.dart';
import '../widgets/product_card.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/product_card_list_item.dart'; // Import ProductCardListItem
import '../pages/filter_page.dart'; // Import FilterPage
import 'dart:async'; // Add this import for Timer
import '../pages/map_page.dart'; // Import MapPage
import '../widgets/auth_bottom_sheet.dart'; // Import AuthBottomSheet

enum ViewMode {
  grid8,
  grid4,
  list,
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonHeader(),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: HomeContent(key: key),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
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
  Map<String, dynamic> _currentFilters = {}; // New state variable for filters
  final TextEditingController _searchController = TextEditingController(); // Search controller
  String _searchQuery = ''; // Current search query
  Timer? _searchDebounceTimer; // Timer for debouncing search
  final LayerLink _sortLayerLink = LayerLink(); // LayerLink for sort dropdown
  final LayerLink _viewLayerLink = LayerLink(); // LayerLink for view dropdown

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadProducts();
    _loadFavorites();
    _scrollController.addListener(_onScroll);
    
    // Показуємо bottom sheet для розлогінених користувачів після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_currentUserId == null) {
        _showAuthBottomSheet();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts(
        limit: 10, // Assuming a fixed limit for now
        offset: _currentPage * 10,
        searchQuery: _searchQuery, // Передаємо пошуковий запит
        categoryId: _currentFilters['category'], // Pass category filter
        subcategoryId: _currentFilters['subcategory'], // Pass subcategory filter
        minPrice: _currentFilters['minPrice'], // Pass minPrice filter
        maxPrice: _currentFilters['maxPrice'], // Pass maxPrice filter
        hasDelivery: _currentFilters['hasDelivery'], // Pass hasDelivery filter
        sortBy: _sortBy,
        isFree: false, // No 'isFree' filtering implemented yet
        minArea: _currentFilters['minArea'], // Pass minArea filter
        maxArea: _currentFilters['maxArea'], // Pass maxArea filter
        minYear: _currentFilters['minYear'], // Pass minYear filter
        maxYear: _currentFilters['maxYear'], // Pass maxYear filter
        brand: _currentFilters['car_brand'], // Pass car_brand filter
        minEngineHp: _currentFilters['minEnginePowerHp'], // Pass minEnginePowerHp filter
        maxEngineHp: _currentFilters['maxEnginePowerHp'], // Pass maxEnginePowerHp filter
        size: _currentFilters['size'], // Pass size filter
        condition: _currentFilters['condition'], // Pass condition filter
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
      // Error loading favorites
    }
  }

  void _showAuthBottomSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Затемнення фону з блюром
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AuthBottomSheet(
                title: 'Тут будуть ваші оголошення',
                subtitle: 'Увійдіть у профіль, щоб переглядати, створювати або зберігати оголошення.',
                onLoginPressed: () {
                  Navigator.of(context).pop(); // Закриваємо bottom sheet
                  Navigator.of(context).pushNamed('/auth');
                },
                onCancelPressed: () {
                  Navigator.of(context).pop(); // Закриваємо bottom sheet
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    if (_currentUserId == null) {
      _showAuthBottomSheet();
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
      // Error toggling favorite
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
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
    });
    _loadProducts();
  }

  void _toggleView() {
    setState(() {
      _isViewDropdownOpen = !_isViewDropdownOpen;
      // Закриваємо sort dropdown якщо відкриваємо view dropdown
      if (_isViewDropdownOpen) {
        _isSortDropdownOpen = false;
      }
    });
  }

  void _onViewModeSelected(ViewMode mode) {
    setState(() {
      _currentViewMode = mode;
      _isViewDropdownOpen = false; // Close dropdown after selection
      _products = [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
    });
    _loadProducts();
  }

  void _showFilterBottomSheet() async {
    final Map<String, dynamic>? newFilters = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterPage(
          initialFilters: _currentFilters,
        ),
      ),
    );

    if (newFilters != null) {
      setState(() {
        _currentFilters = newFilters;
        _products = []; // Clear products to reload with new filters
        _currentPage = 0;
        _hasMore = true;
        _errorMessage = null;
      });
      _loadProducts(); // Reload products with new filters
    }
  }

  void refreshProducts() {
    print('Debug: refreshProducts() called');
    setState(() {
      _products = [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
      _searchQuery = '';
      _currentFilters = {};
      _sortBy = null;
    });
    print('Debug: State reset, calling _loadProducts()');
    _loadProducts();
  }

  // Helper method to build the dropdown menu for view modes
  Widget _buildViewModeDropdown() {
    return CompositedTransformFollower(
      link: _viewLayerLink,
      showWhenUnlinked: false,
      offset: const Offset(-180, 52), // 44px (висота кнопки) + 8px (відступ), зміщено вліво на 180px
      child: Container(
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
    return CompositedTransformFollower(
      link: _sortLayerLink,
      showWhenUnlinked: false,
      offset: const Offset(-180, 52), // 44px (висота кнопки) + 8px (відступ), зміщено вліво на 180px
      child: Container(
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
                CompositedTransformTarget(
                  link: _sortLayerLink,
                  child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSortDropdownOpen = !_isSortDropdownOpen;
                        // Закриваємо view dropdown якщо відкриваємо sort dropdown
                        if (_isSortDropdownOpen) {
                          _isViewDropdownOpen = false;
                        }
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
                      child: const Icon(
                      Icons.sort, // Always show sort icon, regardless of dropdown state
                      size: 20,
                      color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CompositedTransformTarget(
                  link: _viewLayerLink,
                  child: GestureDetector(
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
                            controller: _searchController, // Використовуємо той самий контролер
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
                            onChanged: _onSearchChanged, // Використовуємо той самий обробник
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
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    useRootNavigator: true,
                    builder: (context) => const MapPage(),
                  );
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
                  _showFilterBottomSheet();
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
                      _currentPage = 0;
                      _hasMore = true;
                      _errorMessage = null;
                      _searchQuery = '';
                      _currentFilters = {};
                      _sortBy = null;
                    });
                    await _loadProducts();
                  },
                  child: _products.isEmpty && !_isLoading
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
                                          price: product.formattedPrice,
                                    date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                    location: product.location,
                                    images: product.photos,
                                    isNegotiable: product.isNegotiable,
                                    isFavorite: _favoriteProductIds.contains(product.id),
                                    onFavoriteToggle: () => _toggleFavorite(product),
                                    onTap: () {
                                      if (_currentUserId == null) {
                                        _showAuthBottomSheet();
                                      } else {
                                        Navigator.of(context).pushNamed(
                                          '/product-detail',
                                          arguments: {'id': product.id},
                                        );
                                      }
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
                                        price: product.formattedPrice,
                                  date: DateFormat('dd.MM.yyyy').format(product.createdAt),
                                  location: product.location,
                                  images: product.images,
                                  isNegotiable: product.isNegotiable,
                                  isFavorite: _favoriteProductIds.contains(product.id),
                                  onFavoriteToggle: () => _toggleFavorite(product),
                                  onTap: () {
                                    if (_currentUserId == null) {
                                      _showAuthBottomSheet();
                                    } else {
                                      Navigator.of(context).pushNamed(
                                        '/product-detail',
                                        arguments: {'id': product.id},
                                      );
                                    }
                                  },
                                );
                              },
                            ),
              ),
              ),
            ],
          ),
        ),
        if (_isSortDropdownOpen || _isViewDropdownOpen)
          GestureDetector(
            onTap: () {
              setState(() {
                _isSortDropdownOpen = false;
                _isViewDropdownOpen = false;
              });
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
          ),
        ),
        if (_isSortDropdownOpen)
          _buildSortDropdown(),
        if (_isViewDropdownOpen)
          _buildViewModeDropdown(),
      ],
    );
  }

  void _onSearchChanged(String value) {
    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer!.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = value;
        _products = [];
        _currentPage = 0;
        _hasMore = true;
        _errorMessage = null;
      });
      _loadProducts();
    });
  }
}