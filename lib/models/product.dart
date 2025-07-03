class Product {
  final String id;
  final String title;
  final String price;
  final DateTime createdAt;
  final String location;
  final List<String> images;
  final bool isNegotiable;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.createdAt,
    required this.location,
    required this.images,
    this.isNegotiable = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      price: json['price'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      location: json['location'] as String,
      images: (json['images'] as List<dynamic>).cast<String>(),
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
} 