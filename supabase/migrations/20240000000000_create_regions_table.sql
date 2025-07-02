-- Create regions table
create table if not exists public.regions (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.regions enable row level security;

-- Create policies
create policy "Enable read access for all users" on public.regions
    for select using (true);

-- Create indexes
create index if not exists regions_name_idx on public.regions (name);

-- Set up updated_at trigger
create trigger handle_updated_at before update on public.regions
    for each row execute procedure moddatetime (updated_at); 