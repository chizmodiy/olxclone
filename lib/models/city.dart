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
    final address = json['address'] as Map<String, dynamic>?;
    String cityName = '';

    if (address != null) {
      cityName = address['city'] as String? ??
                 address['town'] as String? ??
                 address['village'] as String? ??
                 address['hamlet'] as String? ??
                 address['county'] as String? ?? // Додано для ширшого покриття, якщо застосовно
                 json['name'] as String? ??
                 json['display_name'] as String; // Остання спроба
    } else {
      cityName = json['name'] as String? ?? json['display_name'] as String;
    }

    // Перевірка, що cityName не пусте
    if (cityName.isEmpty) {
      cityName = json['display_name'] as String; // Якщо все інше не вдалось
      if (cityName.isEmpty) {
        print('Warning: City name could not be extracted from Nominatim response: $json');
        cityName = 'Unnamed Location'; // Запасне ім'я, якщо нічого не знайдено
      }
    }

    return City(
      id: json['place_id']?.toString() ?? const Uuid().v4(),
      name: cityName,
      regionId: address?['state'] as String? ?? '', // Використовуємо address.state для regionName
      latitude: double.tryParse(json['lat']?.toString() ?? ''),
      longitude: double.tryParse(json['lon']?.toString() ?? ''),
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