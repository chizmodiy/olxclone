-- Check listings table structure and find image field
-- This will help identify what field contains the image URL

-- Check table structure
SELECT 
    'Listings table fields:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'listings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check sample data from listings
SELECT 
    'Sample listings data:' as info,
    id,
    title,
    description
FROM public.listings 
LIMIT 5;

-- Search for columns that might contain image URLs
SELECT 
    'Possible image columns:' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'listings' 
AND table_schema = 'public'
AND (
    column_name ILIKE '%image%' OR
    column_name ILIKE '%photo%' OR
    column_name ILIKE '%img%' OR
    column_name ILIKE '%url%' OR
    column_name ILIKE '%file%'
)
ORDER BY column_name;

-- Check if there are any JSON or array columns that might contain images
SELECT 
    'JSON/Array columns:' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'listings' 
AND table_schema = 'public'
AND (
    data_type LIKE '%json%' OR
    data_type LIKE '%[]%' OR
    data_type LIKE '%array%'
)
ORDER BY column_name; 