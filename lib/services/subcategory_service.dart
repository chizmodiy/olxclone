import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcategory.dart';

class SubcategoryService {
  final SupabaseClient _supabase;

  SubcategoryService(this._supabase);

  Future<List<Subcategory>> getSubcategoriesForCategory(String categoryId) async {
    try {
  
      final response = await _supabase
          .from('subcategories')
          .select()
          .eq('category_id', categoryId)
          .order('name');
      
      final subcategories = (response as List<dynamic>)
          .map((json) => Subcategory.fromJson(json))
          .toList();
      
      return subcategories;
    } catch (error) {

      rethrow;
    }
  }

  Future<List<Subcategory>> getAllSubcategories() async {
    try {

      final response = await _supabase
          .from('subcategories')
          .select()
          .order('name');
      

      
      return (response as List<dynamic>)
          .map((json) => Subcategory.fromJson(json))
          .toList();
    } catch (error) {

      rethrow;
    }
  }
} 