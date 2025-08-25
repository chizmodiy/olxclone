import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class AlgoliaService {
  static const String appId = 'XYA8SCV3KC';
  static const String searchKey = '6782ed5c8812fb117b825a5890912b31';
  static const String indexName = 'products';

  Future<List<Product>> searchProducts({
    String? query,
    String? categoryId,
    String? region,
    bool? isFree,
    double? minPrice,
    double? maxPrice,
    int limit = 10,
  }) async {
    try {
      final url = 'https://$appId-dsn.algolia.net/1/indexes/$indexName/query';
      
      // Будуємо фільтри
      final filters = <String>[];
      
      if (categoryId != null) {
        filters.add('category_id:$categoryId');
      }
      
      if (region != null) {
        filters.add('region:$region');
      }
      
      if (isFree != null) {
        filters.add('is_free:$isFree');
      }
      
      if (minPrice != null || maxPrice != null) {
        if (minPrice != null && maxPrice != null) {
          filters.add('price:$minPrice TO $maxPrice');
        } else if (minPrice != null) {
          filters.add('price >= $minPrice');
        } else if (maxPrice != null) {
          filters.add('price <= $maxPrice');
        }
      }
      
      // Додаємо фільтр активних оголошень (тільки якщо є інші фільтри)
      if (filters.isNotEmpty) {
        filters.add('(status:active OR status:null)');
      }
      
      final filterString = filters.join(' AND ');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Algolia-API-Key': searchKey,
          'X-Algolia-Application-Id': appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query ?? '',
          'filters': filterString,
          'hitsPerPage': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>;
        
        return hits.map((hit) => Product.fromJson(hit)).toList();
      } else {
        return [];
      }
      
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> searchByLocation({
    required double latitude,
    required double longitude,
    int radiusInKm = 50,
    String? query,
    int limit = 10,
  }) async {
    try {
      final url = 'https://$appId-dsn.algolia.net/1/indexes/$indexName/query';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Algolia-API-Key': searchKey,
          'X-Algolia-Application-Id': appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query ?? '',
          'aroundLatLng': '$latitude,$longitude',
          'aroundRadius': radiusInKm * 1000, // в метрах
          'filters': '(status:active OR status:null)',
          'hitsPerPage': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>;
        
        return hits.map((hit) => Product.fromJson(hit)).toList();
      } else {
        return [];
      }
      
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getFacets() async {
    try {
      final url = 'https://$appId-dsn.algolia.net/1/indexes/$indexName/query';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Algolia-API-Key': searchKey,
          'X-Algolia-Application-Id': appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': '',
          'facets': ['category_name', 'region', 'is_free'],
          'hitsPerPage': 0, // Тільки фасети
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['facets'] ?? {};
      } else {
        return {};
      }
      
    } catch (e) {
      return {};
    }
  }
} 