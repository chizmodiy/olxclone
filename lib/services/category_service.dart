import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name');
      
      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Category>> getSubcategories(String categoryId) async {
    try {
      final response = await _supabase
          .from('subcategories')
          .select()
          .eq('category_id', categoryId)
          .order('name');
      
      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching subcategories: $e');
      return [];
    }
  }

  Future<String> getCategoryName(String categoryId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .single();
      
      return response['name'] as String;
    } catch (e) {
      return 'Інше';
    }
  }

  Future<String> getSubcategoryName(String subcategoryId) async {
    try {
      final response = await _supabase
          .from('subcategories')
          .select('name')
          .eq('id', subcategoryId)
          .single();
      
      return response['name'] as String;
    } catch (e) {
      return 'Інше';
    }
  }

  // Кешування для оптимізації
  final Map<String, String> _categoryCache = {};
  final Map<String, String> _subcategoryCache = {};

  Future<String> getCategoryNameCached(String categoryId) async {
    if (_categoryCache.containsKey(categoryId)) {
      return _categoryCache[categoryId]!;
    }
    
    final name = await getCategoryName(categoryId);
    _categoryCache[categoryId] = name;
    return name;
  }

  Future<String> getSubcategoryNameCached(String subcategoryId) async {
    if (_subcategoryCache.containsKey(subcategoryId)) {
      return _subcategoryCache[subcategoryId]!;
    }
    
    final name = await getSubcategoryName(subcategoryId);
    _subcategoryCache[subcategoryId] = name;
    return name;
  }
} 