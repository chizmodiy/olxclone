-- Fix complaints table structure and RLS policies
-- Drop existing table and recreate with correct structure

-- Drop existing table if exists
DROP TABLE IF EXISTS public.complaints CASCADE;

-- Create complaints table with correct structure
CREATE TABLE public.complaints (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    listing_id uuid NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    types text[] NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT complaints_pkey PRIMARY KEY (id),
    CONSTRAINT complaints_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
    CONSTRAINT complaints_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- Create correct policies
CREATE POLICY "Users can create complaints"
    ON public.complaints
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own complaints"
    ON public.complaints
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all complaints"
    ON public.complaints
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Create correct indexes
CREATE INDEX complaints_listing_id_idx ON public.complaints (listing_id);
CREATE INDEX complaints_user_id_idx ON public.complaints (user_id);
CREATE INDEX complaints_created_at_idx ON public.complaints (created_at);

-- Grant necessary permissions
GRANT ALL ON public.complaints TO authenticated;
GRANT ALL ON public.complaints TO service_role; 