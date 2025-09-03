-- Seed complaints table with test data
-- Make sure you have some listings and users in the database first

-- Insert test complaints (adjust the UUIDs based on your actual data)
INSERT INTO public.complaints (
    listing_id,
    user_id,
    title,
    description,
    types
) VALUES 
(
    -- Replace with actual listing_id from your listings table
    (SELECT id FROM public.listings LIMIT 1),
    -- Replace with actual user_id from your auth.users table
    (SELECT id FROM auth.users LIMIT 1),
    'Товар не відповідає опису',
    'Отримав товар, який сильно відрізняється від опису. Фото показує новий товар, а прийшов пошкоджений.',
    ARRAY['Товар не відповідає опису', 'Проблема з якістю']
),
(
    -- Replace with actual listing_id from your listings table
    (SELECT id FROM public.listings LIMIT 1 OFFSET 1),
    -- Replace with actual user_id from your auth.users table
    (SELECT id FROM auth.users LIMIT 1 OFFSET 1),
    'Продавець не відповідає',
    'Написав продавцю кілька разів, але він не відповідає на повідомлення вже тиждень.',
    ARRAY['Продавець не відповідав', 'Проблема з комунікацією']
),
(
    -- Replace with actual listing_id from your listings table
    (SELECT id FROM public.listings LIMIT 1 OFFSET 2),
    -- Replace with actual user_id from your auth.users table
    (SELECT id FROM auth.users LIMIT 1),
    'Проблема з оплатою',
    'Спробував оплатити товар, але система видає помилку. Гроші знялися з картки, але замовлення не підтвердилося.',
    ARRAY['Проблема з оплатою', 'Технічна проблема']
)
ON CONFLICT DO NOTHING; 