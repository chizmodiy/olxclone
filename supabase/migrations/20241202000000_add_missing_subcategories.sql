-- Міграція для додавання відсутніх підкатегорій
-- Це виправить проблему з foreign key constraint

-- Функція для створення підкатегорії, якщо її немає
CREATE OR REPLACE FUNCTION ensure_subcategory_exists(
    category_id_param UUID,
    subcategory_name_param TEXT
) RETURNS UUID AS $$
DECLARE
    subcategory_id UUID;
BEGIN
    -- Перевіряємо, чи існує підкатегорія для цієї категорії
    SELECT id INTO subcategory_id 
    FROM subcategories 
    WHERE category_id = category_id_param 
    LIMIT 1;
    
    -- Якщо підкатегорії немає, створюємо її
    IF subcategory_id IS NULL THEN
        INSERT INTO subcategories (id, name, category_id)
        VALUES (gen_random_uuid(), subcategory_name_param, category_id_param)
        RETURNING id INTO subcategory_id;
    END IF;
    
    RETURN subcategory_id;
END;
$$ LANGUAGE plpgsql;

-- Додаємо підкатегорії для категорій, які їх не мають
-- Це потрібно виконати для кожної категорії окремо

-- Приклад для категорії "Інше":
-- SELECT ensure_subcategory_exists(
--     (SELECT id FROM categories WHERE name = 'Інше' LIMIT 1),
--     'Інше'
-- );

-- Приклад для категорії "Послуги":
-- SELECT ensure_subcategory_exists(
--     (SELECT id FROM categories WHERE name = 'Послуги' LIMIT 1),
--     'Інші послуги'
-- );

-- Видаляємо функцію після використання
-- DROP FUNCTION IF EXISTS ensure_subcategory_exists(UUID, TEXT); 