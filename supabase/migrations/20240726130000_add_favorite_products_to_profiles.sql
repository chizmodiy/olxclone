-- Add favorite_products column to profiles table
ALTER TABLE profiles
ADD COLUMN favorite_products jsonb DEFAULT '[]'::jsonb;

-- Allow users to update their own favorite_products
CREATE POLICY "Users can update their own favorite products" ON profiles
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id); 