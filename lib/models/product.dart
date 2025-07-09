class Product {
  final String id;
  final String title;
  final String? description;
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
  final Map<String, dynamic>? customAttributes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> photos;
  final bool isNegotiable;

  Product({
    required this.id,
    required this.title,
    this.description,
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
    this.customAttributes,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
    this.isNegotiable = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
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
      customAttributes: json['custom_attributes'] != null 
        ? Map<String, dynamic>.from(json['custom_attributes'] as Map)
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      isNegotiable: json['is_negotiable'] as bool? ?? false,
    );
  }

  String get formattedDate {
    return '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Січня',
      'Лютого',
      'Березня',
      'Квітня',
      'Травня',
      'Червня',
      'Липня',
      'Серпня',
      'Вересня',
      'Жовтня',
      'Листопада',
      'Грудня'
    ];
    return months[month - 1];
  }

  String get formattedPrice {
    if (isFree) return 'Віддам безкоштовно';
    if (isNegotiable) return 'Договірна';
    if (price == null) return 'Ціна не вказана';
    
    final currencySymbol = switch(currency?.toLowerCase()) {
      'uah' => '₴',
      'usd' => '\$',
      'eur' => '€',
      _ => '₴',
    };
    
    return '$currencySymbol${price!.toStringAsFixed(2)}';
  }

  // Додаємо getter для сумісності зі старим кодом
  List<String> get images => photos;
  
  double get priceValue {
    if (isFree) return 0.0;
    return price ?? 0.0;
  }
} 