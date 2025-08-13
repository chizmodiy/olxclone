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
      // Пріоритет для українських назв
      cityName = address['city'] as String? ??
                 address['town'] as String? ??
                 address['village'] as String? ??
                 address['hamlet'] as String? ??
                 address['county'] as String? ??
                 json['name'] as String? ??
                 json['display_name'] as String;
    } else {
      cityName = json['name'] as String? ?? json['display_name'] as String;
    }

    // Перевірка, що cityName не пусте
    if (cityName.isEmpty) {
      cityName = json['display_name'] as String;
      if (cityName.isEmpty) {
        cityName = 'Невідома локація'; // Українська назва за замовчуванням
      }
    }

    // Очищення назви від зайвих частин адреси
    if (cityName.contains(',')) {
      cityName = cityName.split(',')[0].trim();
    }
    
    // Видаляємо зайві частини адреси (область, країна тощо)
    final unwantedParts = [
      'Україна', 'Ukraine', 'область', 'області', 'region', 'state',
      'район', 'district', 'місто', 'city', 'село', 'village'
    ];
    
    for (final part in unwantedParts) {
      if (cityName.toLowerCase().contains(part.toLowerCase())) {
        // Якщо це не основна назва міста, а додаткова інформація
        if (cityName.toLowerCase().startsWith(part.toLowerCase())) {
          continue; // Пропускаємо, якщо це початок назви
        }
        // Видаляємо зайві частини
        final parts = cityName.split(',');
        cityName = parts.first.trim();
        break;
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