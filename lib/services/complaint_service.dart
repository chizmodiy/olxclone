import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;

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
} 