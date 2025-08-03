class Listing {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String subcategoryId;
  final String location;
  final bool isFree;
  final String? currency;
  final double? price;
  final String? phoneNumber;
  final String? whatsapp;
  final String? telegram;
  final String? viber;
  final String userId;
  final Map<String, dynamic> customAttributes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> photos;
  final bool isNegotiable;
  bool isFavorite;
  final String? address;
  final String? region;
  final double? latitude;
  final double? longitude;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.subcategoryId,
    required this.location,
    required this.isFree,
    this.currency,
    this.price,
    this.phoneNumber,
    this.whatsapp,
    this.telegram,
    this.viber,
    required this.userId,
    required this.customAttributes,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
    this.isNegotiable = false,
    this.isFavorite = false,
    this.address,
    this.region,
    this.latitude,
    this.longitude,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['category_id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      location: json['location'] as String,
      isFree: json['is_free'] as bool,
      currency: json['currency'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      phoneNumber: json['phone_number'] as String?,
      whatsapp: json['whatsapp'] as String?,
      telegram: json['telegram'] as String?,
      viber: json['viber'] as String?,
      userId: json['user_id'] as String,
      customAttributes: json['custom_attributes'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      address: json['address'] as String?,
      region: json['region'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'user_id': userId,
      'custom_attributes': customAttributes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'photos': photos,
      'is_negotiable': isNegotiable,
      'is_favorite': isFavorite,
      'address': address,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get formattedPrice {
    if (isFree) return 'Віддам безкоштовно';
    if (price == null) {
      if (isNegotiable) {
        return 'Договірна';
      }
      return 'Ціна не вказана';
    }
    
    final currencySymbol = switch(currency?.toLowerCase()) {
      'uah' => '₴',
      'usd' => '\$',
      'eur' => '€',
      _ => '₴',
    };
    
    final priceText = '$currencySymbol${price!.toStringAsFixed(2)}';
    
    if (isNegotiable) {
      return '$priceText (Договірна)';
    }
    
    return priceText;
  }
} 