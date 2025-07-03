import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? sortBy,
    bool? isGrid,
  }) async {
    try {
      print('=== Starting getProducts ===');
      print('Page: $page, Limit: $limit');

      // Build the query
      PostgrestTransformBuilder<dynamic> query = _client
          .from('listings')
          .select('*'); // Select all columns, including 'photos'
      
      // Apply sorting based on sortBy parameter
      if (sortBy == 'price_asc') {
        query = query.order('price', ascending: true);
      } else if (sortBy == 'price_desc') {
        query = query.order('price', ascending: false);
      } else {
        // Default sorting by creation date if no specific sort is provided or recognized
        query = query.order('created_at', ascending: false);
      }

      // Add pagination
      query = query.range((page - 1) * limit, page * limit - 1);

      print('Executing query...');
      final response = await query;
      print('Got ${response.length} listings');

      // Convert response to List<Product>
      // Explicitly specify the type for map to help with type inference
      return response.map<Product>((json) {
        // Extract photos directly from the 'photos' column
        final photos = (json['photos'] as List<dynamic>?)
            ?.cast<String>()
            .toList() ?? [];

        print('Listing ${json['id']} has ${photos.length} photos');

        // Format price string
        final priceValue = json['price'];
        final currencyValue = json['currency'];
        final isFree = json['is_free'] as bool? ?? false;

        final priceString = isFree
            ? 'Безкоштовно'
            : (priceValue != null 
                ? '${priceValue}${_getCurrencySymbol(currencyValue)}'
                : 'Ціна не вказана'); // Handle null price for non-free items

        // Create a new map with the correct structure for Product.fromJson
        final productJson = {
          'id': json['id'],
          'title': json['title'],
          'price': priceString,
          'created_at': json['created_at'],
          'location': json['location'],
          'images': photos,
          'is_negotiable': json['is_free'] ? false : (json['is_negotiable'] ?? false),
        };

        return Product.fromJson(productJson);
      }).toList();
    } catch (e) {
      print('=== Error in getProducts ===');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  String _getCurrencySymbol(String? currency) {
    switch (currency) {
      case 'UAH':
        return '₴';
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return '';
    }
  }
} 