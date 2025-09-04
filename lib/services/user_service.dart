import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client;
  UserService(this._client);

  Future<void> blockUser(String userId, String reason) async {
    try {
      await _client.from('profiles').update({
        'status': 'blocked',
        'block_reason': reason,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Не вдалося заблокувати користувача: $e');
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _client.from('profiles').update({
        'status': 'active',
        'block_reason': null,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Не вдалося розблокувати користувача: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Видаляємо скарги користувача
      await _client.from('complaints').delete().eq('user_id', userId);
      // Видаляємо оголошення користувача
      await _client.from('listings').delete().eq('user_id', userId);
      // Видаляємо профіль користувача
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Не вдалося видалити користувача: $e');
    }
  }
} 