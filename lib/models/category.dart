import 'package:flutter/foundation.dart';

class Category {
  final String id;
  final String name;
  final String? iconPath;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    this.iconPath,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconPath: json['icon_path'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_path': iconPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }
} 