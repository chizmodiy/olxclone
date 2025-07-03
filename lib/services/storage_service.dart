import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _client;
  final String _bucketName = 'images';
  final _uuid = const Uuid();

  StorageService(this._client);

  // Додаємо метод для тестування
  Future<bool> testStorageAccess() async {
    try {
      print('=== Testing Storage Access ===');
      
      // 1. Перевіряємо авторизацію
      final user = _client.auth.currentUser;
      print('Current user: ${user?.id ?? 'Not authenticated'}');
      if (user == null) {
        print('No user authenticated!');
        return false;
      }

      // 2. Створюємо тестовий bucket
      try {
        print('Creating test bucket...');
        await _client.storage.createBucket('test-bucket');
        print('Test bucket created successfully');
      } catch (e) {
        print('Error creating bucket: $e');
      }

      // 3. Отримуємо список всіх buckets
      final buckets = await _client.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.id).join(', ')}');

      return true;
    } catch (e) {
      print('Storage test failed: $e');
      return false;
    }
  }

  Future<String> uploadImage(XFile imageFile) async {
    try {
      // Спочатку перевіряємо доступ до storage
      final hasAccess = await testStorageAccess();
      if (!hasAccess) {
        throw Exception('Немає доступу до Supabase Storage. Перевірте налаштування та авторизацію.');
      }

      print('=== Starting image upload process ===');
      
      // Check if user is authenticated
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Користувач повинен бути авторизований для завантаження зображень');
      }

      // Generate a unique filename
      final String fileName = '${_uuid.v4()}.jpg';
      print('Generated filename: $fileName');

      // Read file bytes
      print('Reading file bytes...');
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Файл порожній');
      }
      print('File size: ${bytes.length} bytes');

      // Try to upload with minimal options first
      print('Uploading file...');
      final result = await _client.storage
          .from(_bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );
      print('Upload successful: $result');

      // Get the public URL
      final imageUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
      print('Generated public URL: $imageUrl');

      return imageUrl;
    } catch (error) {
      print('=== Fatal error in uploadImage ===');
      print('Error type: ${error.runtimeType}');
      print('Error message: $error');
      throw Exception('Помилка завантаження зображення: ${error.toString()}');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      print('Deleting image: $imageUrl');
      final uri = Uri.parse(imageUrl);
      final fileName = path.basename(uri.path);
      print('Extracted filename: $fileName');

      await _client.storage
          .from(_bucketName)
          .remove([fileName]);
      print('Image deleted successfully');
    } catch (error) {
      print('Delete error:');
      print('Error type: ${error.runtimeType}');
      print('Error message: $error');
      throw Exception('Помилка видалення зображення: $error');
    }
  }
} 