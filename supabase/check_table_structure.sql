-- Check complaints table structure and relationships
-- This will help identify why the join with profiles is failing

-- Check table structure
SELECT 
    'Table structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'complaints' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check foreign key constraints
SELECT 
    'Foreign keys' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'complaints';

-- Check if there's a direct relationship between complaints and profiles
SELECT 
    'Direct relationships' as info,
    'complaints -> profiles' as relationship,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
            WHERE tc.table_name = 'complaints' 
            AND kcu.column_name = 'user_id'
            AND tc.constraint_type = 'FOREIGN KEY'
            AND tc.constraint_schema = 'public'
        ) THEN 'YES - user_id FK exists'
        ELSE 'NO - user_id FK missing'
    END as status;

-- Check if we can manually join complaints with profiles
SELECT 
    'Manual join test' as info,
    COUNT(*) as complaints_count
FROM public.complaints c
JOIN public.profiles p ON c.user_id = p.id;

-- Check sample data
SELECT 
    'Sample complaints' as info,
    id,
    listing_id,
    user_id,
    title,
    created_at
FROM public.complaints 
LIMIT 5;

-- Check if user_id in complaints matches profiles
SELECT 
    'User ID matching' as info,
    COUNT(DISTINCT c.user_id) as unique_user_ids_in_complaints,
    COUNT(DISTINCT p.id) as unique_user_ids_in_profiles,
    COUNT(DISTINCT c.user_id) FILTER (WHERE p.id IS NOT NULL) as matching_user_ids
FROM public.complaints c
LEFT JOIN public.profiles p ON c.user_id = p.id; 