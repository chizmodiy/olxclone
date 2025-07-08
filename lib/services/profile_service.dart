import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> getUser(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response != null ? UserProfile.fromJson(response as Map<String, dynamic>) : null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      print('No current user available.');
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
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

  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    }
  }
} 