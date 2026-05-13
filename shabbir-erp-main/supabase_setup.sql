-- Shabbir ERP — Supabase table setup
-- Run this once in your Supabase project:
-- Dashboard → SQL Editor → New query → paste → Run

create table if not exists parties (
  id text primary key,
  name text not null,
  type text not null,
  opening_bal double precision not null default 0,
  created_at bigint not null,
  user_id text not null default 'default'
);

create table if not exists stock_items (
  id text primary key,
  name text not null,
  unit text not null default 'Pcs',
  current_qty double precision not null default 0,
  created_at bigint not null,
  user_id text not null default 'default'
);

create table if not exists transactions (
  id text primary key,
  party_id text not null references parties(id) on delete cascade,
  item_id text references stock_items(id) on delete set null,
  qty double precision not null default 0,
  rate double precision not null default 0,
  total double precision not null default 0,
  type text not null,
  date text not null,
  remarks text not null default '',
  created_at bigint not null,
  user_id text not null default 'default'
);

create index if not exists idx_parties_user_id on parties(user_id);
create index if not exists idx_stock_items_user_id on stock_items(user_id);
create index if not exists idx_transactions_user_id on transactions(user_id);
create index if not exists idx_transactions_party_id on transactions(party_id);

-- Enable Row Level Security (optional but recommended)
alter table parties enable row level security;
alter table stock_items enable row level security;
alter table transactions enable row level security;

-- Allow all operations for anon key (single-user app)
create policy "allow_all_parties" on parties for all using (true) with check (true);
create policy "allow_all_stock_items" on stock_items for all using (true) with check (true);
create policy "allow_all_transactions" on transactions for all using (true) with check (true);
