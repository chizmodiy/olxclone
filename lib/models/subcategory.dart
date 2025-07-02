class Subcategory {
  final String id;
  final String name;
  final String categoryId;
  final DateTime? createdAt;

  Subcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.createdAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
} 