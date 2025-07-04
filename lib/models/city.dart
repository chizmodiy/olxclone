import 'package:uuid/uuid.dart';

class City {
  final String id;
  final String name;
  final String regionId; // Still useful for initial filtering/context
  final double? latitude;
  final double? longitude;

  City({
    String? id,
    required this.name,
    required this.regionId,
    this.latitude,
    this.longitude,
  }) : id = id ?? const Uuid().v4();

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['place_id']?.toString() ?? const Uuid().v4(), // Use Nominatim place_id or generate new UUID
      name: json['name'] as String? ?? json['display_name'] as String,
      regionId: json['region_id'] as String? ?? '', // Will need to pass this or infer
      latitude: double.tryParse(json['lat'] as String),
      longitude: double.tryParse(json['lon'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region_id': regionId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
} 