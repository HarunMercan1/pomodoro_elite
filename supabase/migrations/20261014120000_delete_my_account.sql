-- Lets a signed-in user permanently delete their own account from inside the
-- app (Google Play account deletion requirement).
--
-- The user_stats / daily_stats table definitions are not tracked in this repo,
-- so their foreign keys may or may not cascade from auth.users. The stats rows
-- are therefore deleted explicitly first; guest_stats_migration_batches and
-- auth-owned rows (identities, sessions, refresh tokens) cascade from
-- auth.users. Everything runs in a single transaction: if any step fails,
-- nothing is deleted.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  delete from public.daily_stats where user_id = v_user_id;
  delete from public.user_stats where user_id = v_user_id;
  delete from auth.users where id = v_user_id;
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
