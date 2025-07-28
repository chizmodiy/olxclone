import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import '../models/listing.dart'; // Added this import

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
    String? address,
    String? region,
    double? latitude,
    double? longitude,
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
        'address': address,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
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

  Future<Listing> getListingById(String listingId) async {
    try {
      final response = await _client
          .from('listings')
          .select()
          .eq('id', listingId)
          .single();
      return Listing.fromJson(response);
    } catch (error) {
      throw Exception('Failed to fetch listing: $error');
    }
  }

  Future<Map<String, double>> getMinMaxPrices(String currency) async {
    try {
      // Get min price
      final minResponse = await _client
          .from('listings')
          .select('price')
          .eq('currency', currency)
          .not('price', 'is', null) // Exclude null prices
          .order('price', ascending: true)
          .limit(1)
          .single();

      final double minPrice = (minResponse['price'] as num?)?.toDouble() ?? 0.0;

      // Get max price
      final maxResponse = await _client
          .from('listings')
          .select('price')
          .eq('currency', currency)
          .not('price', 'is', null) // Exclude null prices
          .order('price', ascending: false)
          .limit(1)
          .single();

      final double maxPrice = (maxResponse['price'] as num?)?.toDouble() ?? 100.0; // Default max if no listings

      return {
        'minPrice': minPrice,
        'maxPrice': maxPrice,
      };
    } catch (error) {
      print('Error fetching min/max prices: $error');
      // Return default values in case of an error or no listings
      return {'minPrice': 0.0, 'maxPrice': 100.0};
    }
  }

  // Оновлений метод для оновлення статусу оголошення з merge custom_attributes
  Future<void> updateListingStatus(String listingId, String status) async {
    try {
      // Отримати поточні custom_attributes
      final response = await _client
          .from('listings')
          .select('custom_attributes')
          .eq('id', listingId)
          .single();
      final Map<String, dynamic> currentAttributes =
          (response['custom_attributes'] as Map<String, dynamic>? ?? {});
      // Оновити статус, зберігаючи інші атрибути
      final updatedAttributes = Map<String, dynamic>.from(currentAttributes)
        ..['status'] = status;
      await _client.from('listings').update({
        'custom_attributes': updatedAttributes,
      }).eq('id', listingId);
    } catch (e) {
      throw Exception('Не вдалося оновити статус оголошення: $e');
    }
  }

  // Додаємо метод для видалення оголошення
  Future<void> deleteListing(String listingId) async {
    try {
      await _client.from('listings').delete().eq('id', listingId);
    } catch (e) {
      throw Exception('Не вдалося видалити оголошення: $e');
    }
  }

  // Додаємо метод для оновлення оголошення
  Future<void> updateListing({
    required String listingId,
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
    String? address,
    String? region,
    double? latitude,
    double? longitude,
    required Map<String, dynamic> customAttributes,
    List<XFile>? newImages,
    List<String>? existingImageUrls,
  }) async {
    try {
      print('=== Starting updateListing process ===');
      
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
        throw Exception('User must be logged in to update a listing');
      }
      print('Current user ID: ${user.id}');

      // Upload new images if any
      final List<String> imageUrls = [];
      if (existingImageUrls != null) {
        imageUrls.addAll(existingImageUrls);
      }
      
      if (newImages != null && newImages.isNotEmpty) {
        print('Uploading ${newImages.length} new images');
        for (var image in newImages) {
          print('Uploading image: ${image.name}');
          final imageUrl = await _storageService.uploadImage(image);
          print('Image uploaded successfully: $imageUrl');
          imageUrls.add(imageUrl);
        }
        print('All new images uploaded successfully');
      }

      // Update the listing
      print('Updating listing record...');
      await _client.from('listings').update({
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
        'custom_attributes': customAttributes,
        'photos': imageUrls,
        'address': address,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', listingId);

      print('Listing updated successfully');
    } catch (error) {
      print('=== Error in updateListing ===');
      print('Error type: ${error.runtimeType}');
      print('Error details: $error');
      throw Exception('Failed to update listing: $error');
    }
  }
} 