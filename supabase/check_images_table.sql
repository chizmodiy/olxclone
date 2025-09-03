-- Check if there's a separate images table
-- This will help find where images are stored

-- List all tables that might contain images
SELECT 
    'Tables with image-related names:' as info,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public'
AND (
    table_name ILIKE '%image%' OR
    table_name ILIKE '%photo%' OR
    table_name ILIKE '%img%' OR
    table_name ILIKE '%file%' OR
    table_name ILIKE '%media%'
)
ORDER BY table_name;

-- Check if there's a listing_images table
SELECT 
    'Listing images table exists:' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'listing_images'
        ) THEN 'YES'
        ELSE 'NO'
    END as exists;

-- If listing_images exists, check its structure
SELECT 
    'Listing images structure:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'listing_images' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if there are any foreign key relationships between listings and images
SELECT 
    'Foreign keys to images:' as info,
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
AND tc.table_name = 'listings'
AND (
    ccu.table_name ILIKE '%image%' OR
    ccu.table_name ILIKE '%photo%' OR
    ccu.table_name ILIKE '%file%'
); 