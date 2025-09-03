-- Create a test complaint directly via SQL
-- This bypasses RLS policies to test if the issue is with RLS or data

-- First, let's check what data we have
SELECT 'Available listings:' as info;
SELECT id, title FROM public.listings LIMIT 5;

SELECT 'Available users:' as info;
SELECT id, email, role FROM public.profiles LIMIT 5;

-- Create a test complaint using the first available listing and user
-- Replace the UUIDs with actual values from your database
INSERT INTO public.complaints (
    listing_id,
    user_id,
    title,
    description,
    types
) VALUES (
    (SELECT id FROM public.listings LIMIT 1),
    (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1),
    'Тестова скарга',
    'Це тестова скарга для перевірки роботи системи',
    ARRAY['Тест', 'Перевірка']
) ON CONFLICT DO NOTHING;

-- Verify the complaint was created
SELECT 'Created complaint:' as info;
SELECT * FROM public.complaints WHERE title = 'Тестова скарга';

-- Check if we can see it with RLS
SELECT 'Complaints visible with RLS:' as info;
SELECT COUNT(*) as count FROM public.complaints; 