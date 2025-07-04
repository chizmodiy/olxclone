import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';

enum CurrencyEnum {
  UAH,
  EUR,
  USD,
}

class ListingService {
  final SupabaseClient _client;
  late final StorageService _storageService;

  ListingService(this._client) {
    _storageService = StorageService(_client);
  }

  Future<String> createListing({
    required String title,
    required String description,
    required String categoryId,
    required String subcategoryId,
    required String location,
    required bool isFree,
    String? currency,
    double? price,
    String? phoneNumber,
    String? whatsapp,
    String? telegram,
    String? viber,
    required Map<String, dynamic> customAttributes,
    required List<XFile> images,
  }) async {
    try {
      print('=== Starting createListing process ===');
      
      // Validate price and currency based on isFree
      if (isFree) {
        if (price != null || currency != null) {
          throw Exception('Free listings cannot have price or currency');
        }
      } else {
        if (price == null || currency == null) {
          throw Exception('Non-free listings must have price and currency');
        }
        if (price < 0) {
          throw Exception('Price cannot be negative');
        }
      }

      // Get current user
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to create a listing');
      }
      print('Current user ID: ${user.id}');

      // Upload images first
      print('Starting image upload process...');
      final List<String> imageUrls = [];
      if (images.isNotEmpty) {
        print('Uploading ${images.length} images');
        for (var image in images) {
          print('Uploading image: ${image.name}');
          final imageUrl = await _storageService.uploadImage(image);
          print('Image uploaded successfully: $imageUrl');
          imageUrls.add(imageUrl);
        }
        print('All images uploaded successfully');
      }

      // Create the listing
      print('Creating listing record...');
      final response = await _client.from('listings').insert({
        'title': title,
        'description': description,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'location': location,
        'is_free': isFree,
        'currency': currency,
        'price': price,
        'phone_number': phoneNumber,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'viber': viber,
        'user_id': user.id,
        'custom_attributes': customAttributes,
        'photos': imageUrls, // Store image URLs directly in the listings table
      }).select('id').single();

      final listingId = response['id'] as String;
      print('Listing created with ID: $listingId');

      return listingId;
    } catch (error) {
      print('=== Error in createListing ===');
      print('Error type: ${error.runtimeType}');
      print('Error details: $error');
      throw Exception('Failed to create listing: $error');
    }
  }
} 