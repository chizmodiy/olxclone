import 'package:algoliasearch/algoliasearch.dart';

void main() async {
  print('🚀 Тестування Algolia пошуку в додатку');
  
  // Використовуємо ті самі ключі, що в додатку
  const appId = 'XYA8SCV3KC';
  const searchKey = '6782ed5c8812fb117b825a5890912b31';
  const indexName = 'products';
  
  final searchClient = SearchClient(
    appId: appId,
    apiKey: searchKey,
  );
  
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
      final response = await searchClient.searchIndex(
        request: SearchForHits(
          indexName: indexName,
          query: query,
          filters: 'status:active OR status:null',
          hitsPerPage: 5,
        ),
      );
      
      print('📊 Знайдено: ${response.nbHits} результатів');
      print('⏱️ Час виконання: ${response.processingTimeMS}ms');
      
      if (response.hits.isNotEmpty) {
        print('📋 Результати:');
        for (int i = 0; i < response.hits.length && i < 3; i++) {
          final hit = response.hits[i];
          print('  ${i + 1}. ${hit['title']}');
          print('     Ціна: ${hit['price']} ${hit['currency']}');
          print('     Локація: ${hit['location']}');
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
    final response = await searchClient.searchIndex(
      request: SearchForHits(
        indexName: indexName,
        query: 'авто',
        filters: 'category_id:transport-category AND price:10000 TO 50000',
        hitsPerPage: 5,
      ),
    );
    
    print('📊 Фільтрований пошук: ${response.nbHits} результатів');
    print('⏱️ Час виконання: ${response.processingTimeMS}ms');
    
  } catch (e) {
    print('❌ Помилка фільтрованого пошуку: $e');
  }
  
  // Тестуємо геопошук
  print('\n🌍 Тестуємо геопошук (Київ)');
  
  try {
    final response = await searchClient.searchIndex(
      request: SearchForHits(
        indexName: indexName,
        query: '',
        aroundLatLng: '50.4501,30.5234',
        aroundRadius: 20000, // 20km
        hitsPerPage: 5,
      ),
    );
    
    print('📊 Геопошук: ${response.nbHits} результатів');
    print('⏱️ Час виконання: ${response.processingTimeMS}ms');
    
  } catch (e) {
    print('❌ Помилка геопошуку: $e');
  }
  
  print('\n✅ Тестування завершено');
} 