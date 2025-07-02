import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseClient _supabase;

  CategoryService(this._supabase);

  Future<List<Category>> getCategories() async {
    try {
      print('Fetching categories from Supabase...');
      final response = await _supabase
          .from('categories')
          .select()
          .order('name');
      
      print('Response from Supabase: $response');
      
      final categories = (response as List<dynamic>)
          .map((json) => Category.fromJson(json))
          .toList();
          
      print('Parsed categories: ${categories.map((c) => c.name).toList()}');
      
      return categories;
    } catch (error) {
      print('Error fetching categories: $error');
      rethrow;
    }
  }
} 