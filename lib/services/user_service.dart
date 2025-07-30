import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client;
  UserService(this._client);

  Future<void> blockUser(String userId) async {
    try {
      await _client.from('profiles').update({'status': 'blocked'}).eq('id', userId);
    } catch (e) {
      throw Exception('Не вдалося заблокувати користувача: $e');
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