import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  final SupabaseClient _client;

  ComplaintService(this._client);

  Future<List<Map<String, dynamic>>> getComplaints() async {
    try {
      // Get complaints with listings join
      final response = await _client
          .from('complaints')
          .select('''
            *,
            listings!inner(
              id,
              title,
              description,
              photos
            )
          ''')
          .order('created_at', ascending: false);

      final complaints = List<Map<String, dynamic>>.from(response);
      
      // Temporary logging to check data structure
      if (complaints.isNotEmpty) {
        print('First complaint structure: ${complaints.first}');
        print('Listings data: ${complaints.first['listings']}');
      }
      
      // For now, let's simplify and just return the basic data without profiles
      // We can add profile data later once we confirm the basic structure works
      return complaints;
      
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