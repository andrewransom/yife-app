create table public.session_attending_users (
  session_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (session_entity_id, user_id)
);

create table public.session_attending_characters (
  session_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  character_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (session_entity_id, character_entity_id)
);

create index session_attending_users_campaign_idx
  on public.session_attending_users (campaign_id, session_entity_id, updated_at desc);
create index session_attending_characters_campaign_idx
  on public.session_attending_characters (campaign_id, session_entity_id, updated_at desc);

create trigger session_attending_users_set_updated_at
  before update on public.session_attending_users
  for each row execute function public.set_updated_at();

create trigger session_attending_characters_set_updated_at
  before update on public.session_attending_characters
  for each row execute function public.set_updated_at();

create or replace function public.validate_session_attending_user()
returns trigger
language plpgsql
as $$
declare
  v_session_campaign_id uuid;
begin
  select ce.campaign_id
  into v_session_campaign_id
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  where ce.id = new.session_entity_id
    and ce.deleted_at is null
    and et.key = 'session';

  if v_session_campaign_id is null then
    raise exception 'Session attendance must reference an existing session entity';
  end if;

  if new.campaign_id <> v_session_campaign_id then
    raise exception 'Session attendance campaign must match the session campaign';
  end if;

  if not exists (
    select 1
    from public.campaign_memberships cm
    where cm.campaign_id = new.campaign_id
      and cm.user_id = new.user_id
      and cm.status = 'active'
  ) then
    raise exception 'Attending user must belong to an active campaign membership';
  end if;

  return new;
end;
$$;

create or replace function public.validate_session_attending_character()
returns trigger
language plpgsql
as $$
declare
  v_session_campaign_id uuid;
begin
  select ce.campaign_id
  into v_session_campaign_id
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  where ce.id = new.session_entity_id
    and ce.deleted_at is null
    and et.key = 'session';

  if v_session_campaign_id is null then
    raise exception 'Session attendance must reference an existing session entity';
  end if;

  if new.campaign_id <> v_session_campaign_id then
    raise exception 'Session attendance campaign must match the session campaign';
  end if;

  perform public.require_campaign_entity_ref(
    new.campaign_id,
    'character',
    new.character_entity_id,
    true
  );

  return new;
end;
$$;

create trigger session_attending_users_validate
  before insert or update of session_entity_id, campaign_id, user_id
  on public.session_attending_users
  for each row execute function public.validate_session_attending_user();

create trigger session_attending_characters_validate
  before insert or update of session_entity_id, campaign_id, character_entity_id
  on public.session_attending_characters
  for each row execute function public.validate_session_attending_character();

