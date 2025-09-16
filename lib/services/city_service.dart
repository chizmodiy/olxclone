import '../models/city.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CityService {
  CityService();

  Future<List<City>> searchCities(String query, {String? regionName, double? minLat, double? maxLat, double? minLon, double? maxLon}) async {
    if (query.isEmpty) {
      if (regionName != null && regionName.isNotEmpty && minLat == null) {
        // This case indicates an initial search without bounding box data yet, or a fallback.
        // We will now always aim to use bounding box if available.
      } else if (minLat == null || maxLat == null || minLon == null || maxLon == null) {
        // If query is empty and bounding box is not fully provided, return empty list
        return [];
      }
    }

    final String nominatimUrl = 'https://nominatim.openstreetmap.org/search';
    final Map<String, String> params = {
      'format': 'json',
      'addressdetails': '1',
      'limit': '100', // Increased limit to get more results within a bounding box
      'countrycodes': 'ua', // Limit results to Ukraine
      'accept-language': 'uk', // Request Ukrainian language
    };

    // Add viewbox if bounding box coordinates are provided
    if (minLat != null && maxLat != null && minLon != null && maxLon != null) {
      // Nominatim viewbox order: left,top,right,bottom (minlon,maxlat,maxlon,minlat)
      params['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
      params['bounded'] = '1'; // Limit results to the bounding box
    }

    if (query.isNotEmpty) {
      params['q'] = query;
    } else if (regionName != null && regionName.isNotEmpty && (minLat == null || maxLat == null || minLon == null || maxLon == null)) {
        // Fallback for initial search if no bbox, but we have region name
        params['q'] = regionName; // This will return the region itself, as observed before
    } else if (query.isEmpty && minLat != null && maxLat != null && minLon != null && maxLon != null) {
        // If query is empty but bbox is present, search for general settlements within the bbox
        // Nominatim doesn't have a direct 'featuretype=settlement' filter via /search
        // We will rely on post-processing for this, but can add a general query to help if needed
        // For now, let's leave 'q' empty if there's no specific query and we're bounded by viewbox.
    }


    final uri = Uri.parse(nominatimUrl).replace(queryParameters: params);


    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ZENOApp/1.0 (https://yourwebsite.com/contact)', // Replace with your app contact info
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Filter and sort cities alphabetically by name
        List<City> cities = [];
        Set<String> uniqueNames = {}; // Для уникнення дублікатів
        
        for (var item in data) {
          final String? nominatimClass = item['class'];
          final String? nominatimType = item['type'];
          final int? placeRank = item['place_rank'];

          // Refined filtering: only include relevant settlement types
          bool isSettlement = false;

          // Prioritize place types like city, town, village, hamlet
          if (nominatimClass == 'place' &&
              (nominatimType == 'city' || nominatimType == 'town' || nominatimType == 'village' || nominatimType == 'hamlet')) {
            isSettlement = true;
          } else if (nominatimClass == 'boundary' && nominatimType == 'administrative' && placeRank != null && placeRank >= 16 && placeRank <= 20) {
              // Also consider administrative boundaries if they have settlement-like place ranks
              final address = item['address'] as Map<String, dynamic>?;
              if (address != null && (address.containsKey('city') || address.containsKey('town') || address.containsKey('village') || address.containsKey('hamlet'))) {
                  isSettlement = true;
              }
          }

          if (isSettlement) {
            try {
              final city = City.fromJson(item);
              // Перевіряємо, чи не є це дублікатом
              if (!uniqueNames.contains(city.name) && city.name.isNotEmpty) {
                uniqueNames.add(city.name);
                cities.add(city);
              }
            } catch (e) {
              // Error parsing city
            }
          }
        }
        cities.sort((a, b) => a.name.compareTo(b.name));
        return cities;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
} 