-- Muuvelo: remote persistence schema (Supabase / PostgreSQL).
-- Every table carries owner_id so Row Level Security can restrict each row
-- to the authenticated user who created it.

create table public.muuvelo_vacas (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  restaurant_name  text not null check (char_length(restaurant_name) between 2 and 40),
  tip_enabled      boolean not null default true,
  tip_percent      smallint not null default 10 check (tip_percent between 0 and 30),
  status           text not null default 'abierta' check (status in ('abierta', 'cerrada')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  closed_at        timestamptz
);

create table public.muuvelo_participantes (
  id          uuid primary key default gen_random_uuid(),
  vaca_id     uuid not null references public.muuvelo_vacas (id) on delete cascade,
  owner_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 20),
  is_host     boolean not null default false,
  amount      integer not null default 0 check (amount >= 0),   -- pesos (COP), never float
  paid        boolean not null default false,
  paid_at     timestamptz,
  position    smallint not null default 0
);

create table public.muuvelo_items (
  id           uuid primary key default gen_random_uuid(),
  vaca_id      uuid not null references public.muuvelo_vacas (id) on delete cascade,
  owner_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  description  text not null check (char_length(description) between 1 and 40),
  price        integer not null check (price > 0 and price <= 10000000),
  position     smallint not null default 0
);

-- Which participants shared each item (many-to-many).
create table public.muuvelo_item_shares (
  item_id         uuid not null references public.muuvelo_items (id) on delete cascade,
  participant_id  uuid not null references public.muuvelo_participantes (id) on delete cascade,
  owner_id        uuid not null default auth.uid() references auth.users (id) on delete cascade,
  primary key (item_id, participant_id)
);

create index on public.muuvelo_vacas (owner_id, created_at desc);
create index on public.muuvelo_participantes (vaca_id);
create index on public.muuvelo_participantes (owner_id);
create index on public.muuvelo_items (vaca_id);
create index on public.muuvelo_items (owner_id);
create index on public.muuvelo_item_shares (participant_id);
create index on public.muuvelo_item_shares (owner_id);

-- Keep updated_at fresh on every update.
create or replace function public.muuvelo_touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger muuvelo_vacas_touch before update on public.muuvelo_vacas
  for each row execute function public.muuvelo_touch_updated_at();

-- Row Level Security: a user can only see and change their own rows.
alter table public.muuvelo_vacas          enable row level security;
alter table public.muuvelo_participantes  enable row level security;
alter table public.muuvelo_items          enable row level security;
alter table public.muuvelo_item_shares    enable row level security;

create policy "owner can read"   on public.muuvelo_vacas for select to authenticated using ((select auth.uid()) = owner_id);
create policy "owner can insert" on public.muuvelo_vacas for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "owner can update" on public.muuvelo_vacas for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "owner can delete" on public.muuvelo_vacas for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "owner can read"   on public.muuvelo_participantes for select to authenticated using ((select auth.uid()) = owner_id);
create policy "owner can insert" on public.muuvelo_participantes for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "owner can update" on public.muuvelo_participantes for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "owner can delete" on public.muuvelo_participantes for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "owner can read"   on public.muuvelo_items for select to authenticated using ((select auth.uid()) = owner_id);
create policy "owner can insert" on public.muuvelo_items for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "owner can update" on public.muuvelo_items for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "owner can delete" on public.muuvelo_items for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "owner can read"   on public.muuvelo_item_shares for select to authenticated using ((select auth.uid()) = owner_id);
create policy "owner can insert" on public.muuvelo_item_shares for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "owner can delete" on public.muuvelo_item_shares for delete to authenticated using ((select auth.uid()) = owner_id);

-- Anonymous (not logged in) clients get no table privileges at all.
revoke all on public.muuvelo_vacas, public.muuvelo_participantes, public.muuvelo_items, public.muuvelo_item_shares from anon;
