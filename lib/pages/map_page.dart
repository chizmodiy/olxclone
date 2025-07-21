import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/common_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/profile_service.dart';
import '../pages/filter_page.dart'; // Додаю імпорт FilterPage

class Pin extends StatelessWidget {
  final String count;
  const Pin({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 32,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(0),
              decoration: ShapeDecoration(
                color: const Color(0xFF0292B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
              child: Center(
                child: Text(
                  count,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.30,
                    letterSpacing: 0.24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comments extends StatefulWidget {
  final List<Product> products;
  const Comments({super.key, required this.products});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  final ProfileService _profileService = ProfileService();
  Set<String> _favoriteProductIds = {};
  bool _loadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final ids = await _profileService.getFavoriteProductIds();
    setState(() {
      _favoriteProductIds = ids;
      _loadingFavorites = false;
    });
  }

  Future<void> _toggleFavorite(Product product) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 13, right: 13, bottom: 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.products.length} оголошень',
                style: const TextStyle(
                  color: Color(0xFF52525B),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.16,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.close, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loadingFavorites
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      final isFavorite = _favoriteProductIds.contains(product.id);
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: product.photos.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(product.photos.first),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.5),
                                        Colors.black.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                          letterSpacing: 0.14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            product.formattedPrice,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),
                                          Text(
                                            '${product.createdAt.day} ${_monthName(product.createdAt.month)} ${product.createdAt.hour}:${product.createdAt.minute.toString().padLeft(2, '0')} ${product.location}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              height: 1.3,
                                              letterSpacing: 0.24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _toggleFavorite(product),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F5),
                                        borderRadius: BorderRadius.circular(200),
                                        border: Border.all(color: const Color(0xFFF4F4F5), width: 1),
                                      ),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: 20,
                                        color: isFavorite ? const Color(0xFF015873) : const Color(0xFF27272A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  String _monthName(int month) {
    const months = [
      'Січня', 'Лютого', 'Березня', 'Квітня', 'Травня', 'Червня',
      'Липня', 'Серпня', 'Вересня', 'Жовтня', 'Листопада', 'Грудня'
    ];
    return months[month - 1];
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ProductService _productService = ProductService();
  final MapController _mapController = MapController();
  List<Product> _products = [];
  bool _loading = true;
  String _searchQuery = '';
  Map<String, dynamic> _currentFilters = {}; // Додаю збереження фільтрів

  void _goHome() {
    // Знайти GeneralPage в дереві і викликати зміну вкладки
    // Якщо GeneralPageState доступний через InheritedWidget або Provider, тут можна викликати callback
    // Для простоти: Navigator.of(context).pop() якщо MapPage відкрито через push
    // Якщо через таббар — можна використати callback або інший state management
    // Тут для прикладу: Navigator.of(context).popUntil((route) => route.isFirst);
    // Але для таббару краще передати callback
    // TODO: Реалізувати через callback або state management
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
    });
    // Використовуємо getProducts з фільтрами, потім залишаємо тільки продукти з координатами
    final products = await _productService.getProducts(
      searchQuery: _searchQuery,
      categoryId: _currentFilters['category'],
      subcategoryId: _currentFilters['subcategory'],
      minPrice: _currentFilters['minPrice'],
      maxPrice: _currentFilters['maxPrice'],
      hasDelivery: _currentFilters['hasDelivery'],
      isFree: _currentFilters['isFree'],
      minArea: _currentFilters['minArea'],
      maxArea: _currentFilters['maxArea'],
      minYear: _currentFilters['minYear'],
      maxYear: _currentFilters['maxYear'],
      brand: _currentFilters['car_brand'],
      minEngineHp: _currentFilters['minEnginePowerHp'],
      maxEngineHp: _currentFilters['maxEnginePowerHp'],
      size: _currentFilters['size'],
      condition: _currentFilters['condition'],
      // Можна додати інші фільтри за потреби
      limit: 1000, // Щоб завантажити всі продукти для карти
      offset: 0,
    );
    final productsWithCoords = products.where((p) => p.latitude != null && p.longitude != null).toList();
    setState(() {
      _products = productsWithCoords;
      _loading = false;
    });
  }

  Future<void> _showFilterBottomSheet() async {
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
      });
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _searchQuery.isEmpty
        ? _products
        : _products.where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final markers = filteredProducts.map((product) {
      return Marker(
        width: 28,
        height: 32,
        point: LatLng(product.latitude!, product.longitude!),
        child: const Pin(count: '1'),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Карта на всю ширину і висоту
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(49.0, 32.0),
                zoom: 6,
                minZoom: 5,
                maxZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                if (!_loading)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 70,
                      maxZoom: 13,
                      size: const Size(40, 40),
                      markers: markers,
                      builder: (context, markers) {
                        return Pin(count: markers.length.toString());
                      },
                      onClusterTap: (cluster) async {
                        // Визначаємо, чи це фінальний кластер (не розпадається далі)
                        final currentZoom = _mapController.zoom;
                        if (currentZoom >= 13) {
                          // Збираємо продукти з маркерів цього кластера
                          final productsInCluster = cluster.markers
                              .map((m) => _products.firstWhere((p) =>
                                  p.latitude == m.point.latitude &&
                                  p.longitude == m.point.longitude))
                              .toList();
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.7,
                            ),
                            builder: (context) => Comments(products: productsInCluster),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Градієнтний overlay поверх карти
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.5, 0.0),
                  end: Alignment(0.5, 1.0),
                  colors: [
                    Color(0xFF015873), // 100%
                    Color(0x80015873), // 50%
                    Color(0x00015873), // 0%
                  ],
                ),
              ),
            ),
          ),
          // Вміст хедера поверх градієнта
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 64,
              padding: const EdgeInsets.fromLTRB(13, 16, 13, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Лого
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Аватар користувача
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Overlay-група: кнопка повернення + пошук/фільтр
          Positioned(
            top: 88, // 64px хедер + 24px відступ
            left: 13,
            right: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Кнопка повернення
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).maybePop();
                      },
                      child: SvgPicture.asset(
                        'assets/icons/chevron-states.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Головна',
                      style: TextStyle(
                        color: Color(0xFF161817),
                        fontSize: 28,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Пошук і фільтр
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(200),
                          border: Border.all(color: Color(0xFFE4E4E7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF838583), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Пошук',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Color(0xFF838583),
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                  _loadProducts();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(color: Color(0xFFE4E4E7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 