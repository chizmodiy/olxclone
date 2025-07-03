import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> _getProfile() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      print('No current user available.');
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select('favorite_products')
          .eq('id', currentUser.id)
          .single();
      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<Set<String>> getFavoriteProductIds() async {
    final profile = await _getProfile();
    if (profile == null || profile['favorite_products'] == null) {
      return {};
    }
    final List<dynamic> favs = profile['favorite_products'];
    return favs.cast<String>().toSet();
  }

  Future<void> addFavoriteProduct(String productId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    final currentFavorites = await getFavoriteProductIds();
    if (currentFavorites.add(productId)) { // Only update if product was not already in favorites
      await _client
          .from('profiles')
          .update({'favorite_products': currentFavorites.toList()})
          .eq('id', currentUser.id);
    }
  }

  Future<void> removeFavoriteProduct(String productId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    final currentFavorites = await getFavoriteProductIds();
    if (currentFavorites.remove(productId)) { // Only update if product was in favorites
      await _client
          .from('profiles')
          .update({'favorite_products': currentFavorites.toList()})
          .eq('id', currentUser.id);
    }
  }
} 