-- Check RLS policies on complaints table
-- Run this to verify that RLS policies are correctly set up

-- Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'complaints';

-- Check all policies on complaints table
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
WHERE tablename = 'complaints'
ORDER BY policyname;

-- Check if the admin policy is working correctly
-- This should return the policy definition
SELECT 
    policyname,
    pg_get_expr(qual, polrelid) as using_expression,
    pg_get_expr(with_check, polrelid) as with_check_expression
FROM pg_policy 
WHERE polrelid = 'public.complaints'::regclass
AND policyname = 'Admins can view all complaints';

-- Check if the user can access complaints based on their role
-- Replace 'YOUR_USER_ID' with actual user ID
SELECT 
    'Current user can access complaints' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE profiles.id = 'YOUR_USER_ID'::uuid
            AND profiles.role = 'admin'
        ) THEN 'YES - User is admin'
        ELSE 'NO - User is not admin'
    END as result;

-- Check if there are any admin users in profiles
SELECT 
    'Admin users count' as info,
    COUNT(*) as count
FROM public.profiles 
WHERE role = 'admin';

-- Check if there are any complaints in the table
SELECT 
    'Complaints count' as info,
    COUNT(*) as count
FROM public.complaints;

-- Check if the user has the right permissions
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'complaints'
AND table_schema = 'public'; 