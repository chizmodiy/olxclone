# 🚀 Інструкція по налаштуванню Algolia

## 📋 Кроки для налаштування

### 1. **Отримання ключів від клієнта**

Потрібно отримати від клієнта:
- **Application ID** (App ID)
- **Search-Only API Key** (для Flutter додатку)
- **Admin API Key** (для імпорту даних та налаштувань)

### 2. **Експорт даних з Supabase**

```bash
# Запустіть скрипт експорту
dart run scripts/export_data_for_algolia.dart
```

Це створить файли:
- `algolia_products_export.json` - оголошення
- `algolia_categories_export.json` - категорії

### 3. **Імпорт даних в Algolia**

#### Варіант A: Через веб-інтерфейс Algolia
1. Увійдіть в Algolia Dashboard
2. Перейдіть до "Search" → "Index"
3. Виберіть "Upload a File"
4. Завантажте `algolia_products_export.json`

#### Варіант B: Через API (рекомендовано)
1. Оновіть ключі в `scripts/import_to_algolia.dart`
2. Запустіть скрипт:
```bash
c
```

### 4. **Налаштування індексу**

#### Основні налаштування:
- **Searchable Attributes**: title, description, category_name, location
- **Facets**: category_id, region, is_free, price
- **Ranking**: typo, geo, words, filters, proximity, attribute, exact, custom

#### Геопошук:
- **Latitude**: latitude
- **Longitude**: longitude

### 5. **Оновлення Flutter додатку**

#### Оновіть `lib/services/product_service.dart`:

```dart
// Замініть на нові ключі
static const String algoliaAppId = 'НОВИЙ_APP_ID';
static const String algoliaSearchKey = 'НОВИЙ_SEARCH_KEY';
```

#### Розкоментуйте Algolia пошук:

```dart
// Розкоментуйте рядки 118-136
if (searchQuery != null && searchQuery.isNotEmpty) {
  try {
    final response = await searchClient.searchIndex(
      request: SearchForHits(
        indexName: algoliaIndexName,
        query: searchQuery,
        filters: 'status:active OR status:null',
      ),
    );
    final hits = response.hits;
    return hits.map((hit) => Product.fromJson(hit)).toList();
  } catch (e) {
    // Fallback до Supabase
  }
}
```

### 6. **Оновлення Supabase змінних середовища**

```bash
# Встановіть змінні середовища для Supabase функції
supabase secrets set ALGOLIA_APP_ID=НОВИЙ_APP_ID
supabase secrets set ALGOLIA_ADMIN_KEY=НОВИЙ_ADMIN_KEY
```

### 7. **Тестування**

#### Тестування пошуку:
```dart
// Додайте тестові запити
await productService.getProducts(searchQuery: 'телефон');
await productService.getProducts(searchQuery: 'авто');
```

#### Перевірка фільтрів:
```dart
await productService.getProducts(
  categoryId: 'category_id',
  minPrice: 100,
  maxPrice: 1000,
  region: 'Київ'
);
```

## 🔧 Налаштування фільтрів

### Фасети для фільтрації:
- `category_id` - категорія
- `subcategory_id` - підкатегорія  
- `region` - регіон
- `is_free` - безкоштовні
- `has_delivery` - з доставкою
- `price` - ціна
- `custom_attributes.car_brand` - марка авто
- `custom_attributes.size` - розмір
- `custom_attributes.condition` - стан

### Числові фільтри:
- `price` - ціна
- `custom_attributes.year` - рік
- `custom_attributes.area` - площа
- `custom_attributes.engine_power_hp` - потужність двигуна

## 📊 Моніторинг

### Перевірте в Algolia Dashboard:
- Кількість записів в індексі
- Статистика пошукових запитів
- Популярні запити
- Помилки

### Логи Supabase функції:
```bash
supabase functions logs sync-to-algolia
```

## 🚨 Важливі моменти

1. **Backup даних** - зробіть резервну копію перед заміною
2. **Тестування** - протестуйте на staging середовищі
3. **Поетапна міграція** - спочатку налаштуйте, потім переключайте
4. **Моніторинг** - слідкуйте за помилками після запуску

## 📞 Підтримка

При проблемах:
1. Перевірте логи Supabase функції
2. Перевірте налаштування індексу в Algolia
3. Тестуйте пошук через Algolia Dashboard
4. Перевірте правильність ключів 