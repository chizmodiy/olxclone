import 'package:uuid/uuid.dart';

class Region {
  final String id;
  final String name;

  Region({
    String? id,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
} 