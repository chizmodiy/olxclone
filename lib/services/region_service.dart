import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import 'package:http/http.dart' as http; // Add this import
import 'dart:convert'; // Add this import

class RegionService {
  final SupabaseClient _supabaseClient;

  RegionService(this._supabaseClient);

  Future<List<Region>> getRegions() async {
    try {
      final response = await _supabaseClient
          .from('regions')
          .select('id, name')
          .order('name');

      return (response as List<dynamic>)
          .map((json) => Region.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      print('Error fetching regions: $error');
      return [];
    }
  }

  Future<void> initializeRegions() async {
    try {
      // Check if regions already exist and have bounding box data
      final existing = await _supabaseClient.from('regions').select('id, min_lat');
      if ((existing as List).isNotEmpty && existing.any((element) => element['min_lat'] != null)) {
        print('Regions already initialized with bounding box data.');
        return; // Regions already initialized with bounding box
      }

      // List of Ukrainian regions
      final List<Map<String, dynamic>> regionsData = [
        {'name': 'Вінницька область'},
        {'name': 'Волинська область'},
        {'name': 'Дніпропетровська область'},
        {'name': 'Донецька область'},
        {'name': 'Житомирська область'},
        {'name': 'Закарпатська область'},
        {'name': 'Запорізька область'},
        {'name': 'Івано-Франківська область'},
        {'name': 'Київська область'},
        {'name': 'Кіровоградська область'},
        {'name': 'Луганська область'},
        {'name': 'Львівська область'},
        {'name': 'Миколаївська область'},
        {'name': 'Одеська область'},
        {'name': 'Полтавська область'},
        {'name': 'Рівненська область'},
        {'name': 'Сумська область'},
        {'name': 'Тернопільська область'},
        {'name': 'Харківська область'},
        {'name': 'Херсонська область'},
        {'name': 'Хмельницька область'},
        {'name': 'Черкаська область'},
        {'name': 'Чернівецька область'},
        {'name': 'Чернігівська область'},
        {'name': 'м. Київ'},
      ];

      List<Map<String, dynamic>> regionsToInsert = [];

      for (var regionMap in regionsData) {
        final regionName = regionMap['name'];
        final String nominatimUrl = 'https://nominatim.openstreetmap.org/search';
        final Map<String, String> params = {
          'q': regionName,
          'format': 'json',
          'addressdetails': '1',
          'limit': '1',
          'countrycodes': 'ua',
          'dedupe': '0',
        };
        final uri = Uri.parse(nominatimUrl).replace(queryParameters: params);

        try {
          final response = await http.get(
            uri,
            headers: {
              'User-Agent': 'WithoutNameApp/1.0 (https://yourwebsite.com/contact)',
            },
          );

          if (response.statusCode == 200) {
            List<dynamic> data = json.decode(response.body);
            if (data.isNotEmpty) {
              // Try to find a result that is a state or administrative boundary
              final relevantResult = data.firstWhere(
                (item) => item['addresstype'] == 'state' || (item['class'] == 'boundary' && item['type'] == 'administrative'),
                orElse: () => null,
              );

              if (relevantResult != null && relevantResult['boundingbox'] != null) {
                final bbox = relevantResult['boundingbox'] as List<dynamic>;
                regionMap['min_lat'] = double.tryParse(bbox[0].toString());
                regionMap['max_lat'] = double.tryParse(bbox[1].toString());
                regionMap['min_lon'] = double.tryParse(bbox[2].toString());
                regionMap['max_lon'] = double.tryParse(bbox[3].toString());
                regionsToInsert.add(regionMap);
              } else {
                print('Warning: Bounding box not found for region: $regionName');
                regionsToInsert.add(regionMap); // Add without bbox if not found
              }
            } else {
              print('Warning: No Nominatim result for region: $regionName');
              regionsToInsert.add(regionMap); // Add without bbox if not found
            }
          } else {
            print('Error fetching Nominatim data for $regionName: ${response.statusCode}, ${response.body}');
            regionsToInsert.add(regionMap); // Add without bbox on error
          }
        } catch (e) {
          print('Exception fetching Nominatim data for $regionName: $e');
          regionsToInsert.add(regionMap); // Add without bbox on exception
        }
      }

      // Insert regions into the database
      if (regionsToInsert.isNotEmpty) {
        await _supabaseClient.from('regions').insert(regionsToInsert);
        print('Regions initialized and updated with bounding box data.');
      } else {
        print('No regions to insert or update.');
      }

    } catch (error) {
      print('Error initializing regions: $error');
    }
  }
} 