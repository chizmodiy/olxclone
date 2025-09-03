# Виправлення проблеми з відображенням скарг на сторінці адміна

## Проблема
На сторінці адміна не відображаються скарги з бази даних Supabase, навіть якщо вони є в базі.

## Причини проблеми

### 1. Невідповідність структури таблиці
- У міграції використовується `product_id`, але у схемі та коді - `listing_id`
- Неправильні індекси та зовнішні ключі

### 2. Неправильні RLS політики
- Політика для адмінів перевіряє `auth.users.role`, але роль зберігається в `public.profiles.role`
- Неправильні посилання на поля

### 3. Проблеми в коді
- `ComplaintService` неправильно обробляє join'и
- Відсутнє логування для дебагу

### 4. **ВИЯВЛЕНА ПРОБЛЕМА: Неправильні join'и**
- Код намагався зробити `complaints!inner(profiles)`, але між цими таблицями немає прямого foreign key
- Таблиця `complaints` має `user_id`, який посилається на `auth.users`, а не на `public.profiles`

## Рішення

### Крок 1: Застосувати нову міграцію
```bash
# Застосувати міграцію для виправлення таблиці скарг
supabase db reset
# або
supabase migration up
```

### Крок 2: Додати тестові дані
```bash
# Виконати скрипт для додавання тестових скарг
psql -h your-supabase-host -U postgres -d postgres -f supabase/seed_complaints.sql
```

### Крок 3: Перевірити логування
1. Відкрити Flutter DevTools або консоль
2. Перейти на сторінку адміна
3. Перевірити логи в консолі

## Діагностика проблеми

### Якщо скарги є в базі, але не відображаються:

1. **Перевірити RLS політики**:
   ```bash
   psql -h your-supabase-host -U postgres -d postgres -f supabase/check_rls_policies.sql
   ```

2. **Перевірити структуру таблиці**:
   ```bash
   psql -h your-supabase-host -U postgres -d postgres -f supabase/check_table_structure.sql
   ```

3. **Створити тестову скаргу**:
   ```bash
   psql -h your-supabase-host -U postgres -d postgres -f supabase/create_test_complaint.sql
   ```

4. **Використати кнопки тестування** на сторінці адміна:
   - Натиснути "Тест доступу" - перевірить всі таблиці та права доступу
   - Натиснути "Тест сервісу" - перевірить роботу ComplaintService
   - Натиснути "Оновити скарги" - примусово оновить список скарг

5. **Перевірити логи в консолі** - тепер там буде детальна інформація про:
   - Поточного користувача та його роль
   - Спробу отримання скарг без join'ів
   - Спробу отримання скарг з правильними join'ами
   - Отримання даних користувачів окремо
   - Помилки та їх деталі

### Перевірка RLS політик

Основна проблема може бути в RLS політиці для адмінів. Переконайтеся, що:

1. **RLS увімкнено** на таблиці `complaints`
2. **Політика "Admins can view all complaints"** правильно налаштована
3. **Користувач має роль 'admin'** в таблиці `profiles`
4. **Політика перевіряє правильне поле** (`profiles.role`, а не `auth.users.role`)

### Тестування без RLS

Для тестування можна тимчасово вимкнути RLS:

```sql
-- ТИМЧАСОВО вимкнути RLS для тестування
ALTER TABLE public.complaints DISABLE ROW LEVEL SECURITY;

-- Перевірити, чи тепер видно скарги
SELECT * FROM public.complaints;

-- ПОВЕРНУТИ RLS після тестування
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
```

## Виправлена проблема з join'ами

### Раніше (неправильно):
```dart
// Це не працювало, бо між complaints та profiles немає прямого FK
final response = await _client
    .from('complaints')
    .select('''
      *,
      listings!inner(...),
      profiles!inner(...)  // ❌ Помилка: немає FK зв'язку
    ''');
```

### Тепер (правильно):
```dart
// 1. Отримуємо скарги з join на listings
final response = await _client
    .from('complaints')
    .select('''
      *,
      listings!inner(...)
    ''');

// 2. Отримуємо дані користувачів окремо
final profilesResponse = await _client
    .from('profiles')
    .select('id, full_name, email')
    .in_('id', userIds);

// 3. Об'єднуємо дані в коді
for (final complaint in complaints) {
  final userId = complaint['user_id'] as String;
  complaint['profiles'] = profilesMap[userId] ?? {};
}
```

## Файли, які були змінені

1. **`supabase/migrations/20241202000001_fix_complaints_table.sql`** - Нова міграція
2. **`lib/services/complaint_service.dart`** - Виправлений сервіс з правильними join'ами та детальним логуванням
3. **`lib/pages/admin_dashboard_page.dart`** - Додано логування, тестування та перевірку на порожній список
4. **`supabase/seed_complaints.sql`** - Скрипт для тестових даних
5. **`supabase/check_data.sql`** - Перевірка наявності даних
6. **`supabase/check_rls_policies.sql`** - Перевірка RLS політик
7. **`supabase/check_table_structure.sql`** - Перевірка структури таблиці та зв'язків
8. **`supabase/create_test_complaint.sql`** - Створення тестової скарги

## Перевірка роботи

1. **Застосувати міграцію** до бази даних
2. **Додати тестові скарги** за допомогою seed скрипта
3. **Перезапустити додаток**
4. **Перейти на сторінку адміна** та перевірити вкладку "Скарги"
5. **Використати кнопки тестування** для діагностики
6. **Перевірити логи** в консолі на наявність помилок

## Структура таблиці після виправлення

```sql
CREATE TABLE public.complaints (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    listing_id uuid NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    types text[] NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT complaints_pkey PRIMARY KEY (id),
    CONSTRAINT complaints_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
    CONSTRAINT complaints_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
```

## RLS політики

- **Users can create complaints**: Користувачі можуть створювати скарги
- **Users can view their own complaints**: Користувачі можуть переглядати свої скарги
- **Admins can view all complaints**: Адміністратори можуть переглядати всі скарги

## Додаткові рекомендації

1. **Перевірити права доступу** користувача в таблиці `profiles.role`
2. **Переконатися**, що є хоча б один користувач з `role = 'admin'`
3. **Перевірити**, що таблиця `listings` містить дані
4. **Перевірити**, що таблиця `profiles` містить дані користувачів
5. **Використовувати кнопки тестування** для швидкої діагностики
6. **Перевірити RLS політики** якщо проблема залишається
7. **Перевірити структуру таблиці** та зв'язки між таблицями 