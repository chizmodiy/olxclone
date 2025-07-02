import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';

class RegionService {
  final SupabaseClient _supabaseClient;

  RegionService(this._supabaseClient);

  Future<List<Region>> getRegions() async {
    try {
      final response = await _supabaseClient
          .from('regions')
          .select()
          .order('name');

      return (response as List<dynamic>)
          .map((json) => Region.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      print('Error fetching regions: $error');
      return [];
    }
  }

  Future<void> initializeRegions() async {
    try {
      // Check if regions already exist
      final existing = await _supabaseClient.from('regions').select('id');
      if ((existing as List).isNotEmpty) {
        return; // Regions already initialized
      }

      // List of Ukrainian regions
      final regions = [
        {'name': 'Вінницька область'},
        {'name': 'Волинська область'},
        {'name': 'Дніпропетровська область'},
        {'name': 'Донецька область'},
        {'name': 'Житомирська область'},
        {'name': 'Закарпатська область'},
        {'name': 'Запорізька область'},
        {'name': 'Івано-Франківська область'},
        {'name': 'Київська область'},
        {'name': 'Кіровоградська область'},
        {'name': 'Луганська область'},
        {'name': 'Львівська область'},
        {'name': 'Миколаївська область'},
        {'name': 'Одеська область'},
        {'name': 'Полтавська область'},
        {'name': 'Рівненська область'},
        {'name': 'Сумська область'},
        {'name': 'Тернопільська область'},
        {'name': 'Харківська область'},
        {'name': 'Херсонська область'},
        {'name': 'Хмельницька область'},
        {'name': 'Черкаська область'},
        {'name': 'Чернівецька область'},
        {'name': 'Чернігівська область'},
        {'name': 'м. Київ'},
      ];

      // Insert regions into the database
      await _supabaseClient.from('regions').insert(regions);
    } catch (error) {
      print('Error initializing regions: $error');
    }
  }
} 