create or replace function public.assert_manage_session_attendance(
  p_session_entity_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_campaign_id uuid;
begin
  select ce.campaign_id
  into v_campaign_id
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  where ce.id = p_session_entity_id
    and ce.deleted_at is null
    and et.key = 'session';

  if v_campaign_id is null then
    raise exception 'Session not found';
  end if;

  if not public.can_view_gm_content(v_campaign_id) then
    raise exception 'Only owners and game masters can manage session attendance';
  end if;

  return v_campaign_id;
end;
$$;

drop function if exists public.get_session_attendance(uuid);
drop function if exists public.get_session_attendance(uuid, text);

create function public.get_session_attendance(
  p_session_entity_id uuid,
  p_role_view text default null
)
returns table (
  session_entity_id uuid,
  attending_users jsonb,
  attending_characters jsonb,
  can_manage boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with session_row as (
    select ce.id, ce.campaign_id
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = p_session_entity_id
      and ce.deleted_at is null
      and et.key = 'session'
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
  ),
  users_json as (
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'user_id', sau.user_id,
        'display_label', coalesce(cm.display_name_override, up.display_name),
        'role_keys', (
          select coalesce(array_agg(rd.key order by rd.key), array[]::text[])
          from public.campaign_memberships cm2
          join public.campaign_membership_roles cmr on cmr.membership_id = cm2.id
          join public.role_definitions rd on rd.id = cmr.role_id
          where cm2.campaign_id = sr.campaign_id
            and cm2.user_id = sau.user_id
            and cm2.status = 'active'
        )
      )
      order by coalesce(cm.display_name_override, up.display_name), sau.created_at
    ), '[]'::jsonb) as value
    from session_row sr
    left join public.session_attending_users sau
      on sau.session_entity_id = sr.id
    left join public.user_profiles up
      on up.user_id = sau.user_id
    left join public.campaign_memberships cm
      on cm.campaign_id = sr.campaign_id
     and cm.user_id = sau.user_id
     and cm.status = 'active'
  ),
  characters_json as (
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'character_entity_id', sac.character_entity_id,
        'display_label', public.entity_ref_label_for_role(sac.character_entity_id, p_role_view),
        'visibility', ce.default_visibility
      )
      order by public.entity_ref_label_for_role(sac.character_entity_id, p_role_view), sac.created_at
    ), '[]'::jsonb) as value
    from session_row sr
    left join public.session_attending_characters sac
      on sac.session_entity_id = sr.id
    left join public.campaign_entities ce
      on ce.id = sac.character_entity_id
    where sac.character_entity_id is null
      or public.can_view_campaign_entity_for_role(sac.character_entity_id, p_role_view)
  )
  select
    sr.id,
    users_json.value,
    characters_json.value,
    case when public.is_player_preview_role(p_role_view) then false else public.can_view_gm_content(sr.campaign_id) end
  from session_row sr
  cross join users_json
  cross join characters_json;
$$;

