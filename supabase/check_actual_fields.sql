-- Check actual fields in profiles and listings tables
-- This will help identify what fields are actually available

-- Check profiles table structure
SELECT 
    'Profiles table fields:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check listings table structure
SELECT 
    'Listings table fields:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'listings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check sample data from profiles
SELECT 
    'Sample profiles data:' as info,
    *
FROM public.profiles 
LIMIT 3;

-- Check sample data from listings
SELECT 
    'Sample listings data:' as info,
    *
FROM public.listings 
LIMIT 3; 