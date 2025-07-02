import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcategory.dart';

class SubcategoryService {
  final SupabaseClient _supabase;

  SubcategoryService(this._supabase);

  Future<List<Subcategory>> getSubcategoriesForCategory(String categoryId) async {
    try {
      print('Fetching subcategories for category: $categoryId');
      final response = await _supabase
          .from('subcategories')
          .select()
          .eq('category_id', categoryId)
          .order('name');
      
      print('Response from Supabase: $response');
      
      final subcategories = (response as List<dynamic>)
          .map((json) => Subcategory.fromJson(json))
          .toList();
          
      print('Parsed subcategories: ${subcategories.map((c) => c.name).toList()}');
      
      return subcategories;
    } catch (error) {
      print('Error fetching subcategories: $error');
      rethrow;
    }
  }

  Future<List<Subcategory>> getAllSubcategories() async {
    try {
      print('Fetching all subcategories');
      final response = await _supabase
          .from('subcategories')
          .select()
          .order('name');
      
      print('Response from Supabase: $response');
      
      return (response as List<dynamic>)
          .map((json) => Subcategory.fromJson(json))
          .toList();
    } catch (error) {
      print('Error fetching all subcategories: $error');
      rethrow;
    }
  }
} 