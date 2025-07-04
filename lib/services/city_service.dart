import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CityService {
  CityService();

  Future<List<City>> getCitiesForRegion(String regionName, {String? query}) async {
    try {
      String url = 'https://nominatim.openstreetmap.org/search?';
      Map<String, String> params = {
        'format': 'json',
        'countrycodes': 'ua', // Use countrycodes for hard country filter
        'addressdetails': '1',
        'limit': '50',
        'dedupe': '1',
        'accept-language': 'uk',
      };

      String searchString;
      if (query != null && query.isNotEmpty) {
        // Search for the query within the region, explicitly mentioning the region and country in the query string
        searchString = '$query, $regionName, Україна';
      } else {
        // If no specific city query, search broadly for places within the region
        searchString = '$regionName, Україна';
      }
      params['q'] = searchString; // Use 'q' for free-form search

      final uri = Uri.parse(url).replace(queryParameters: params);
      
      final response = await http.get(uri, headers: {
        'User-Agent': 'WithoutNameApp/1.0 (your_email@example.com)', // Please replace with your actual email
      });

      print('Nominatim API URL: $uri');
      print('Nominatim API Response Status: ${response.statusCode}');
      print('Nominatim API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<City> cities = [];
        for (var item in data) {
          // Filter by relevant types and ensure the city belongs to the selected region based on address details
          // Nominatim's 'state' field often corresponds to regions in Ukraine.
          // 'county' might sometimes contain district/raion information which can also be part of the region name.
          bool isSettlement = (item['type'] == 'city' ||
                  item['type'] == 'town' ||
                  item['type'] == 'village' ||
                  item['type'] == 'hamlet' ||
                  item['type'] == 'administrative' || // e.g., district centers
                  item['type'] == 'county'); // e.g., district names that are also settlements

          if (isSettlement && item['name'] != null && item['address'] != null) {
            String stateInAddress = item['address']['state']?.toLowerCase() ?? '';
            String countyInAddress = item['address']['county']?.toLowerCase() ?? '';
            String regionNameLower = regionName.toLowerCase();

            // Check if the region name is present in the 'state' or 'county' field of the address details
            // Or if the display name explicitly contains the region name (e.g., "Kyiv, Kyiv Oblast")
            if (stateInAddress == regionNameLower ||
                countyInAddress == regionNameLower ||
                item['display_name'].toLowerCase().contains(regionNameLower.replaceAll(' область', ''))) { // Remove " область" for broader matching
              cities.add(City.fromJson(item));
            }
          }
        }
        cities.sort((a, b) => a.name.compareTo(b.name));
        print('Кількість розпарсених міст: ${cities.length}');
        return cities;
      } else {
        print('Failed to load cities from Nominatim: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching cities from Nominatim: $error');
      return [];
    }
  }
} 