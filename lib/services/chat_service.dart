import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> hasUnreadMessages() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    final response = await _client
        .from('chat_messages')
        .select('id')
        .eq('is_read', false)
        .neq('sender_id', currentUser.id)
        .limit(1)
        .maybeSingle();

    return response != null;
  }
} 