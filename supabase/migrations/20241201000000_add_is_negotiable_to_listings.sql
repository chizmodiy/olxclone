-- Add is_negotiable column to listings table
alter table public.listings 
add column if not exists is_negotiable boolean default false;

-- Add comment to the column
comment on column public.listings.is_negotiable is 'Indicates if the price is negotiable';

-- Create index for better performance on queries filtering by is_negotiable
create index if not exists listings_is_negotiable_idx on public.listings (is_negotiable); 