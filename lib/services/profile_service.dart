import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  Future<UserProfile?> getUser(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final userProfile = response != null ? UserProfile.fromJson(response as Map<String, dynamic>) : null;
      
      return userProfile;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
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
    // Обробляємо avatarUrl окремо, щоб можна було встановити null
    updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    }
  }

  Future<void> addToViewedList(String listingId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // First get current viewed_list
      final response = await _client
          .from('profiles')
          .select('viewed_list')
          .eq('id', userId)
          .single();

      List<String> currentList = List<String>.from(response['viewed_list'] ?? []);
      
      // Add new listing to the beginning if not already present
      if (!currentList.contains(listingId)) {
        currentList.insert(0, listingId);
      }

      // Update the profile with new list
      await _client
          .from('profiles')
          .update({
            'viewed_list': currentList
          })
          .eq('id', userId);
    } catch (e) {
      // Error adding to viewed list
    }
  }

  Future<List<String>> getViewedList() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('profiles')
          .select('viewed_list')
          .eq('id', userId)
          .single();
      
      return List<String>.from(response['viewed_list'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<String?> getUserStatus() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .single();
      
      return response['status'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('status, block_reason')
          .eq('id', userId)
          .single();
      
      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
} 