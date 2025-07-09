-- Create complaints table
create table if not exists public.complaints (
    id uuid primary key default uuid_generate_v4(),
    product_id uuid not null references public.products(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    description text not null,
    types text[] not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.complaints enable row level security;

-- Create policies
create policy "Users can create complaints"
    on public.complaints
    for insert
    with check (auth.uid() = user_id);

create policy "Users can view their own complaints"
    on public.complaints
    for select
    using (auth.uid() = user_id);

create policy "Admins can view all complaints"
    on public.complaints
    for select
    using (
        exists (
            select 1
            from auth.users
            where auth.users.id = auth.uid()
            and auth.users.role = 'admin'
        )
    );

-- Create indexes
create index if not exists complaints_listing_id_idx on public.complaints (listing_id);
create index if not exists complaints_user_id_idx on public.complaints (user_id);

-- Set up updated_at trigger
create trigger handle_updated_at before update on public.complaints
    for each row execute procedure moddatetime (updated_at); 