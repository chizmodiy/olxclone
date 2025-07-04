-- Create cities table
create table if not exists public.cities (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    region_id uuid not null references public.regions(id) on delete cascade,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.cities enable row level security;

-- Create policies
create policy "Enable read access for all users" on public.cities
    for select using (true);

-- Create indexes
create index if not exists cities_name_idx on public.cities (name);
create index if not exists cities_region_id_idx on public.cities (region_id);

-- Set up updated_at trigger
create trigger handle_updated_at before update on public.cities
    for each row execute procedure moddatetime (updated_at); 