-- Idempotency ledger: a network retry can never add the same guest batch twice.
create table if not exists public.guest_stats_migration_batches (
  user_id uuid not null references auth.users(id) on delete cascade,
  batch_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, batch_id),
  constraint guest_stats_migration_batch_id_length
    check (char_length(batch_id) between 8 and 128)
);

alter table public.guest_stats_migration_batches enable row level security;
revoke all on table public.guest_stats_migration_batches from anon, authenticated;

create or replace function public.migrate_guest_stats_v1(
  p_batch_id text,
  p_total_sessions integer,
  p_total_minutes integer,
  p_current_streak integer,
  p_daily_stats jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_inserted integer := 0;
  v_item jsonb;
  v_date_key text;
  v_minutes integer;
  v_sessions integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_batch_id is null or char_length(p_batch_id) not between 8 and 128 then
    raise exception 'Invalid migration batch id' using errcode = '22023';
  end if;

  if coalesce(p_total_sessions, -1) < 0
     or coalesce(p_total_minutes, -1) < 0
     or coalesce(p_current_streak, -1) < 0 then
    raise exception 'Stats cannot be negative' using errcode = '22023';
  end if;

  if p_daily_stats is null or jsonb_typeof(p_daily_stats) <> 'array' then
    raise exception 'Daily stats must be a JSON array' using errcode = '22023';
  end if;

  insert into public.guest_stats_migration_batches (user_id, batch_id)
  values (v_user_id, p_batch_id)
  on conflict (user_id, batch_id) do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return jsonb_build_object('applied', false, 'already_applied', true);
  end if;

  insert into public.user_stats (
    user_id,
    total_sessions,
    total_minutes,
    current_streak,
    updated_at
  )
  values (
    v_user_id,
    p_total_sessions,
    p_total_minutes,
    p_current_streak,
    now()
  )
  on conflict (user_id) do update
  set total_sessions = coalesce(public.user_stats.total_sessions, 0)
                         + excluded.total_sessions,
      total_minutes = coalesce(public.user_stats.total_minutes, 0)
                        + excluded.total_minutes,
      current_streak = greatest(
        coalesce(public.user_stats.current_streak, 0),
        excluded.current_streak
      ),
      updated_at = now();

  for v_item in select value from jsonb_array_elements(p_daily_stats)
  loop
    v_date_key := v_item ->> 'date_key';
    v_minutes := coalesce((v_item ->> 'minutes')::integer, 0);
    v_sessions := coalesce((v_item ->> 'sessions')::integer, 0);

    if v_date_key is null
       or v_date_key !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
       or to_char(to_date(v_date_key, 'YYYY-MM-DD'), 'YYYY-MM-DD') <> v_date_key
       or v_minutes < 0
       or v_sessions < 0 then
      raise exception 'Invalid daily stats row' using errcode = '22023';
    end if;

    insert into public.daily_stats (
      user_id,
      date_key,
      minutes,
      sessions
    )
    values (
      v_user_id,
      v_date_key,
      v_minutes,
      v_sessions
    )
    on conflict (user_id, date_key) do update
    set minutes = coalesce(public.daily_stats.minutes, 0) + excluded.minutes,
        sessions = coalesce(public.daily_stats.sessions, 0) + excluded.sessions;
  end loop;

  return jsonb_build_object('applied', true, 'already_applied', false);
end;
$$;

revoke all on function public.migrate_guest_stats_v1(
  text,
  integer,
  integer,
  integer,
  jsonb
) from public, anon;

grant execute on function public.migrate_guest_stats_v1(
  text,
  integer,
  integer,
  integer,
  jsonb
) to authenticated;
