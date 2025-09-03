-- Script to check data availability in the database
-- Run this to verify that all necessary data exists

-- Check if complaints table exists and has data
SELECT 
    'complaints' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'NO DATA'
    END as status
FROM public.complaints

UNION ALL

-- Check if listings table has data
SELECT 
    'listings' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'NO DATA'
    END as status
FROM public.listings

UNION ALL

-- Check if profiles table has data
SELECT 
    'profiles' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'NO DATA'
    END as status
FROM public.profiles

UNION ALL

-- Check if there are admin users
SELECT 
    'admin_users' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'NO ADMIN USERS'
    END as status
FROM public.profiles 
WHERE role = 'admin'

UNION ALL

-- Check if auth.users has data
SELECT 
    'auth.users' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'NO DATA'
    END as status
FROM auth.users;

-- Check RLS policies on complaints table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'complaints';

-- Check table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'complaints' 
AND table_schema = 'public'
ORDER BY ordinal_position; 