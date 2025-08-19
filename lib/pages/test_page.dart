import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  // Змінні для області
  String? _selectedRegion;
  bool _isRegionDropdownOpen = false;
  final List<String> _regions = [
    'Вінницька область',
    'Волинська область',
    'Дніпропетровська область',
    'Донецька область',
    'Житомирська область',
    'Закарпатська область',
    'Запорізька область',
    'Івано-Франківська область',
    'Київська область',
    'Кіровоградська область',
    'Луганська область',
    'Львівська область',
    'Миколаївська область',
    'Одеська область',
    'Полтавська область',
    'Рівненська область',
    'Сумська область',
    'Тернопільська область',
    'Харківська область',
    'Херсонська область',
    'Хмельницька область',
    'Черкаська область',
    'Чернівецька область',
    'Чернігівська область',
    'м. Київ',
    'м. Севастополь',
    'АР Крим',
  ];

  // Змінні для міста
  final TextEditingController _cityController = TextEditingController();
  List<Map<String, String>> _cityResults = [];
  bool _isSearchingCities = false;
  String? _selectedCity;
  String? _selectedPlaceId;
  Timer? _debounceTimer;

  // Змінні для карти
  late final MapController _mapController;
  latlong.LatLng? _currentLocation;
  latlong.LatLng? _selectedLocation;
  bool _isLoadingLocation = false;

  // Центр України
  final latlong.LatLng _ukraineCenter = const latlong.LatLng(49.0, 32.0);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  void _initializeMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_ukraineCenter, 6.0);
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Локація',
          style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.arrow_back,
            color: AppColors.color2,
            size: 24,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isRegionDropdownOpen) {
            setState(() {
              _isRegionDropdownOpen = false;
            });
          }
        },
        child: Column(
          children: [
            // Верхня частина з полями вводу
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Dropdown для вибору області
                  _buildRegionDropdown(),
                  const SizedBox(height: 16),
                  
                  // Поле вводу міста (показується тільки після вибору області)
                  if (_selectedRegion != null) ...[
                    _buildCityInput(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            
            // Карта
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildMap(),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка "Моє місцезнаходження"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildLocationButton(),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Dropdown для вибору області
  Widget _buildRegionDropdown() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isRegionDropdownOpen = !_isRegionDropdownOpen;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedRegion ?? 'Оберіть область',
                    style: _selectedRegion != null
                        ? AppTextStyles.body1Regular.copyWith(color: AppColors.color2)
                        : AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  ),
                ),
                Icon(
                  _isRegionDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.color5,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isRegionDropdownOpen)
          Container(
            width: double.infinity,
            height: 320,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1,
                color: const Color(0xFFEAECF0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x07101828),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0x14101828),
                  blurRadius: 16,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = _selectedRegion == region;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                        _selectedCity = null;
                        _selectedPlaceId = null;
                        _cityController.clear();
                        _cityResults.clear();
                        _isRegionDropdownOpen = false;
                      });
                      
                      if (region != null) {
                        _focusMapOnRegion(region);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 8,
                        right: 10,
                        bottom: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFAFAFA) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              region,
                              style: TextStyle(
                                color: const Color(0xFF0F1728),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                height: 1.50,
                                letterSpacing: isSelected ? 0.16 : 0,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 20,
                              height: 20,
                              child: const Icon(
                                Icons.check,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Поле вводу міста
  Widget _buildCityInput() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Введіть назву міста або села',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                  onChanged: _onCitySearchChanged,
                ),
              ),
              if (_isSearchingCities)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (_cityResults.isNotEmpty)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1,
                color: const Color(0xFFEAECF0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x07101828),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0x14101828),
                  blurRadius: 16,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _cityResults.length,
              itemBuilder: (context, index) {
                final city = _cityResults[index];
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: GestureDetector(
                    onTap: () => _onCitySelected(city),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 8,
                        right: 10,
                        bottom: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              city['name'] ?? '',
                              style: TextStyle(
                                color: const Color(0xFF0F1728),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Карта
  Widget _buildMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Отримуємо ширину екрану
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Розраховуємо розмір карти пропорційно
        // При ширині екрану 390px карта має бути 364x364
        final mapSize = (screenWidth - 32) * (364.0 / 358.0); // 358 = 390 - 32 (відступи)
        
        // Обмежуємо максимальний розмір
        final maxMapSize = screenWidth - 32;
        final finalMapSize = mapSize > maxMapSize ? maxMapSize : mapSize;
        
        // Обмежуємо висоту карти, щоб вона не була занадто великою
        final maxHeight = screenWidth * 0.8; // 80% від ширини екрану
        final finalHeight = finalMapSize > maxHeight ? maxHeight : finalMapSize;
        
        return Center(
          child: Container(
            width: finalMapSize,
            height: finalHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.zinc200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _selectedLocation ?? _currentLocation ?? _ukraineCenter,
                      zoom: _selectedLocation != null ? 12.0 : 6.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40,
                              height: 40,
                              point: _selectedLocation!,
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primaryColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Кнопки керування картою
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _buildMapControlButton(
                          icon: Icons.add,
                          onTap: () {
                            try {
                              final currentZoom = _mapController.zoom;
                              _mapController.move(_mapController.center, currentZoom + 1);
                            } catch (e) {
                              print('Помилка збільшення масштабу: $e');
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMapControlButton(
                          icon: Icons.remove,
                          onTap: () {
                            try {
                              final currentZoom = _mapController.zoom;
                              _mapController.move(_mapController.center, currentZoom - 1);
                            } catch (e) {
                              print('Помилка зменшення масштабу: $e');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Кнопка керування картою
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.color2, size: 20),
      ),
    );
  }

  // Кнопка "Моє місцезнаходження"
  Widget _buildLocationButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5), // Zinc-100
        borderRadius: BorderRadius.circular(200),
        border: Border.all(
          width: 1,
          color: const Color(0xFFF4F4F5), // Zinc-100
        ),
      ),
      child: GestureDetector(
        onTap: _isLoadingLocation ? null : _getCurrentLocation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoadingLocation)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            else
              Container(
                width: 20,
                height: 20,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              'Моє місцезнаходження',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: 0.14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Методи для роботи з пошуком міст
  void _onCitySearchChanged(String query) {
    if (query.isEmpty || _selectedRegion == null) {
      setState(() {
        _cityResults.clear();
      });
      return;
    }

    // Debounce запитів
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _isSearchingCities = true;
      });

      try {
        final results = await _searchCities(query, _selectedRegion!);
        setState(() {
          _cityResults = results;
          _isSearchingCities = false;
        });
      } catch (e) {
        setState(() {
          _cityResults.clear();
          _isSearchingCities = false;
        });
        print('Помилка пошуку міст: $e');
      }
    });
  }

  Future<List<Map<String, String>>> _searchCities(String query, String region) async {
    final sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Перевіряємо, чи користувач не вводить область, яка вже вибрана
    if (_isSameRegion(query, region)) {
      return [];
    }
    
    // Додаємо більш точне обмеження пошуку для області
    final String searchQuery = '$query, $region, Україна';
    
    final url = Uri.parse(
      'https://wcczieoznbopcafdatpk.supabase.co/functions/v1/places-api'
      '?input=${Uri.encodeComponent(searchQuery)}'
      '&sessiontoken=$sessionToken'
      '&region=${Uri.encodeComponent(region)}'
      '&components=country:ua',
    );
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjY3ppZW96bmJvcGNhZmRhdHBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNTc2MTEsImV4cCI6MjA2NjkzMzYxMX0.1OdLDVnzHx9ghZ7D8X2P_lpZ7XvnPtdEKN4ah_guUJ0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List<dynamic>;
          final cities = predictions.map<Map<String, String>>((p) {
            final Map<String, dynamic> prediction = p as Map<String, dynamic>;
            final description = prediction['description']?.toString() ?? '';
            final placeId = prediction['place_id']?.toString() ?? '';
            return {'name': description, 'placeId': placeId};
          }).toList();
          
          // Фільтруємо результати, прибираючи області та країну
          return cities.where((city) {
            final name = city['name']?.toLowerCase() ?? '';
            final regionLower = region.toLowerCase();
            
            // Пропускаємо результат, якщо він містить тільки область або країну
            if (name == regionLower || 
                name == 'україна' || 
                name == 'ukraine') {
              return false;
            }
            
            // Перевіряємо, чи не є результат областю
            if (_isSameRegion(name, region)) {
              return false;
            }
            
            // Результат повинен містити щось більше, ніж область
            return name.contains(regionLower) || 
                   name.contains('україна') || 
                   name.contains('ukraine');
          }).toList();
        }
      }
    } catch (e) {
      print('Помилка пошуку міст: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка пошуку міст: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    return [];
  }

  void _onCitySelected(Map<String, String> city) async {
    try {
      setState(() {
        _selectedCity = city['name'];
        _selectedPlaceId = city['placeId'];
        _cityController.text = city['name'] ?? '';
        _cityResults.clear();
      });
      
      // Отримуємо координати міста та фокусуємо карту
      if (city['placeId'] != null) {
        final coordinates = await _getLatLngFromPlaceId(city['placeId']!);
        if (coordinates != null) {
          setState(() {
            _selectedLocation = coordinates;
          });
          try {
          _mapController.move(coordinates, 12.0);
        } catch (e) {
          print('Помилка фокусування на місті: $e');
        }
        }
      }
    } catch (e) {
      print('Помилка вибору міста: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка вибору міста: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Фокусування карти на області
  void _focusMapOnRegion(String region) {
    try {
      // Координати центрів областей України
      final regionCoordinates = {
        'Вінницька область': const latlong.LatLng(49.2331, 28.4682),
        'Волинська область': const latlong.LatLng(50.7476, 25.3253),
        'Дніпропетровська область': const latlong.LatLng(48.4647, 35.0462),
        'Донецька область': const latlong.LatLng(48.0159, 37.8028),
        'Житомирська область': const latlong.LatLng(50.2547, 28.6587),
        'Закарпатська область': const latlong.LatLng(48.6208, 22.2879),
        'Запорізька область': const latlong.LatLng(47.8388, 35.1396),
        'Івано-Франківська область': const latlong.LatLng(48.9226, 24.7111),
        'Київська область': const latlong.LatLng(50.4501, 30.5234),
        'Кіровоградська область': const latlong.LatLng(48.5079, 32.2623),
        'Луганська область': const latlong.LatLng(48.5740, 39.3078),
        'Львівська область': const latlong.LatLng(49.8397, 24.0297),
        'Миколаївська область': const latlong.LatLng(46.9750, 31.9946),
        'Одеська область': const latlong.LatLng(46.4825, 30.7233),
        'Полтавська область': const latlong.LatLng(49.5883, 34.5514),
        'Рівненська область': const latlong.LatLng(50.6199, 26.2516),
        'Сумська область': const latlong.LatLng(50.9077, 34.7981),
        'Тернопільська область': const latlong.LatLng(49.5535, 25.5948),
        'Харківська область': const latlong.LatLng(49.9935, 36.2304),
        'Херсонська область': const latlong.LatLng(46.6354, 32.6178),
        'Хмельницька область': const latlong.LatLng(49.4229, 26.9871),
        'Черкаська область': const latlong.LatLng(49.4444, 32.0598),
        'Чернівецька область': const latlong.LatLng(48.2917, 25.9352),
        'Чернігівська область': const latlong.LatLng(51.4982, 31.2893),
        'м. Київ': const latlong.LatLng(50.4501, 30.5234),
        'м. Севастополь': const latlong.LatLng(44.6166, 33.5254),
        'АР Крим': const latlong.LatLng(45.3453, 34.4997),
      };

      final coordinates = regionCoordinates[region] ?? _ukraineCenter;
      _mapController.move(coordinates, 8.0);
    } catch (e) {
      print('Помилка фокусування на області: $e');
      try {
        _mapController.move(_ukraineCenter, 6.0);
      } catch (e2) {
        print('Помилка фокусування на центрі України: $e2');
      }
    }
  }

  // Фокусування карти на місті
  void _focusMapOnCity(String cityName) {
    // Тут буде логіка для отримання координат міста
    // Поки що використовуємо центр області
    if (_selectedRegion != null) {
      _focusMapOnRegion(_selectedRegion!);
    }
  }

  // Отримання поточної локації
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Перевіряємо дозволи
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Дозвіл на геолокацію відхилено');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Дозвіл на геолокацію відхилено назавжди');
      }

      // Отримуємо поточну позицію
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = latlong.LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = location;
        _selectedLocation = location;
        _isLoadingLocation = false;
      });

      // Фокусуємо карту на поточній локації
      try {
        _mapController.move(location, 14.0);
      } catch (e) {
        print('Помилка фокусування карти: $e');
      }

      // Отримуємо адресу та заповнюємо поля
      await _fillLocationFromCoordinates(location);

    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка отримання локації: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Заповнення полів з координат
  Future<void> _fillLocationFromCoordinates(latlong.LatLng location) async {
    try {
      // Використовуємо Nominatim OpenStreetMap API для Reverse Geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=${location.latitude}&lon=${location.longitude}'
        '&format=json&accept-language=uk&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'YourApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>;
        
        // Отримуємо область та місто з адреси
        String? region = address['state']?.toString() ?? address['province']?.toString() ?? address['region']?.toString();
        String? city = address['city']?.toString() ?? address['town']?.toString() ?? address['village']?.toString() ?? address['municipality']?.toString();
        
        // Якщо місто не знайдено, беремо перший доступний населений пункт
        if (city == null) {
          city = address['suburb']?.toString() ?? address['county']?.toString() ?? address['district']?.toString();
        }
        
        // Якщо область не знайдено, беремо країну
        if (region == null) {
          region = address['country']?.toString();
        }
        
        // Перевіряємо, чи це Україна
        final country = address['country']?.toString();
        if (country == 'Україна' || country == 'Ukraine') {
          // Додаємо "область" до назви області, якщо її немає
          if (region != null && !region!.toLowerCase().contains('область')) {
            region = '$region область';
          }
          
          // Перевіряємо, чи область є в нашому списку
          if (region != null && _regions.contains(region!)) {
            setState(() {
              _selectedRegion = region!;
              _selectedCity = city;
              _cityController.text = city != null ? '$city, ${region!}' : region!;
            });
            
            // Фокусуємо карту на області
            _focusMapOnRegion(region!);
          } else {
            // Якщо область не знайдена в списку, встановлюємо за замовчуванням
            setState(() {
              _selectedRegion = 'Київська область';
              _selectedCity = city ?? 'Київ';
              _cityController.text = city != null ? '$city, Київська область' : 'Київ, Київська область';
            });
            
            _focusMapOnRegion('Київська область');
          }
        } else {
          // Якщо це не Україна, встановлюємо за замовчуванням
          setState(() {
            _selectedRegion = 'Київська область';
            _selectedCity = 'Київ';
            _cityController.text = 'Київ, Київська область';
          });
          
          _focusMapOnRegion('Київська область');
        }
      } else {
        throw Exception('Помилка отримання адреси: ${response.statusCode}');
      }
    } catch (e) {
      print('Помилка отримання адреси: $e');
      
      // При помилці встановлюємо за замовчуванням
      setState(() {
        _selectedRegion = 'Київська область';
        _selectedCity = 'Київ';
        _cityController.text = 'Київ, Київська область';
      });
      
      _focusMapOnRegion('Київська область');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка отримання адреси: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Перевіряє, чи є частина адреси тією ж областю, що вже вибрана
  bool _isSameRegion(String addressPart, String selectedRegion) {
    final partLower = addressPart.toLowerCase();
    final regionLower = selectedRegion.toLowerCase();
    
    // Пряме порівняння
    if (partLower == regionLower) {
      return true;
    }
    
    // Порівняння без "область" та "м."
    final cleanPart = partLower
        .replaceAll('область', '')
        .replaceAll('м.', '')
        .trim();
    final cleanRegion = regionLower
        .replaceAll('область', '')
        .replaceAll('м.', '')
        .trim();
    
    if (cleanPart == cleanRegion) {
      return true;
    }
    
    // Перевіряємо, чи містить частина адреси назву області
    if (partLower.contains('область') && regionLower.contains('область')) {
      // Видаляємо слово "область" та порівнюємо
      final partWithoutRegion = partLower.replaceAll('область', '').trim();
      final regionWithoutRegion = regionLower.replaceAll('область', '').trim();
      if (partWithoutRegion == regionWithoutRegion) {
        return true;
      }
    }
    
    // Перевіряємо міста-області (Київ, Севастополь)
    if (regionLower.contains('м. київ') && partLower.contains('київ')) {
      return true;
    }
    if (regionLower.contains('м. севастополь') && partLower.contains('севастополь')) {
      return true;
    }
    
    return false;
  }

  // Отримання координат з Place ID
  Future<latlong.LatLng?> _getLatLngFromPlaceId(String placeId) async {
    final url = Uri.parse('https://wcczieoznbopcafdatpk.supabase.co/functions/v1/places-api?place_id=$placeId');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjY3ppZW96bmJvcGNhZmRhdHBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNTc2MTEsImV4cCI6MjA2NjkzMzYxMX0.1OdLDVnzHx9ghZ7D8X2P_lpZ7XvnPtdEKN4ah_guUJ0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>;
          final location = geometry['location'] as Map<String, dynamic>;
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          return latlong.LatLng(lat, lng);
        }
      }
    } catch (e) {
      print('Помилка отримання координат: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка отримання координат: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    return null;
  }
} 