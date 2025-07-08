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

  Future<List<Product>> getProductsByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];

      final response = await _supabase
          .from('listings')
          .select()
          .in_('id', ids);
      
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Помилка завантаження товарів: $e');
    }
  }

  Future<List<Product>> getProducts({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
    String? categoryId,
    String? sortBy,
    bool? isFree,
  }) async {
    try {
      print('Fetching products with params: limit=$limit, offset=$offset, searchQuery=$searchQuery, categoryId=$categoryId, sortBy=$sortBy, isFree=$isFree');
      
      PostgrestFilterBuilder query = _supabase.from('listings').select();

      // Додаємо умови пошуку
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%') as PostgrestFilterBuilder;
      }

      if (categoryId != null) {
        query = query.eq('category_id', categoryId) as PostgrestFilterBuilder;
      }

      if (isFree != null) {
        query = query.eq('is_free', isFree) as PostgrestFilterBuilder;
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