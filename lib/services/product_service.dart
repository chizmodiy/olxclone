import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      final response = await _supabase
          .from('listings')
          .select()
          .in_('id', productIds);
      
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error getting products by IDs: $e');
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
      print('Fetching products with params: limit=$limit, offset=$offset, searchQuery=$searchQuery, categoryId=$categoryId, subcategoryId=$subcategoryId, minPrice=$minPrice, maxPrice=$maxPrice, hasDelivery=$hasDelivery, sortBy=$sortBy, isFree=$isFree, minArea=$minArea, maxArea=$maxArea, minYear=$minYear, maxYear=$maxYear, brand=$brand, minEngineHp=$minEngineHp, maxEngineHp=$maxEngineHp, size=$size, condition=$condition');
      
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

      final response = await query;
      print('Received response: $response');
      
      final products = (response as List).map((json) => Product.fromJson(json)).toList();
      print('Parsed ${products.length} products');
      
      return products;
    } catch (e) {
      print('Error in getProducts: $e');
      throw Exception('Помилка завантаження товарів: $e');
    }
  }
} 