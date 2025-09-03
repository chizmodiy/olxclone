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
              photos,
              price,
              is_free,
              location,
              created_at,
              status
            )
          ''')
          .order('created_at', ascending: false);

      final complaints = List<Map<String, dynamic>>.from(response);
      
      // Temporary logging to check data structure
      if (complaints.isNotEmpty) {
        print('First complaint structure: ${complaints.first}');
        print('Listings data: ${complaints.first['listings']}');
      }
      
      // Get user profiles for all complaints
      final userIds = complaints.map((c) => c['user_id']).toSet().toList();
      final profilesResponse = await _client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url')
          .in_('id', userIds);
      
      final profiles = Map<String, Map<String, dynamic>>.fromEntries(
        (profilesResponse as List).map((p) => MapEntry(p['id'], p))
      );
      
      // Merge profile data into complaints
      for (final complaint in complaints) {
        final userId = complaint['user_id'];
        final profile = profiles[userId];
        if (profile != null) {
          complaint['user_profile'] = profile;
        }
      }
      
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