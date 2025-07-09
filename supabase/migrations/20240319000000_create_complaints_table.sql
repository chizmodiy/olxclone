create table public.complaints (
    id uuid not null default uuid_generate_v4(),
    product_id uuid not null references public.products(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    description text not null,
    types text[] not null,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    constraint complaints_pkey primary key (id)
);

-- Set up Row Level Security (RLS)
alter table public.complaints enable row level security;

-- Create policies
create policy "Users can view their own complaints"
    on public.complaints for select
    using (auth.uid() = user_id);

create policy "Users can create complaints"
    on public.complaints for insert
    with check (auth.uid() = user_id);

-- Grant access to authenticated users
grant all on public.complaints to authenticated; 