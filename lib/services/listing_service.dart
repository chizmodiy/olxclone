import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import 'package:withoutname/services/category_service.dart'; // Add this import
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
    bool? isNegotiable,
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
      print('Debug: ListingService.createListing - parameters:');
      print('  isFree: $isFree');
      print('  price: $price');
      print('  currency: $currency');
      print('  isNegotiable: $isNegotiable');
      
      // Validate price and currency based on isFree and isNegotiable
      if (isFree) {
        if (price != null && price > 0) {
          throw Exception('Free listings cannot have a positive price');
        }
        // Allow null currency and null price for free listings
      } else {
        if (isNegotiable == true) {
          // For negotiable listings, price can be null or any valid price
          if (price != null && price < 0) {
            throw Exception('Price cannot be negative');
          }
        } else {
          // For non-negotiable listings, price and currency are required
          if (price == null || currency == null) {
            throw Exception('Non-free listings must have price and currency');
          }
          if (price < 0) {
            throw Exception('Price cannot be negative');
          }
        }
      }

      // Get current user
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to create a listing');
      }

      // Upload images first
      final List<String> imageUrls = [];
      if (images.isNotEmpty) {
        for (var image in images) {
          final imageUrl = await _storageService.uploadImage(image);
          imageUrls.add(imageUrl);
        }
      }

      // Create the listing
      final response = await _client.from('listings').insert({
        'title': title,
        'description': description,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'location': location,
        'is_free': isFree,
        'currency': currency,
        'price': price,
        'is_negotiable': isNegotiable ?? false,
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
      
      print('Debug: ListingService.createListing - listing created successfully with ID: $listingId');

      return listingId;
    } catch (error) {
      print('Debug: ListingService.createListing - error: $error');
      throw Exception('Failed to create listing: $error');
    }
  }

  Future<Listing> getListingById(String listingId) async {
    try {
      final response = await _client
          .from('listings')
          .select('*, categories!id(name), subcategories!id(name)') // Fetch category and subcategory names
          .eq('id', listingId)
          .single();
      
      final categoryName = (response['categories'] as Map<String, dynamic>)['name'] as String?;
      final subcategoryName = (response['subcategories'] as Map<String, dynamic>)['name'] as String?;

      return Listing.fromJson({
        ...response,
        'category_name': categoryName,
        'subcategory_name': subcategoryName,
      });
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

  // Оновлений метод для оновлення статусу оголошення
  Future<void> updateListingStatus(String listingId, String status) async {
    try {
      print('=== ОНОВЛЕННЯ СТАТУСУ ОГОЛОШЕННЯ ===');
      print('ID оголошення: $listingId');
      print('Новий статус: $status');
      
      // Спочатку перевіримо поточний статус
      final currentResponse = await _client.from('listings').select('status').eq('id', listingId).single();
      print('Поточний статус: ${currentResponse['status']}');
      
      // Оновлюємо статус
      final updateResponse = await _client.from('listings').update({
        'status': status,
      }).eq('id', listingId);
      
      print('Відповідь оновлення: $updateResponse');
      
      // Перевіряємо оновлений статус
      final updatedResponse = await _client.from('listings').select('status').eq('id', listingId).single();
      print('Оновлений статус: ${updatedResponse['status']}');
      
      print('Статус успішно оновлено на: $status');
    } catch (e) {
      print('Помилка оновлення статусу: $e');
      throw Exception('Не вдалося оновити статус оголошення: $e');
    }
  }

  // Додаємо метод для видалення оголошення
  Future<void> deleteListing(String listingId) async {
    try {
      print('=== ПОЧАТОК ВИДАЛЕННЯ ОГОЛОШЕННЯ ===');
      print('Видалення оголошення з ID: $listingId');
      
      // Перевіряємо поточного користувача
      final user = _client.auth.currentUser;
      print('Поточний користувач: ${user?.id}');
      print('Email користувача: ${user?.email}');
      
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }
      
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
    bool? isNegotiable,
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
      // Validate price and currency based on isFree and isNegotiable
      if (isFree) {
        if (price != null || currency != null) {
          throw Exception('Free listings cannot have price or currency');
        }
      } else {
        if (isNegotiable == true) {
          // For negotiable listings, price can be null or any valid price
          if (price != null && price < 0) {
            throw Exception('Price cannot be negative');
          }
        } else {
          // For non-negotiable listings, price and currency are required
          if (price == null || currency == null) {
            throw Exception('Non-free listings must have price and currency');
          }
          if (price < 0) {
            throw Exception('Price cannot be negative');
          }
        }
      }

      // Get current user
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to update a listing');
      }

      // Upload new images if any
      final List<String> imageUrls = [];
      if (existingImageUrls != null) {
        imageUrls.addAll(existingImageUrls);
      }
      
      if (newImages != null && newImages.isNotEmpty) {
        for (var image in newImages) {
          final imageUrl = await _storageService.uploadImage(image);
          imageUrls.add(imageUrl);
        }
      }

      print('Debug: ListingService.updateListing - updating listing with ID: $listingId');
      
      // Update the listing
      await _client.from('listings').update({
        'title': title,
        'description': description,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'location': location,
        'is_free': isFree,
        'currency': currency,
        'price': price,
        'is_negotiable': isNegotiable ?? false,
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

      print('Debug: ListingService.updateListing - listing updated successfully');
    } catch (error) {
      print('Debug: ListingService.updateListing - error: $error');
      print('Error type: ${error.runtimeType}');
      print('Error details: $error');
      throw Exception('Failed to update listing: $error');
    }
  }
} 