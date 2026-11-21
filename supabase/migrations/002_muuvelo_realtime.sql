
-- Realtime: push row changes to the app (RLS still applies to subscribers).
alter publication supabase_realtime add table public.muuvelo_vacas, public.muuvelo_participantes;
