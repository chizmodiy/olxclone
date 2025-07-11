import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
  // Замість List<String> _cityResults
  List<Map<String, String>> _cityResults = [];
  bool _isSearchingCities = false;
  String? _rawApiResponse; // Для збереження сирої відповіді
  String? _apiError; // Для збереження помилки
  LatLng? _selectedLatLng;
  LatLng? _mapCenter; // Центр карти
  String? _selectedCityName;
  String? _selectedPlaceId;
  int? _dropdownSelectedIndex;
  final MapController _mapController = MapController();
  OverlayEntry? _autocompleteOverlay;
  final LayerLink _autocompleteLayerLink = LayerLink();
  bool _citySelected = false;

  @override
  void dispose() {
    _citySearchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onCitySearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final query = _citySearchController.text.trim();
      if (query.isEmpty || _selectedRegion == null) {
        setState(() {
          _cityResults = [];
          _rawApiResponse = null;
          _apiError = null;
        });
        return;
      }
      setState(() {
        _isSearchingCities = true;
        _rawApiResponse = null;
        _apiError = null;
      });
      try {
        final result = await searchCitiesGooglePlaces(
          query: query,
          regionName: _selectedRegion!,
        );
        setState(() {
          _cityResults = result['cities'] ?? [];
          _rawApiResponse = result['raw'];
          _apiError = result['error'];
        });
      } catch (e) {
        setState(() {
          _cityResults = [];
          _rawApiResponse = null;
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
      'http://localhost:3000/address_search'
      '?input=${Uri.encodeComponent(query)}'
      '&sessiontoken=$sessionToken'
      '&region=${Uri.encodeComponent(regionName)}',
    );
    final response = await http.get(url);
    String? error;
    List<Map<String, String>> cities = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        // Тепер показуємо всі результати (міста, адреси, заклади)
        cities = predictions.map<Map<String, String>>((p) {
          final description = p['description'] as String;
          final placeId = p['place_id'] as String;
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
      'raw': response.body,
      'error': error,
    };
  }

  // Отримати координати через Google Places Details API
  Future<LatLng?> getLatLngFromPlaceId(String placeId) async {
    final url = Uri.parse('http://localhost:3000/place_details?place_id=$placeId');
    final response = await http.get(url);
    print('Place details response: ${response.body}'); // debug
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        return LatLng(loc['lat'], loc['lng']);
      }
    }
    return null;
  }

  // Reverse geocoding для координат (через Nominatim)
  Future<String?> getCityNameFromLatLng(LatLng latLng) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=10&addressdetails=1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['address']['city'] ?? data['address']['town'] ?? data['address']['village'] ?? data['address']['state'] ?? data['display_name'];
    }
    return null;
  }

  // Отримати координати центру області через Nominatim
  Future<LatLng?> getLatLngFromRegion(String regionName) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?country=Україна&state=${Uri.encodeComponent(regionName)}&format=json&limit=1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        final lat = double.tryParse(data[0]['lat'].toString());
        final lon = double.tryParse(data[0]['lon'].toString());
        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  void _showAutocompleteOverlay(BuildContext context) {
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
          offset: Offset(0, size.height + 8),
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
                      _mapController.move(latLng!, 11);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Вибрано місто: $city')),
                      );
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

  // Визначити місцезнаходження
  Future<void> _setToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    final latLng = LatLng(pos.latitude, pos.longitude);
    final cityName = await getCityNameFromLatLng(latLng);
    setState(() {
      _selectedLatLng = latLng;
      _mapCenter = latLng;
      _selectedCityName = cityName;
      _selectedPlaceId = null;
    });
    // Центруємо карту
    _mapController.move(latLng, 11);
  }

  @override
  void initState() {
    super.initState();
    _citySearchController.addListener(_onCitySearchChanged);
  }

  @override
  Widget build(BuildContext context) {
    print('ChatPage build');
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Локація (Dropdown)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: Color(0xFFE4E4E7), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      hint: const Text(
                        'Локація',
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.16,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF667085)),
                      items: _regions.map((region) => DropdownMenuItem(
                        value: region,
                        child: Text(region,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      )).toList(),
                      onChanged: (region) async {
                        setState(() {
                          _selectedRegion = region;
                        });
                        _onCitySearchChanged();
                        // Центруємо карту на область
                        if (region != null) {
                          final regionLatLng = await getLatLngFromRegion(region);
                          if (regionLatLng != null) {
                            setState(() {
                              _mapCenter = regionLatLng;
                              _selectedLatLng = null;
                            });
                            _mapController.move(regionLatLng, 8);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              // Інпут пошуку
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(color: Color(0xFFE4E4E7), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: CompositedTransformTarget(
                    link: _autocompleteLayerLink,
                    child: TextField(
                      controller: _citySearchController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Введіть назву міста, вулиці, адреси або закладу',
                        hintStyle: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
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
              const Center(child: CircularProgressIndicator()),
            if (!_isSearchingCities && _apiError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Помилка: $_apiError',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              if (!_isSearchingCities && _apiError == null && _citySearchController.text.isNotEmpty && _cityResults.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Нічого не знайдено',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            if (!_isSearchingCities && _cityResults.isNotEmpty && !_citySelected && _citySearchController.text.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Вибрано: $city')),
                        );
                      },
                    );
                  },
                ),
              ),
              // Карта
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                      center: _mapCenter ?? LatLng(49.0, 32.0),
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
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Моє місцезнаходження'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                onPressed: _setToCurrentLocation,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
} 