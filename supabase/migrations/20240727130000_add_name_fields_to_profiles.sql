-- Add first_name and last_name columns to profiles table
ALTER TABLE profiles
ADD COLUMN first_name text,
ADD COLUMN last_name text;

-- Allow users to update their own name fields
CREATE POLICY "Users can update their own name fields" ON profiles
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id); 