create or replace function public.update_session_attendance(
  p_session_entity_id uuid,
  p_user_ids uuid[] default null,
  p_character_entity_ids uuid[] default null
)
returns table (
  session_entity_id uuid,
  campaign_id uuid,
  user_count integer,
  character_count integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_campaign_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  v_campaign_id := public.assert_manage_session_attendance(p_session_entity_id);

  if exists (
    select 1
    from unnest(coalesce(p_user_ids, array[]::uuid[])) as requested_user_id
    left join public.campaign_memberships cm
      on cm.campaign_id = v_campaign_id
     and cm.user_id = requested_user_id
     and cm.status = 'active'
    where cm.id is null
  ) then
    raise exception 'Attending users must be active campaign members';
  end if;

  perform public.require_campaign_entity_ref(v_campaign_id, 'character', requested_character_id, true)
  from (
    select distinct requested_character_id
    from unnest(coalesce(p_character_entity_ids, array[]::uuid[])) requested_character_id
    where requested_character_id is not null
  ) requested_characters;

  delete from public.session_attending_users sau
  where sau.session_entity_id = p_session_entity_id
    and sau.user_id not in (
      select requested_user_id
      from unnest(coalesce(p_user_ids, array[]::uuid[])) requested_user_id
    );

  insert into public.session_attending_users (
    session_entity_id,
    campaign_id,
    user_id,
    created_by,
    updated_by
  )
  select
    p_session_entity_id,
    v_campaign_id,
    requested_user_id,
    v_user_id,
    v_user_id
  from (
    select distinct requested_user_id
    from unnest(coalesce(p_user_ids, array[]::uuid[])) requested_user_id
    where requested_user_id is not null
  ) requested_users
  on conflict on constraint session_attending_users_pkey do update
  set updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.session_attending_characters sac
  where sac.session_entity_id = p_session_entity_id
    and sac.character_entity_id not in (
      select requested_character_id
      from unnest(coalesce(p_character_entity_ids, array[]::uuid[])) requested_character_id
    );

  insert into public.session_attending_characters (
    session_entity_id,
    campaign_id,
    character_entity_id,
    created_by,
    updated_by
  )
  select
    p_session_entity_id,
    v_campaign_id,
    requested_character_id,
    v_user_id,
    v_user_id
  from (
    select distinct requested_character_id
    from unnest(coalesce(p_character_entity_ids, array[]::uuid[])) requested_character_id
    where requested_character_id is not null
  ) requested_characters
  on conflict on constraint session_attending_characters_pkey do update
  set updated_by = excluded.updated_by,
      updated_at = now();

  return query
  select
    p_session_entity_id,
    v_campaign_id,
    (
      select count(*)::integer
      from public.session_attending_users sau
      where sau.session_entity_id = p_session_entity_id
    ),
    (
      select count(*)::integer
      from public.session_attending_characters sac
      where sac.session_entity_id = p_session_entity_id
    );
end;
$$;

drop function if exists public.get_current_session(uuid);
drop function if exists public.get_current_session(uuid, text);

create function public.get_current_session(
  p_campaign_id uuid,
  p_role_view text default null
)
returns table (
  session_entity_id uuid,
  list_caption text,
  session_date date,
  status_key text,
  status_label text,
  selection_reason text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with visible_sessions as (
    select
      ce.id as session_entity_id,
      ce.list_caption,
      s.session_date,
      sd.key as status_key,
      sd.label as status_label,
      timezone(c.timezone, now())::date as local_today
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    join public.sessions s on s.entity_id = ce.id
    join public.campaigns c on c.id = ce.campaign_id
    left join public.status_definitions sd on sd.id = s.status_id
    where ce.campaign_id = p_campaign_id
      and ce.deleted_at is null
      and et.key = 'session'
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
      and sd.key in ('planned', 'completed')
  ),
  next_planned as (
    select *
    from visible_sessions
    where status_key = 'planned'
      and session_date >= local_today
    order by session_date asc, list_caption asc
    limit 1
  ),
  recent_completed as (
    select *
    from visible_sessions
    where status_key = 'completed'
    order by session_date desc, list_caption asc
    limit 1
  )
  select
    np.session_entity_id,
    np.list_caption,
    np.session_date,
    np.status_key,
    np.status_label,
    'nearest_upcoming_planned'::text
  from next_planned np
  union all
  select
    rc.session_entity_id,
    rc.list_caption,
    rc.session_date,
    rc.status_key,
    rc.status_label,
    'most_recent_completed'::text
  from recent_completed rc
  where not exists (select 1 from next_planned)
  limit 1;
$$;

create or replace function public.update_session(
  p_session_entity_id uuid,
  p_title text default null,
  p_session_date date default null,
  p_status_id uuid default null,
  p_session_number_label text default null,
  p_start_time time default null,
  p_clear_start_time boolean default false,
  p_end_time time default null,
  p_clear_end_time boolean default false,
  p_public_summary text default null,
  p_gm_summary text default null,
  p_next_session_teaser text default null
)
returns table (
  campaign_id uuid,
  entity_id uuid
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_entity_type_id uuid;
  v_campaign_id uuid;
  v_status_id uuid;
  v_existing public.sessions%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select s.*
  into v_existing
  from public.sessions s
  join public.campaign_entities ce on ce.id = s.entity_id
  where s.entity_id = p_session_entity_id
    and ce.deleted_at is null;

  if v_existing.entity_id is null then
    raise exception 'Session not found';
  end if;

  select ce.campaign_id, ce.entity_type_id
  into v_campaign_id, v_entity_type_id
  from public.campaign_entities ce
  where ce.id = p_session_entity_id;

  if not public.can_edit_entity_core(p_session_entity_id) then
    raise exception 'You do not have permission to edit this session';
  end if;

  v_status_id := coalesce(
    public.require_entity_status(v_campaign_id, v_entity_type_id, p_status_id, false),
    v_existing.status_id
  );

  update public.campaign_entities
  set list_caption = case
        when p_title is null then list_caption
        else nullif(trim(p_title), '')
      end,
      status_id = v_status_id,
      relevant_date = coalesce(p_session_date, relevant_date),
      updated_by = v_user_id,
      updated_at = now()
  where id = p_session_entity_id;

  update public.sessions
  set title = case
        when p_title is null then title
        else nullif(trim(p_title), '')
      end,
      session_date = coalesce(p_session_date, session_date),
      status_id = v_status_id,
      session_number_label = case
        when p_session_number_label is null then session_number_label
        else nullif(trim(p_session_number_label), '')
      end,
      start_time = case
        when p_clear_start_time then null
        when p_start_time is not null then p_start_time
        else start_time
      end,
      end_time = case
        when p_clear_end_time then null
        when p_end_time is not null then p_end_time
        else end_time
      end,
      public_summary = case
        when p_public_summary is null then public_summary
        else nullif(trim(p_public_summary), '')
      end,
      gm_summary = case
        when p_gm_summary is null then gm_summary
        else nullif(trim(p_gm_summary), '')
      end,
      next_session_teaser = case
        when p_next_session_teaser is null then next_session_teaser
        else nullif(trim(p_next_session_teaser), '')
      end,
      updated_by = v_user_id
  where entity_id = p_session_entity_id;

  return query
  select v_campaign_id, p_session_entity_id;
end;
$$;

create or replace function public.update_storyline(
  p_storyline_entity_id uuid,
  p_title text default null,
  p_status_id uuid default null,
  p_storyline_type text default null,
  p_priority_option_id uuid default null,
  p_clear_priority_option boolean default false,
  p_storyline_category_option_id uuid default null,
  p_clear_storyline_category_option boolean default false,
  p_is_major boolean default null,
  p_parent_storyline_entity_id uuid default null,
  p_clear_parent_storyline boolean default false,
  p_public_summary text default null,
  p_gm_summary text default null,
  p_primary_location_entity_id uuid default null,
  p_clear_primary_location boolean default false,
  p_reward_text text default null,
  p_completed_at timestamptz default null,
  p_clear_completed_at boolean default false,
  p_sort_order integer default null
  ,
  p_clear_sort_order boolean default false
)
returns table (
  campaign_id uuid,
  entity_id uuid
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_entity_type_id uuid;
  v_campaign_id uuid;
  v_status_id uuid;
  v_existing public.storylines%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select st.*
  into v_existing
  from public.storylines st
  join public.campaign_entities ce on ce.id = st.entity_id
  where st.entity_id = p_storyline_entity_id
    and ce.deleted_at is null;

  if v_existing.entity_id is null then
    raise exception 'Storyline not found';
  end if;

  select ce.campaign_id, ce.entity_type_id
  into v_campaign_id, v_entity_type_id
  from public.campaign_entities ce
  where ce.id = p_storyline_entity_id;

  if not public.can_edit_entity_core(p_storyline_entity_id) then
    raise exception 'You do not have permission to edit this storyline';
  end if;

  v_status_id := coalesce(
    public.require_entity_status(v_campaign_id, v_entity_type_id, p_status_id, false),
    v_existing.status_id
  );

  if p_storyline_type is not null and p_storyline_type not in ('quest', 'thread') then
    raise exception 'Invalid storyline type';
  end if;

  update public.campaign_entities
  set list_caption = case
        when p_title is null then list_caption
        else trim(p_title)
      end,
      status_id = v_status_id,
      parent_entity_id = case
        when p_clear_parent_storyline then null
        when p_parent_storyline_entity_id is not null then public.require_campaign_entity_ref(v_campaign_id, 'storyline', p_parent_storyline_entity_id, false)
        else parent_entity_id
      end,
      updated_by = v_user_id,
      updated_at = now()
  where id = p_storyline_entity_id;

  update public.storylines
  set title = case
        when p_title is null then title
        else trim(p_title)
      end,
      status_id = v_status_id,
      storyline_type = coalesce(p_storyline_type, storyline_type),
      priority_option_id = case
        when p_clear_priority_option then null
        when p_priority_option_id is not null then public.require_campaign_option(v_campaign_id, 'storyline_priority', p_priority_option_id, false)
        else priority_option_id
      end,
      storyline_category_option_id = case
        when p_clear_storyline_category_option then null
        when p_storyline_category_option_id is not null then public.require_campaign_option(v_campaign_id, 'storyline_category', p_storyline_category_option_id, false)
        else storyline_category_option_id
      end,
      is_major = coalesce(p_is_major, is_major),
      parent_storyline_entity_id = case
        when p_clear_parent_storyline then null
        when p_parent_storyline_entity_id is not null then public.require_campaign_entity_ref(v_campaign_id, 'storyline', p_parent_storyline_entity_id, false)
        else parent_storyline_entity_id
      end,
      public_summary = case
        when p_public_summary is null then public_summary
        else nullif(trim(p_public_summary), '')
      end,
      gm_summary = case
        when p_gm_summary is null then gm_summary
        else nullif(trim(p_gm_summary), '')
      end,
      primary_location_entity_id = case
        when p_clear_primary_location then null
        when p_primary_location_entity_id is not null then public.require_campaign_entity_ref(v_campaign_id, 'location', p_primary_location_entity_id, false)
        else primary_location_entity_id
      end,
      reward_text = case
        when p_reward_text is null then reward_text
        else nullif(trim(p_reward_text), '')
      end,
      completed_at = case
        when p_clear_completed_at then null
        when p_completed_at is not null then p_completed_at
        else completed_at
      end,
      sort_order = case
        when p_clear_sort_order then null
        when p_sort_order is not null then p_sort_order
        else sort_order
      end,
      updated_by = v_user_id
  where entity_id = p_storyline_entity_id;

  return query
  select v_campaign_id, p_storyline_entity_id;
end;
$$;

create or replace function public.update_encounter(
  p_encounter_entity_id uuid,
  p_title text default null,
  p_status_id uuid default null,
  p_encounter_type_option_id uuid default null,
  p_difficulty_option_id uuid default null,
  p_clear_difficulty_option boolean default false,
  p_related_session_entity_id uuid default null,
  p_clear_related_session boolean default false,
  p_related_storyline_entity_id uuid default null,
  p_clear_related_storyline boolean default false,
  p_sort_order integer default null
  ,
  p_clear_sort_order boolean default false
)
returns table (
  campaign_id uuid,
  entity_id uuid
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_entity_type_id uuid;
  v_campaign_id uuid;
  v_status_id uuid;
  v_existing public.encounters%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select e.*
  into v_existing
  from public.encounters e
  join public.campaign_entities ce on ce.id = e.entity_id
  where e.entity_id = p_encounter_entity_id
    and ce.deleted_at is null;

  if v_existing.entity_id is null then
    raise exception 'Encounter not found';
  end if;

  select ce.campaign_id, ce.entity_type_id
  into v_campaign_id, v_entity_type_id
  from public.campaign_entities ce
  where ce.id = p_encounter_entity_id;

  if not public.can_edit_entity_core(p_encounter_entity_id) then
    raise exception 'You do not have permission to edit this encounter';
  end if;

  v_status_id := coalesce(
    public.require_entity_status(v_campaign_id, v_entity_type_id, p_status_id, false),
    v_existing.status_id
  );

  update public.campaign_entities
  set list_caption = case
        when p_title is null then list_caption
        else nullif(trim(p_title), '')
      end,
      status_id = v_status_id,
      related_session_entity_id = case
        when p_clear_related_session then null
        when p_related_session_entity_id is not null then public.require_campaign_entity_ref(v_campaign_id, 'session', p_related_session_entity_id, false)
        else related_session_entity_id
      end,
      updated_by = v_user_id,
      updated_at = now()
  where id = p_encounter_entity_id;

  update public.encounters
  set title = case
        when p_title is null then title
        else nullif(trim(p_title), '')
      end,
      status_id = v_status_id,
      encounter_type_option_id = coalesce(
        public.require_campaign_option(v_campaign_id, 'encounter_type', p_encounter_type_option_id, false),
        encounter_type_option_id
      ),
      difficulty_option_id = case
        when p_clear_difficulty_option then null
        when p_difficulty_option_id is not null then public.require_campaign_option(v_campaign_id, 'encounter_difficulty', p_difficulty_option_id, false)
        else difficulty_option_id
      end,
      related_session_entity_id = case
        when p_clear_related_session then null
        when p_related_session_entity_id is not null then public.require_campaign_entity_ref(v_campaign_id, 'session', p_related_session_entity_id, false)
        else related_session_entity_id
      end,
      related_storyline_entity_id = case
        when p_clear_related_storyline then null
        when p_related_storyline_entity_id is not null then public.require_campaign_entity_ref(v_campaign_id, 'storyline', p_related_storyline_entity_id, false)
        else related_storyline_entity_id
      end,
      sort_order = case
        when p_clear_sort_order then null
        when p_sort_order is not null then p_sort_order
        else sort_order
      end,
      updated_by = v_user_id
  where entity_id = p_encounter_entity_id;

  return query
  select v_campaign_id, p_encounter_entity_id;
end;
$$;

drop function if exists public.get_campaign_activity(uuid);
drop function if exists public.get_campaign_activity(uuid, text, integer, uuid);

create function public.get_campaign_activity(
  p_campaign_id uuid,
  p_role_view text default null,
  p_limit integer default 30,
  p_related_entity_id uuid default null
)
returns table (
  campaign_id uuid,
  activity_type text,
  subject_type text,
  subject_id uuid,
  subject_entity_id uuid,
  actor_user_id uuid,
  actor_display_label text,
  occurred_at timestamptz,
  label text,
  visibility text,
  subject_label text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with activity_rows as (
    select
      ce.campaign_id,
      case when ce.created_at = ce.updated_at then 'entity_created' else 'entity_updated' end as activity_type,
      'campaign_entity'::text as subject_type,
      ce.id as subject_id,
      ce.id as subject_entity_id,
      ce.updated_by as actor_user_id,
      coalesce(cm.display_name_override, up.display_name) as actor_display_label,
      greatest(ce.updated_at, ce.created_at) as occurred_at,
      case when ce.created_at = ce.updated_at then 'Created' else 'Updated' end || ' ' || lower(et.label) || ': ' || ce.list_caption as label,
      ce.default_visibility as visibility,
      ce.list_caption as subject_label
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    left join public.user_profiles up on up.user_id = ce.updated_by
    left join public.campaign_memberships cm
      on cm.campaign_id = ce.campaign_id
     and cm.user_id = ce.updated_by
     and cm.status = 'active'
    where ce.campaign_id = p_campaign_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
      and (
        p_related_entity_id is null
        or ce.id = p_related_entity_id
        or ce.related_session_entity_id = p_related_entity_id
        or ce.parent_entity_id = p_related_entity_id
      )

    union all

    select
      n.campaign_id,
      case when n.created_at = n.updated_at then 'note_created' else 'note_updated' end,
      'note'::text,
      n.id,
      attached_entity.entity_id,
      n.updated_by,
      coalesce(cm.display_name_override, up.display_name),
      greatest(n.updated_at, n.created_at),
      case
        when attached_entity.entity_id is not null then
          case when n.created_at = n.updated_at then 'Created note on ' else 'Updated note on ' end || attached_entity.label
        else
          case when n.created_at = n.updated_at then 'Created campaign note' else 'Updated campaign note' end
      end,
      n.visibility,
      coalesce(attached_entity.label, 'Campaign note')
    from public.notes n
    left join lateral (
      select
        na.entity_id,
        public.entity_ref_label_for_role(na.entity_id, p_role_view) as label
      from public.note_attachments na
      where na.note_id = n.id
        and na.target_type = 'entity'
        and public.can_view_campaign_entity_for_role(na.entity_id, p_role_view)
      order by na.created_at, na.entity_id
      limit 1
    ) attached_entity on true
    left join lateral (
      select na.entity_id
      from public.note_attachments na
      where na.note_id = n.id
        and na.target_type = 'entity'
      order by na.created_at, na.entity_id
      limit 1
    ) primary_entity on true
    left join public.user_profiles up on up.user_id = n.updated_by
    left join public.campaign_memberships cm
      on cm.campaign_id = n.campaign_id
     and cm.user_id = n.updated_by
     and cm.status = 'active'
    where n.campaign_id = p_campaign_id
      and n.deleted_at is null
      and public.can_view_entity_visibility_for_role(
        n.campaign_id,
        n.visibility,
        n.author_user_id,
        primary_entity.entity_id,
        p_role_view
      )
      and (
        exists (
          select 1
          from public.note_attachments na
          where na.note_id = n.id
            and na.target_type = 'campaign'
        )
        or exists (
          select 1
          from public.note_attachments na
          where na.note_id = n.id
            and na.target_type = 'entity'
            and public.can_view_campaign_entity_for_role(na.entity_id, p_role_view)
        )
      )
      and (
        p_related_entity_id is null
        or exists (
          select 1
          from public.note_attachments na
          where na.note_id = n.id
            and na.target_type = 'entity'
            and na.entity_id = p_related_entity_id
        )
      )

    union all

    select
      ce.campaign_id,
      'section_updated'::text,
      'entity_section'::text,
      es.id,
      ce.id,
      es.updated_by,
      coalesce(cm.display_name_override, up.display_name),
      greatest(es.updated_at, es.created_at),
      'Updated ' || es.label || ' on ' || ce.list_caption,
      es.visibility,
      ce.list_caption
    from public.entity_sections es
    join public.campaign_entities ce on ce.id = es.entity_id
    left join public.user_profiles up on up.user_id = es.updated_by
    left join public.campaign_memberships cm
      on cm.campaign_id = ce.campaign_id
     and cm.user_id = es.updated_by
     and cm.status = 'active'
    where ce.campaign_id = p_campaign_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
      and public.can_view_entity_visibility_for_role(
        ce.campaign_id,
        es.visibility,
        es.created_by,
        es.entity_id,
        p_role_view
      )
      and (p_related_entity_id is null or ce.id = p_related_entity_id)

    union all

    select
      esc.campaign_id,
      case when esc.created_at = esc.updated_at then 'contribution_created' else 'contribution_updated' end,
      'entity_section_contribution'::text,
      esc.id,
      ce.id,
      esc.updated_by,
      coalesce(cm.display_name_override, up.display_name),
      greatest(esc.updated_at, esc.created_at),
      case when esc.created_at = esc.updated_at then 'Added contribution to ' else 'Updated contribution in ' end || es.label || ' on ' || ce.list_caption,
      esc.visibility,
      ce.list_caption
    from public.entity_section_contributions esc
    join public.entity_sections es on es.id = esc.section_id
    join public.campaign_entities ce on ce.id = es.entity_id
    left join public.user_profiles up on up.user_id = esc.updated_by
    left join public.campaign_memberships cm
      on cm.campaign_id = esc.campaign_id
     and cm.user_id = esc.updated_by
     and cm.status = 'active'
    where esc.campaign_id = p_campaign_id
      and esc.deleted_at is null
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
      and public.can_view_entity_visibility_for_role(
        ce.campaign_id,
        es.visibility,
        es.created_by,
        es.entity_id,
        p_role_view
      )
      and public.can_view_entity_visibility_for_role(
        esc.campaign_id,
        esc.visibility,
        esc.author_user_id,
        es.entity_id,
        p_role_view
      )
      and (p_related_entity_id is null or ce.id = p_related_entity_id)

    union all

    select
      er.campaign_id,
      case when er.created_at = er.updated_at then 'relationship_created' else 'relationship_updated' end,
      'relationship'::text,
      er.id,
      er.source_entity_id,
      er.updated_by,
      coalesce(cm.display_name_override, up.display_name),
      greatest(er.updated_at, er.created_at),
      case when er.created_at = er.updated_at then 'Linked ' else 'Updated link: ' end
        || public.entity_ref_label_for_role(er.source_entity_id, p_role_view)
        || ' and '
        || public.entity_ref_label_for_role(er.target_entity_id, p_role_view),
      er.visibility,
      public.entity_ref_label_for_role(er.source_entity_id, p_role_view)
    from public.entity_relationships er
    left join public.user_profiles up on up.user_id = er.updated_by
    left join public.campaign_memberships cm
      on cm.campaign_id = er.campaign_id
     and cm.user_id = er.updated_by
     and cm.status = 'active'
    where er.campaign_id = p_campaign_id
      and er.deleted_at is null
      and public.can_view_entity_visibility_for_role(
        er.campaign_id,
        er.visibility,
        er.created_by,
        er.source_entity_id,
        p_role_view
      )
      and public.can_view_campaign_entity_for_role(er.source_entity_id, p_role_view)
      and public.can_view_campaign_entity_for_role(er.target_entity_id, p_role_view)
      and (
        p_related_entity_id is null
        or er.source_entity_id = p_related_entity_id
        or er.target_entity_id = p_related_entity_id
      )
  )
  select
    campaign_id,
    activity_type,
    subject_type,
    subject_id,
    subject_entity_id,
    actor_user_id,
    actor_display_label,
    occurred_at,
    label,
    visibility,
    subject_label
  from activity_rows
  order by occurred_at desc, subject_id desc
  limit greatest(coalesce(p_limit, 30), 1);
$$;

alter table public.session_attending_users enable row level security;
alter table public.session_attending_characters enable row level security;

revoke all on public.session_attending_users from anon, public;
revoke all on public.session_attending_characters from anon, public;
grant select, insert, update, delete on public.session_attending_users to authenticated;
grant select, insert, update, delete on public.session_attending_characters to authenticated;

revoke all on function public.assert_manage_session_attendance(uuid) from public, anon;
revoke all on function public.validate_session_attending_user() from public, anon;
revoke all on function public.validate_session_attending_character() from public, anon;
revoke all on function public.get_session_attendance(uuid, text) from public, anon;
revoke all on function public.update_session_attendance(uuid, uuid[], uuid[]) from public, anon;
revoke all on function public.get_current_session(uuid, text) from public, anon;
revoke all on function public.update_session(uuid, text, date, uuid, text, time, boolean, time, boolean, text, text, text) from public, anon;
revoke all on function public.update_storyline(uuid, text, uuid, text, uuid, boolean, uuid, boolean, boolean, uuid, boolean, text, text, uuid, boolean, text, timestamptz, boolean, integer, boolean) from public, anon;
revoke all on function public.update_encounter(uuid, text, uuid, uuid, uuid, boolean, uuid, boolean, uuid, boolean, integer, boolean) from public, anon;
revoke all on function public.get_campaign_activity(uuid, text, integer, uuid) from public, anon;

grant execute on function public.assert_manage_session_attendance(uuid) to authenticated, service_role;
grant execute on function public.get_session_attendance(uuid, text) to authenticated, service_role;
grant execute on function public.update_session_attendance(uuid, uuid[], uuid[]) to authenticated, service_role;
grant execute on function public.get_current_session(uuid, text) to authenticated, service_role;
grant execute on function public.update_session(uuid, text, date, uuid, text, time, boolean, time, boolean, text, text, text) to authenticated, service_role;
grant execute on function public.update_storyline(uuid, text, uuid, text, uuid, boolean, uuid, boolean, boolean, uuid, boolean, text, text, uuid, boolean, text, timestamptz, boolean, integer, boolean) to authenticated, service_role;
grant execute on function public.update_encounter(uuid, text, uuid, uuid, uuid, boolean, uuid, boolean, uuid, boolean, integer, boolean) to authenticated, service_role;
grant execute on function public.get_campaign_activity(uuid, text, integer, uuid) to authenticated, service_role;
