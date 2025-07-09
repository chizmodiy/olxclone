import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  final SupabaseClient _client;

  ComplaintService(this._client);

  Future<void> createComplaint({
    required String listingId,
    required String title,
    required String description,
    required List<String> types,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to create a complaint');
      }

      await _client.from('complaints').insert({
        'product_id': listingId,
        'user_id': user.id,
        'title': title,
        'description': description,
        'types': types,
      });
    } catch (error) {
      print('Error creating complaint: $error');
      throw Exception('Failed to create complaint: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getUserComplaints() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to view complaints');
      }

      final response = await _client
          .from('complaints')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching user complaints: $error');
      throw Exception('Failed to fetch user complaints: $error');
    }
  }
} 