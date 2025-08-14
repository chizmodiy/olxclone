import 'lib/services/algolia_service.dart';

void main() async {
  print('🚀 Тестування HTTP Algolia сервісу');
  
  final algoliaService = AlgoliaService();
  
  // Тестуємо базовий пошук
  print('\n🔍 Тестуємо базовий пошук: "авто"');
  try {
    final results = await algoliaService.searchProducts(
      query: 'авто',
      limit: 5,
    );
    
    print('📊 Знайдено: ${results.length} результатів');
    
    if (results.isNotEmpty) {
      print('📋 Результати:');
      for (int i = 0; i < results.length && i < 3; i++) {
        final product = results[i];
        print('  ${i + 1}. ${product.title}');
        print('     Ціна: ${product.price} ${product.currency}');
        print('     Локація: ${product.location}');
      }
    }
  } catch (e) {
    print('❌ Помилка: $e');
  }
  
  // Тестуємо пошук по категорії
  print('\n🔍 Тестуємо пошук по категорії: "Електроніка"');
  try {
    final results = await algoliaService.searchProducts(
      query: 'телефон',
      categoryId: 'electronics-category',
      limit: 5,
    );
    
    print('📊 Знайдено: ${results.length} результатів');
  } catch (e) {
    print('❌ Помилка: $e');
  }
  
  // Тестуємо геопошук
  print('\n🌍 Тестуємо геопошук (Київ)');
  try {
    final results = await algoliaService.searchByLocation(
      latitude: 50.4501,
      longitude: 30.5234,
      radiusInKm: 20,
      limit: 5,
    );
    
    print('📊 Знайдено: ${results.length} результатів поблизу Києва');
  } catch (e) {
    print('❌ Помилка: $e');
  }
  
  // Тестуємо фасети
  print('\n🏷️ Тестуємо фасети');
  try {
    final facets = await algoliaService.getFacets();
    
    print('📊 Доступні фасети:');
    for (final entry in facets.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
  } catch (e) {
    print('❌ Помилка: $e');
  }
  
  print('\n✅ Тестування завершено');
} 