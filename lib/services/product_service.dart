import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'package:algoliasearch/algoliasearch.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Algolia configuration
  static const String algoliaAppId = '0OP1H6TEU7';
  static const String algoliaSearchKey = '69c4afc3b8918ea3c03c0f6c11e8fc72';
  static const String algoliaIndexName = 'products';

  final SearchClient searchClient = SearchClient(
    appId: algoliaAppId,
    apiKey: algoliaSearchKey,
  );

  Future<Product> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('listings')
          .select()
          .eq('id', id)
          .single();
      
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Помилка завантаження товару: $e');
    }
  }

  Future<List<Product>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }
    try {
      print('Debug: Fetching products with IDs: $productIds');
      final response = await _supabase
          .from('listings')
          .select()
          .in_('id', productIds);
      
      print('Debug: Raw response: $response');
      final products = (response as List).map((json) => Product.fromJson(json)).toList();
      print('Debug: Parsed ${products.length} products');
      return products;
    } catch (e) {
      print('Debug: Error in getProductsByIds: $e');
      return [];
    }
  }

  Future<List<Product>> getProducts({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
    String? categoryId,
    String? subcategoryId,
    double? minPrice,
    double? maxPrice,
    bool? hasDelivery,
    String? sortBy,
    bool? isFree,
    double? minArea,
    double? maxArea,
    double? minYear,
    double? maxYear,
    String? brand,
    double? minEngineHp,
    double? maxEngineHp,
    String? size,
    String? condition,
  }) async {
    try {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // --- ALGOLIA SEARCH ---
        final response = await searchClient.searchIndex(
          request: SearchForHits(
            indexName: algoliaIndexName,
            query: searchQuery,
          ),
        );
        final hits = response.hits;

        return hits.map((hit) => Product.fromJson(hit)).toList();
      } else {
        // --- SUPABASE SEARCH (fallback) ---


        PostgrestFilterBuilder query = _supabase.from('listings').select();

        // Додаємо умови пошуку
        if (searchQuery != null && searchQuery.isNotEmpty) {
          query = query.ilike('title', '%$searchQuery%');
        }

        if (categoryId != null) {
          query = query.eq('category_id', categoryId);
        }

        if (subcategoryId != null) {
          query = query.eq('subcategory_id', subcategoryId);
        }

        if (minPrice != null) {
          query = query.gte('price', minPrice);
        }

        if (maxPrice != null) {
          query = query.lte('price', maxPrice);
        }

        if (hasDelivery != null) {
          // Assuming 'has_delivery' is a boolean field in your database
          // You might need to adjust this based on your actual schema for delivery
          query = query.eq('has_delivery', hasDelivery);
        }

        if (isFree != null) {
          query = query.eq('is_free', isFree);
        }

        // Add area filters for custom attributes
        if (minArea != null || maxArea != null) {
          // Filter by area in custom_attributes JSON field
          if (minArea != null) {
            query = query.gte('custom_attributes->area', minArea);
          }
          if (maxArea != null) {
            query = query.lte('custom_attributes->area', maxArea);
          }
        }

        // Add car filters for custom attributes
        if (minYear != null || maxYear != null) {
          if (minYear != null) {
            query = query.gte('custom_attributes->year', minYear);
          }
          if (maxYear != null) {
            query = query.lte('custom_attributes->year', maxYear);
          }
        }

        if (brand != null) {
          query = query.eq('custom_attributes->car_brand', brand);
        }

        if (minEngineHp != null || maxEngineHp != null) {
          if (minEngineHp != null) {
            query = query.gte('custom_attributes->engine_power_hp', minEngineHp);
          }
          if (maxEngineHp != null) {
            query = query.lte('custom_attributes->engine_power_hp', maxEngineHp);
          }
        }

        // Add fashion filters for custom attributes
        if (size != null) {
          query = query.eq('custom_attributes->size', size);
        }

        if (condition != null) {
          query = query.eq('custom_attributes->condition', condition);
        }

        // Додаємо сортування
        if (sortBy == 'price_asc') {
          query = query.order('price', ascending: true) as PostgrestFilterBuilder;
        } else if (sortBy == 'price_desc') {
          query = query.order('price', ascending: false) as PostgrestFilterBuilder;
        } else {
          query = query.order('created_at', ascending: false) as PostgrestFilterBuilder;
        }

        // Додаємо пагінацію
        query = query.range(offset, offset + limit - 1) as PostgrestFilterBuilder;

        // Return Supabase results
        final data = await query as List<dynamic>;
        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getAllProductsWithCoordinates() async {
    try {
      final response = await _supabase
          .from('listings')
          .select()
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateProduct({
    required String id,
    required String title,
    String? description,
    required String categoryId,
    required String subcategoryId,
    required String location,
    required bool isFree,
    String? currency,
    double? price,
    String? phoneNumber,
    String? whatsapp,
    String? telegram,
    String? viber,
    String? address,
    String? region,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? customAttributes,
  }) async {
    try {
      await _supabase.from('listings').update({
        'title': title,
        'description': description,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'location': location,
        'is_free': isFree,
        'currency': currency,
        'price': price,
        'phone_number': phoneNumber,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'viber': viber,
        'address': address,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
        'custom_attributes': customAttributes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Помилка оновлення товару: $e');
    }
  }
}