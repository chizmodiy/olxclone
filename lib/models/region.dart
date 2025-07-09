import 'package:uuid/uuid.dart';

class Region {
  final String id;
  final String name;
  final double? minLat;
  final double? maxLat;
  final double? minLon;
  final double? maxLon;

  Region({
    String? id,
    required this.name,
    this.minLat,
    this.maxLat,
    this.minLon,
    this.maxLon,
  }) : id = id ?? const Uuid().v4();

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
      minLat: json['min_lat'] != null ? double.tryParse(json['min_lat'].toString()) : null,
      maxLat: json['max_lat'] != null ? double.tryParse(json['max_lat'].toString()) : null,
      minLon: json['min_lon'] != null ? double.tryParse(json['min_lon'].toString()) : null,
      maxLon: json['max_lon'] != null ? double.tryParse(json['max_lon'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'min_lat': minLat,
      'max_lat': maxLat,
      'min_lon': minLon,
      'max_lon': maxLon,
    };
  }
} 