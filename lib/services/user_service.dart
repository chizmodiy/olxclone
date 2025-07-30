import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client;
  UserService(this._client);

  Future<void> blockUser(String userId) async {
    print('[USER_SERVICE] blockUser: userId=$userId');
    try {
      await _client.from('profiles').update({'status': 'blocked'}).eq('id', userId);
      print('[USER_SERVICE] User blocked successfully');
    } catch (e) {
      print('[USER_SERVICE] ERROR blocking user: $e');
      throw Exception('Не вдалося заблокувати користувача: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    print('[USER_SERVICE] deleteUser: userId=$userId');
    try {
      // Видаляємо скарги користувача
      await _client.from('complaints').delete().eq('user_id', userId);
      print('[USER_SERVICE] Complaints deleted');
      // Видаляємо оголошення користувача
      await _client.from('listings').delete().eq('user_id', userId);
      print('[USER_SERVICE] Listings deleted');
      // Видаляємо профіль користувача
      await _client.from('profiles').delete().eq('id', userId);
      print('[USER_SERVICE] Profile deleted');
    } catch (e) {
      print('[USER_SERVICE] ERROR deleting user: $e');
      throw Exception('Не вдалося видалити користувача: $e');
    }
  }
} 