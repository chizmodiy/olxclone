import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  List<String> _cityResults = [];
  bool _isSearchingCities = false;
  String? _rawApiResponse; // Для збереження сирої відповіді
  String? _apiError; // Для збереження помилки

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
          _cityResults = result['cities'];
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
      'http://localhost:3000/places'
      '?input=${Uri.encodeComponent(query)}'
      '&sessiontoken=$sessionToken',
    );
    final response = await http.get(url);
    String? error;
    List<String> cities = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        final filtered = predictions.where((p) {
          final desc = (p['description'] as String).toLowerCase();
          final types = (p['types'] as List).cast<String>();
          // Всі типи населених пунктів
          final isSettlement = types.contains('locality') ||
              types.contains('sublocality') ||
              types.contains('administrative_area_level_1') ||
              types.contains('administrative_area_level_2') ||
              types.contains('administrative_area_level_3') ||
              types.contains('administrative_area_level_4') ||
              types.contains('administrative_area_level_5') ||
              types.contains('postal_town') ||
              types.contains('neighborhood') ||
              types.contains('plus_code') ||
              types.contains('political');
          return desc.contains(regionName.toLowerCase()) && isSettlement;
        }).toList();
        // Відображаємо тільки назву населеного пункту (без країни та області)
        cities = filtered.map<String>((p) {
          final description = p['description'] as String;
          // Вирізаємо країну та область (беремо першу частину до коми)
          final parts = description.split(',');
          return parts.first.trim();
        }).toList();
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

  @override
  void initState() {
    super.initState();
    _citySearchController.addListener(_onCitySearchChanged);
  }

  @override
  Widget build(BuildContext context) {
    print('ChatPage build');
    return Scaffold(
      appBar: AppBar(title: const Text('Пошук міст (Google Places API)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Оберіть область', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _selectedRegion,
              hint: const Text('Оберіть область'),
              isExpanded: true,
              items: _regions.map((region) => DropdownMenuItem(
                value: region,
                child: Text(region),
              )).toList(),
              onChanged: (region) {
                setState(() {
                  _selectedRegion = region;
                });
                _onCitySearchChanged();
              },
            ),
            const SizedBox(height: 20),
            Text('Пошук міста', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _citySearchController,
              decoration: const InputDecoration(
                hintText: 'Введіть назву міста',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
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
            if (!_isSearchingCities && _rawApiResponse != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    'API response: $_rawApiResponse',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ),
            if (!_isSearchingCities && _cityResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _cityResults.length,
                  itemBuilder: (context, index) {
                    final city = _cityResults[index];
                    return ListTile(
                      title: Text(city),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Вибрано місто: $city')),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 