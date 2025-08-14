# 🔧 Оновлення змінних середовища Supabase

## Виконайте наступні команди:

```bash
# Оновлення Application ID
supabase secrets set ALGOLIA_APP_ID=XYA8SCV3KC

# Оновлення Admin Key
supabase secrets set ALGOLIA_ADMIN_KEY=822ba9bc100be86442292e334d088b20
```

## Перевірка налаштувань:

```bash
# Перевірка поточних змінних
supabase secrets list
```

## Перезапуск функції:

```bash
# Розгортання функції з новими змінними
supabase functions deploy sync-to-algolia
```

## Перевірка логів:

```bash
# Перегляд логів функції
supabase functions logs sync-to-algolia
``` 