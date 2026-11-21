-- Table privileges for logged-in users. Without these, PostgREST answers 403
-- before RLS is even evaluated. RLS policies still restrict every row to its
-- owner; anon keeps no privileges at all.
revoke all on public.muuvelo_vacas, public.muuvelo_participantes, public.muuvelo_items, public.muuvelo_item_shares from authenticated;
grant select, insert, update, delete on public.muuvelo_vacas, public.muuvelo_participantes, public.muuvelo_items to authenticated;
grant select, insert, delete on public.muuvelo_item_shares to authenticated;
