import 'lib/services/product_service.dart';

void main() async {
  // Ініціалізація Supabase (потрібно налаштувати)
  print('🚀 Тестування пошуку в додатку');
  
  final productService = ProductService();
  
  // Тестуємо різні пошукові запити
  final testQueries = [
    'телефон',
    'авто',
    'квартира',
    'iPhone',
    'Toyota',
    'Київ',
    'Львів',
  ];
  
  for (final query in testQueries) {
    print('\n🔍 Тестуємо пошук: "$query"');
    
    try {
      final results = await productService.getProducts(
        searchQuery: query,
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
      } else {
        print('❌ Результатів не знайдено');
      }
      
    } catch (e) {
      print('❌ Помилка пошуку: $e');
    }
  }
  
  // Тестуємо фільтрований пошук
  print('\n🔍 Тестуємо фільтрований пошук');
  
  try {
    final filteredResults = await productService.getProducts(
      searchQuery: 'авто',
      categoryId: 'transport-category',
      minPrice: 10000,
      maxPrice: 50000,
      limit: 5,
    );
    
    print('📊 Фільтрований пошук: ${filteredResults.length} результатів');
    
  } catch (e) {
    print('❌ Помилка фільтрованого пошуку: $e');
  }
  
  print('\n✅ Тестування завершено');
} 