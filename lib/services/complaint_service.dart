import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  final SupabaseClient _client;

  ComplaintService(this._client);

  Future<List<Map<String, dynamic>>> getComplaints() async {
    try {
      final response = await _client
          .from('complaints')
          .select('''
            *,
            listings!inner(
              id,
              title,
              description
            ),
            profiles!inner(
              id,
              full_name,
              email
            )
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Не вдалося отримати скарги: $e');
    }
  }

  Future<void> createComplaint({
    required String listingId,
    required String title,
    required String description,
    required List<String> types,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('complaints').insert({
      'listing_id': listingId,
      'user_id': userId,
      'title': title,
      'description': description,
      'types': types,
    });
  }

  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _client.from('complaints').delete().eq('id', complaintId);
    } catch (e) {
      throw Exception('Не вдалося видалити скаргу: $e');
    }
  }
} 