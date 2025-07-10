import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/pages/add_listing_page.dart';
import 'package:withoutname/pages/home_page.dart';
import 'package:withoutname/pages/viewed_page.dart';
import 'package:withoutname/pages/favorites_page.dart';
import '../models/region.dart';
import '../services/region_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// Додаємо ChatPage
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
        });
        return;
      }
      setState(() {
        _isSearchingCities = true;
      });
      try {
        final results = await searchCitiesGooglePlaces(
          query: query,
          regionName: _selectedRegion!,
        );
        setState(() {
          _cityResults = results;
        });
      } catch (e) {
        setState(() {
          _cityResults = [];
        });
      } finally {
        setState(() {
          _isSearchingCities = false;
        });
      }
    });
  }

  Future<List<String>> searchCitiesGooglePlaces({
    required String query,
    required String regionName,
  }) async {
    const apiKey = 'AIzaSyDg6aJ0F5soP4Y9M4ZGAQ5RJAtFB-PfMa0';
    final sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&language=uk'
      '&components=country:UA'
      '&sessiontoken=$sessionToken'
      '&key=$apiKey',
    );
    final response = await http.get(url);
    print('Google Places response: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        final filtered = predictions.where((p) {
          final desc = (p['description'] as String).toLowerCase();
          return desc.contains(regionName.toLowerCase());
        }).toList();
        return filtered.map<String>((p) => p['description'] as String).toList();
      } else {
        print('Google Places API error: ${data['status']} ${data['error_message'] ?? ''}');
      }
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _citySearchController.addListener(_onCitySearchChanged);
  }

  @override
  Widget build(BuildContext context) {
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

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomePage(),
    const FavoritesPage(),
    const ViewedPage(),
    const ChatPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(23, 6, 23, 36),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.10),
              offset: Offset(0, 4),
              blurRadius: 16,
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.zinc200, width: 1.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: _buildNavItem(
                iconPath: 'assets/icons/home-02.svg',
                label: 'Головна',
                index: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavItem(
                iconPath: 'assets/icons/heart-rounded.svg',
                label: 'Обране',
                index: 1,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.primaryColor, width: 1),
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddListingPage()));
                  if (result == true && _selectedIndex == 0) {
                    // _homeContentKey.currentState?.refreshProducts(); // This line is removed
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                shape: const CircleBorder(),
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavItem(
                iconPath: 'assets/icons/book-open-01.svg',
                label: 'Проглянуті',
                index: 2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavItemWithNotification(
                iconPath: 'assets/icons/message-circle-01.svg',
                label: 'Чат',
                index: 3,
                hasNotification: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? AppColors.primaryColor : AppColors.color5;
    final Color textColor = isSelected ? AppColors.color2 : AppColors.color8;

    return InkWell(
      onTap: () => _onItemTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.captionRegular.copyWith(color: textColor, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithNotification({
    required String iconPath,
    required String label,
    required int index,
    required bool hasNotification,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? AppColors.primaryColor : AppColors.color5;
    final Color textColor = isSelected ? AppColors.color2 : AppColors.color8;

    return InkWell(
      onTap: () => _onItemTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                if (hasNotification)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SvgPicture.asset(
                      'assets/icons/notification_dot.svg',
                      width: 6,
                      height: 6,
                      colorFilter: ColorFilter.mode(AppColors.notificationDotColor, BlendMode.srcIn),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.captionRegular.copyWith(color: textColor, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}