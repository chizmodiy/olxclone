import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LocationPicker extends StatefulWidget {
  final void Function(latlong.LatLng? latLng, String? address)? onLocationSelected;
  final latlong.LatLng? initialLatLng;
  final String? initialAddress;
  final String? initialRegion;
  
  const LocationPicker({
    super.key, 
    this.onLocationSelected,
    this.initialLatLng,
    this.initialAddress,
    this.initialRegion,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? _selectedRegion;
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
  final TextEditingController _citySearchController = TextEditingController();
  Timer? _debounceTimer;
  List<Map<String, String>> _cityResults = [];
  bool _isSearchingCities = false;
  String? _apiError;
  latlong.LatLng? _selectedLatLng;
  latlong.LatLng? _mapCenter;
  String? _selectedCityName;
  String? _selectedPlaceId;
  final MapController _mapController = MapController();
  OverlayEntry? _autocompleteOverlay;
  final LayerLink _autocompleteLayerLink = LayerLink();
  bool _citySelected = false;
  bool _isInitializing = true;
  OverlayEntry? _regionDropdownOverlay;
  final LayerLink _regionDropdownLayerLink = LayerLink();
  final GlobalKey _regionFieldKey = GlobalKey();

  @override
  void dispose() {
    _citySearchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onCitySearchChanged() {
    // Не запускаємо пошук під час ініціалізації
    if (_isInitializing) return;
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final query = _citySearchController.text.trim();
      if (query.isEmpty || _selectedRegion == null) {
        setState(() {
          _cityResults = [];
          _apiError = null;
        });
        return;
      }
      setState(() {
        _isSearchingCities = true;
        _apiError = null;
      });
      try {
        final result = await searchCitiesGooglePlaces(
          query: query,
          regionName: _selectedRegion!,
        );
        setState(() {
          _cityResults = result['cities'] ?? [];
          _apiError = result['error'];
        });
      } catch (e) {
        setState(() {
          _cityResults = [];
          _apiError = e.toString();
        });
      } finally {
        setState(() {
          _isSearchingCities = false;
        });
      }
    });
  }

  Future<Map<String, dynamic>> searchCitiesGooglePlaces({
    required String query,
    required String regionName,
  }) async {
    final sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse(
      'https://wcczieoznbopcafdatpk.supabase.co/functions/v1/places-api'
      '?input=${Uri.encodeComponent(query)}'
      '&sessiontoken=$sessionToken'
      '&region=${Uri.encodeComponent(regionName)}',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjY3ppZW96bmJvcGNhZmRhdHBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNTc2MTEsImV4cCI6MjA2NjkzMzYxMX0.1OdLDVnzHx9ghZ7D8X2P_lpZ7XvnPtdEKN4ah_guUJ0',
      },
    );
    String? error;
    List<Map<String, String>> cities = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List<dynamic>;
        cities = predictions.map<Map<String, String>>((p) {
          final Map<String, dynamic> prediction = p as Map<String, dynamic>;
          final description = prediction['description']?.toString() ?? '';
          final placeId = prediction['place_id']?.toString() ?? '';
          return {'name': description, 'placeId': placeId};
        }).toList();
      } else if (data['status'] == 'ZERO_RESULTS') {
        cities = [];
        error = null;
      } else {
        error = 'Google Places API error: ${data['status']} ${data['error_message'] ?? ''}';
      }
    } else {
      error = 'HTTP error: status code ${response.statusCode}';
    }
    return {
      'cities': cities,
      'error': error,
    };
  }

  Future<latlong.LatLng?> getLatLngFromPlaceId(String placeId) async {
    final url = Uri.parse('https://wcczieoznbopcafdatpk.supabase.co/functions/v1/places-api?place_id=$placeId');
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
    return null;
  }

  Future<String?> getCityNameFromLatLng(latlong.LatLng latLng) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=10&addressdetails=1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address != null) {
        return address['city']?.toString() ?? 
               address['town']?.toString() ?? 
               address['village']?.toString() ?? 
               address['state']?.toString() ?? 
               data['display_name']?.toString();
      }
      return data['display_name']?.toString();
    }
    return null;
  }

  Future<latlong.LatLng?> getLatLngFromRegion(String regionName) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?country=Україна&state=${Uri.encodeComponent(regionName)}&format=json&limit=1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        final firstResult = data[0] as Map<String, dynamic>;
        final lat = double.tryParse(firstResult['lat']?.toString() ?? '');
        final lon = double.tryParse(firstResult['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          return latlong.LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  void _showAutocompleteOverlay(BuildContext context) {
    // Не показуємо автодоповнення під час ініціалізації
    if (_isInitializing) return;
    
    _hideAutocompleteOverlay();
    if (_cityResults.isEmpty || _citySearchController.text.isEmpty) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    _autocompleteOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _autocompleteLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52), // 44px (висота інпуту) + 8px (відступ)
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cityResults.length,
                itemBuilder: (context, index) {
                  final cityObj = _cityResults[index];
                  final city = cityObj['name']!;
                  final placeId = cityObj['placeId']!;
                  return ListTile(
                    title: Text(city),
                    onTap: () async {
                      final latLng = await getLatLngFromPlaceId(placeId);
                      setState(() {
                        _selectedLatLng = latLng;
                        _mapCenter = latLng;
                        _selectedCityName = city;
                        _selectedPlaceId = placeId;
                        _citySearchController.text = city;
                        _citySelected = true;
                      });
                      FocusScope.of(context).unfocus();
                      final zoom = city.contains(',') ? 15.0 : 11.0;
                      _mapController.move(latLng!, zoom);
                      if (widget.onLocationSelected != null) {
                        widget.onLocationSelected!(latLng, city);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_autocompleteOverlay!);
  }

  void _hideAutocompleteOverlay() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  void _showRegionDropdown(BuildContext context) {
    // Не показуємо випадаюче вікно під час ініціалізації
    if (_isInitializing) return;
    
    _hideRegionDropdown();
    final renderBox = _regionFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final overlay = Overlay.of(context);
    _regionDropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Прозорий фон для закриття кліком
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideRegionDropdown,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Dropdown
          CompositedTransformFollower(
            link: _regionDropdownLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 52),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: size.width,
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.zinc200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(16, 24, 40, 0.03),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _regions.length,
                        itemBuilder: (context, index) {
                          final region = _regions[index];
                          final isSelected = region == _selectedRegion;
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                _selectedRegion = region;
                              });
                              _onCitySearchChanged();
                              _hideRegionDropdown();
                              final regionLatLng = await getLatLngFromRegion(region);
                              if (regionLatLng != null) {
                                setState(() {
                                  _mapCenter = regionLatLng;
                                  _selectedLatLng = null;
                                });
                                _mapController.move(regionLatLng, 8);
                              }
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(left: 8, right: 10, top: 10, bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.zinc50 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        region,
                                        style: AppTextStyles.body1Regular.copyWith(
                                          color: AppColors.color2,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      SvgPicture.asset(
                                        'assets/icons/check.svg',
                                        width: 20,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_regionDropdownOverlay!);
  }

  void _hideRegionDropdown() {
    _regionDropdownOverlay?.remove();
    _regionDropdownOverlay = null;
  }

  Future<void> _setToCurrentLocation() async {
    try {
      // Перевіряємо чи увімкнені сервіси геолокації
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Показуємо повідомлення користувачу
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Будь ласка, увімкніть геолокацію в налаштуваннях телефону'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Перевіряємо дозволи
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showPermissionRequestDialog();
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationPermissionDialog();
        }
        return;
      }

      // Отримуємо поточну позицію
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      final latLng = latlong.LatLng(pos.latitude, pos.longitude);
      final cityName = await getCityNameFromLatLng(latLng);
      
      setState(() {
        _selectedLatLng = latLng;
        _mapCenter = latLng;
        _selectedCityName = cityName;
        _selectedPlaceId = null;
      });
      
      _mapController.move(latLng, 11);
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(latLng, cityName);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ваша локація встановлена'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка отримання локації: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPermissionRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Дозвіл на геолокацію'),
          content: const Text(
            'Для використання функції "Моє місцеположення" потрібен дозвіл на доступ до геолокації. '
            'Будь ласка, надайте дозвіл для продовження.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Скасувати'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Повторно запитуємо дозвіл
                await _setToCurrentLocation();
              },
              child: const Text('Надати дозвіл'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Дозвіл на геолокацію'),
          content: const Text(
            'Для використання функції "Моє місцеположення" потрібен дозвіл на доступ до геолокації. '
            'Дозвіл був відхилений назавжди. Будь ласка, увімкніть його в налаштуваннях додатку.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Скасувати'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Відкриваємо налаштування додатку
                await Geolocator.openAppSettings();
              },
              child: const Text('Налаштування'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _citySearchController.addListener(_onCitySearchChanged);
    
    // Встановлюємо початкові значення
    if (widget.initialRegion != null) {
      _selectedRegion = widget.initialRegion;
    }
    
    if (widget.initialAddress != null) {
      _citySearchController.text = widget.initialAddress!;
    }
    
    if (widget.initialLatLng != null) {
      _selectedLatLng = widget.initialLatLng;
      _mapCenter = widget.initialLatLng;
    }
    
    // Позначаємо, що ініціалізація завершена
    _isInitializing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Локація (Dropdown)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: CompositedTransformTarget(
              link: _regionDropdownLayerLink,
              child: GestureDetector(
                onTap: () {
                  _showRegionDropdown(context);
                },
                child: Container(
                  key: _regionFieldKey,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.zinc50,
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedRegion ?? 'Локація',
                          style: AppTextStyles.body1Regular.copyWith(
                            color: _selectedRegion != null ? AppColors.color2 : AppColors.color5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/chevron_down.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Інпут пошуку
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: CompositedTransformTarget(
                link: _autocompleteLayerLink,
                child: TextField(
                  controller: _citySearchController,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: 1,
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColors.color2,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Введіть назву міста, вулиці, адреси або закладу',
                    hintStyle: AppTextStyles.body1Regular.copyWith(
                      color: AppColors.color5,
                      height: 1.0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) {
                    _onCitySearchChanged();
                    setState(() {
                      _citySelected = false;
                    });
                  },
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showAutocompleteOverlay(context);
                    });
                  },
                  onEditingComplete: _hideAutocompleteOverlay,
                ),
              ),
            ),
          ),
          // Loading, error, empty state, results
          if (_isSearchingCities)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (!_isSearchingCities && _apiError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Помилка: $_apiError',
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (!_isSearchingCities && _apiError == null && _citySearchController.text.isNotEmpty && _cityResults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Нічого не знайдено',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          if (!_isSearchingCities && _cityResults.isNotEmpty && !_citySelected && _citySearchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.zinc200),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(16, 24, 40, 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cityResults.length,
                  itemBuilder: (context, index) {
                    final cityObj = _cityResults[index];
                    final city = cityObj['name']!;
                    final placeId = cityObj['placeId']!;
                    return ListTile(
                      title: Text(
                        city,
                        style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                      ),
                      onTap: () async {
                        final latLng = await getLatLngFromPlaceId(placeId);
                        setState(() {
                          _selectedLatLng = latLng;
                          _mapCenter = latLng;
                          _selectedCityName = city;
                          _selectedPlaceId = placeId;
                          _citySearchController.text = city;
                          _citySelected = true;
                        });
                        FocusScope.of(context).unfocus();
                        final zoom = city.contains(',') ? 15.0 : 11.0;
                        _mapController.move(latLng!, zoom);
                        if (widget.onLocationSelected != null) {
                          widget.onLocationSelected!(latLng, city);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          // Карта
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _mapCenter ?? latlong.LatLng(49.0, 32.0),
                  zoom: _selectedLatLng != null ? 11 : 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  if (_selectedLatLng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: _selectedLatLng!,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Кнопка "Моє місцезнаходження"
          SizedBox(
            width: double.infinity,
            height: 44, // Фіксована висота 44 пікселі
            child: ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Моє місцезнаходження'),
                          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.color2,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(200),
                side: BorderSide(color: AppColors.zinc200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: AppTextStyles.body1Medium,
            ),
              onPressed: _setToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }
} 