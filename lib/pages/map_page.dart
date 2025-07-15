import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/common_header.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Pin extends StatelessWidget {
  final String count;
  const Pin({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _loading = true;

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
    final products = await _productService.getAllProductsWithCoordinates();
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = _products.map((product) {
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
                      maxClusterRadius: 60,
                      size: const Size(40, 40),
                      markers: markers,
                      builder: (context, markers) {
                        return Pin(count: markers.length.toString());
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
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(200),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/chevron-states.svg',
                          width: 20,
                          height: 20,
                        ),
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
                          children: const [
                            Icon(Icons.search_rounded, color: Color(0xFF838583), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
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
                                style: TextStyle(
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
                    ),
                    const SizedBox(width: 12),
                    Container(
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