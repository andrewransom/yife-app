create table public.characters (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  controlling_user_id uuid not null references auth.users(id) on delete restrict,
  image_asset_id uuid references public.media_assets(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.npcs (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  apparent_status_id uuid not null references public.status_definitions(id) on delete restrict,
  real_status_id uuid not null references public.status_definitions(id) on delete restrict,
  faction_entity_id uuid references public.campaign_entities(id) on delete set null,
  image_asset_id uuid references public.media_assets(id) on delete set null,
  stat_block_jsonb jsonb,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.parties (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.factions (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  status_id uuid references public.status_definitions(id) on delete restrict,
  parent_faction_entity_id uuid references public.campaign_entities(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.locations (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  location_type_option_id uuid not null references public.entity_option_definitions(id) on delete restrict,
  status_id uuid references public.status_definitions(id) on delete restrict,
  parent_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  image_asset_id uuid references public.media_assets(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.quests (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  priority_option_id uuid references public.entity_option_definitions(id) on delete restrict,
  is_major boolean not null default false,
  parent_quest_entity_id uuid references public.campaign_entities(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sessions (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  session_date date not null,
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.plot_arcs (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.encounters (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  encounter_type_option_id uuid not null references public.entity_option_definitions(id) on delete restrict,
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  related_session_entity_id uuid references public.campaign_entities(id) on delete set null,
  related_plot_arc_entity_id uuid references public.campaign_entities(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.timeline_events (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  date_expression text not null check (length(trim(date_expression)) > 0),
  sort_key text,
  event_type_option_id uuid not null references public.entity_option_definitions(id) on delete restrict,
  related_session_entity_id uuid references public.campaign_entities(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.entity_sections (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  section_definition_id uuid not null references public.entity_section_definitions(id) on delete restrict,
  section_key text not null,
  label text not null,
  visibility text not null check (visibility in ('shared', 'gm_only', 'private')),
  edit_policy text not null check (edit_policy in ('gm_edit', 'owner_edit', 'player_edit', 'append_contributions')),
  content_mode text not null check (content_mode in ('document', 'contribution_feed')),
  body_json jsonb not null default '{"type":"doc","content":[{"type":"paragraph"}]}'::jsonb,
  body_text text not null default '',
  body_preview text,
  version_number integer not null default 1 check (version_number > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entity_sections_key_unique unique (entity_id, section_key)
);

create table public.entity_aliases (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  alias_text text not null check (length(trim(alias_text)) > 0),
  alias_type text not null default 'alternate_name'
    check (alias_type in ('nickname', 'alternate_name', 'title', 'other')),
  visibility text not null check (visibility in ('shared', 'gm_only', 'private')),
  is_preferred boolean not null default false,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index campaign_entities_directory_idx
  on public.campaign_entities (campaign_id, entity_type_id, deleted_at, archived_at, updated_at desc);
create index characters_controlling_user_idx on public.characters (controlling_user_id);
create index npcs_faction_idx on public.npcs (faction_entity_id);
create index factions_parent_idx on public.factions (parent_faction_entity_id);
create index locations_parent_idx on public.locations (parent_location_entity_id);
create index quests_parent_idx on public.quests (parent_quest_entity_id);
create index sessions_date_status_idx on public.sessions (session_date, status_id);
create index encounters_session_idx on public.encounters (related_session_entity_id);
create index encounters_plot_arc_idx on public.encounters (related_plot_arc_entity_id);
create index timeline_events_sort_idx on public.timeline_events (sort_key, created_at);
create index entity_sections_entity_idx on public.entity_sections (entity_id, section_key);
create index entity_aliases_entity_idx on public.entity_aliases (entity_id) where deleted_at is null;

create trigger characters_set_updated_at
  before update on public.characters
  for each row execute function public.set_updated_at();
create trigger npcs_set_updated_at
  before update on public.npcs
  for each row execute function public.set_updated_at();
create trigger parties_set_updated_at
  before update on public.parties
  for each row execute function public.set_updated_at();
create trigger factions_set_updated_at
  before update on public.factions
  for each row execute function public.set_updated_at();
create trigger locations_set_updated_at
  before update on public.locations
  for each row execute function public.set_updated_at();
create trigger quests_set_updated_at
  before update on public.quests
  for each row execute function public.set_updated_at();
create trigger sessions_set_updated_at
  before update on public.sessions
  for each row execute function public.set_updated_at();
create trigger plot_arcs_set_updated_at
  before update on public.plot_arcs
  for each row execute function public.set_updated_at();
create trigger encounters_set_updated_at
  before update on public.encounters
  for each row execute function public.set_updated_at();
create trigger timeline_events_set_updated_at
  before update on public.timeline_events
  for each row execute function public.set_updated_at();
create trigger entity_sections_set_updated_at
  before update on public.entity_sections
  for each row execute function public.set_updated_at();
create trigger entity_aliases_set_updated_at
  before update on public.entity_aliases
  for each row execute function public.set_updated_at();

create or replace function public.can_view_campaign_entity(p_entity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.campaign_entities ce
    where ce.id = p_entity_id
      and ce.deleted_at is null
      and public.is_campaign_member(ce.campaign_id)
      and (
        ce.default_visibility = 'shared'
        or (ce.default_visibility = 'gm_only' and public.can_view_gm_content(ce.campaign_id))
        or (ce.default_visibility = 'private' and ce.created_by = public.current_user_id())
      )
  )
$$;

create or replace function public.entity_ref_label(p_entity_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when p_entity_id is null then null
    when public.can_view_campaign_entity(p_entity_id) then (
      select ce.list_caption
      from public.campaign_entities ce
      where ce.id = p_entity_id
    )
    else null
  end
$$;

create or replace function public.validate_typed_entity()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = new.entity_id
      and et.key = tg_argv[0]
  ) then
    raise exception 'Typed detail row references the wrong entity type';
  end if;

  return new;
end;
$$;

create trigger characters_validate_entity_type
  before insert or update of entity_id on public.characters
  for each row execute function public.validate_typed_entity('character');
create trigger npcs_validate_entity_type
  before insert or update of entity_id on public.npcs
  for each row execute function public.validate_typed_entity('npc');
create trigger parties_validate_entity_type
  before insert or update of entity_id on public.parties
  for each row execute function public.validate_typed_entity('party');
create trigger factions_validate_entity_type
  before insert or update of entity_id on public.factions
  for each row execute function public.validate_typed_entity('faction');
create trigger locations_validate_entity_type
  before insert or update of entity_id on public.locations
  for each row execute function public.validate_typed_entity('location');
create trigger quests_validate_entity_type
  before insert or update of entity_id on public.quests
  for each row execute function public.validate_typed_entity('quest');
create trigger sessions_validate_entity_type
  before insert or update of entity_id on public.sessions
  for each row execute function public.validate_typed_entity('session');
create trigger plot_arcs_validate_entity_type
  before insert or update of entity_id on public.plot_arcs
  for each row execute function public.validate_typed_entity('plot_arc');
create trigger encounters_validate_entity_type
  before insert or update of entity_id on public.encounters
  for each row execute function public.validate_typed_entity('encounter');
create trigger timeline_events_validate_entity_type
  before insert or update of entity_id on public.timeline_events
  for each row execute function public.validate_typed_entity('timeline_event');

create or replace function public.validate_entity_section()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.campaign_entities ce
    join public.entity_section_definitions esd
      on esd.id = new.section_definition_id
     and esd.entity_type_id = ce.entity_type_id
     and esd.section_key = new.section_key
    where ce.id = new.entity_id
  ) then
    raise exception 'Entity section definition must match the parent entity type';
  end if;

  return new;
end;
$$;

create trigger entity_sections_validate_definition
  before insert or update of entity_id, section_definition_id, section_key on public.entity_sections
  for each row execute function public.validate_entity_section();

create or replace function public.require_entity_status(
  p_campaign_id uuid,
  p_entity_type_id uuid,
  p_status_id uuid,
  p_required boolean default true
)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_status_id is null then
    if p_required then
      raise exception 'Status is required';
    end if;
    return null;
  end if;

  if not exists (
    select 1
    from public.status_definitions sd
    where sd.id = p_status_id
      and sd.subject_key = 'entity'
      and sd.entity_type_id = p_entity_type_id
      and sd.is_active
      and (sd.campaign_id is null or sd.campaign_id = p_campaign_id)
  ) then
    raise exception 'Invalid entity status';
  end if;

  return p_status_id;
end;
$$;

create or replace function public.require_entity_option(
  p_campaign_id uuid,
  p_entity_type_id uuid,
  p_group_key text,
  p_option_id uuid,
  p_required boolean default true
)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_option_id is null then
    if p_required then
      raise exception 'Option is required';
    end if;
    return null;
  end if;

  if not exists (
    select 1
    from public.entity_option_definitions eod
    where eod.id = p_option_id
      and eod.entity_type_id = p_entity_type_id
      and eod.group_key = p_group_key
      and eod.is_active
      and (eod.campaign_id is null or eod.campaign_id = p_campaign_id)
  ) then
    raise exception 'Invalid entity option';
  end if;

  return p_option_id;
end;
$$;

create or replace function public.require_campaign_entity_ref(
  p_campaign_id uuid,
  p_entity_type_key text,
  p_entity_id uuid,
  p_required boolean default false
)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_entity_id is null then
    if p_required then
      raise exception 'Entity reference is required';
    end if;
    return null;
  end if;

  if not exists (
    select 1
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = p_entity_id
      and ce.campaign_id = p_campaign_id
      and ce.deleted_at is null
      and et.key = p_entity_type_key
  ) then
    raise exception 'Invalid entity reference';
  end if;

  return p_entity_id;
end;
$$;

drop view public.campaign_entity_summaries;
drop function public.get_campaign_entity_summaries(uuid);

create or replace function public.get_campaign_entity_summaries(p_campaign_id uuid)
returns table (
  campaign_id uuid,
  entity_id uuid,
  entity_type_key text,
  list_caption text,
  default_visibility text,
  status_key text,
  status_label text,
  primary_image_asset_id uuid,
  primary_image_alt_text text,
  primary_image_thumb_bucket text,
  primary_image_thumb_path text,
  primary_image_thumb_width integer,
  primary_image_thumb_height integer,
  primary_image_grid_bucket text,
  primary_image_grid_path text,
  primary_image_grid_width integer,
  primary_image_grid_height integer,
  primary_image_is_decorative boolean,
  relevant_date date,
  sort_key text,
  parent_entity_id uuid,
  parent_entity_label text,
  related_session_entity_id uuid,
  related_session_label text,
  related_plot_arc_entity_id uuid,
  related_plot_arc_label text,
  controlling_user_display_label text,
  npc_apparent_status_label text,
  location_type_label text,
  quest_priority_label text,
  is_major boolean,
  encounter_type_label text,
  timeline_date_expression text,
  timeline_event_type_label text,
  updated_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    ce.campaign_id,
    ce.id as entity_id,
    et.key as entity_type_key,
    ce.list_caption,
    ce.default_visibility,
    sd.key as status_key,
    sd.label as status_label,
    ma.id as primary_image_asset_id,
    ma.alt_text as primary_image_alt_text,
    thumb.storage_bucket as primary_image_thumb_bucket,
    thumb.storage_path as primary_image_thumb_path,
    thumb.width as primary_image_thumb_width,
    thumb.height as primary_image_thumb_height,
    grid.storage_bucket as primary_image_grid_bucket,
    grid.storage_path as primary_image_grid_path,
    grid.width as primary_image_grid_width,
    grid.height as primary_image_grid_height,
    ma.is_decorative as primary_image_is_decorative,
    ce.relevant_date,
    ce.sort_key,
    case
      when public.can_view_campaign_entity(ce.parent_entity_id) then ce.parent_entity_id
      else null
    end as parent_entity_id,
    public.entity_ref_label(ce.parent_entity_id) as parent_entity_label,
    case
      when public.can_view_campaign_entity(ce.related_session_entity_id) then ce.related_session_entity_id
      else null
    end as related_session_entity_id,
    public.entity_ref_label(ce.related_session_entity_id) as related_session_label,
    case
      when public.can_view_campaign_entity(e.related_plot_arc_entity_id) then e.related_plot_arc_entity_id
      else null
    end as related_plot_arc_entity_id,
    public.entity_ref_label(e.related_plot_arc_entity_id) as related_plot_arc_label,
    coalesce(cm.display_name_override, up.display_name) as controlling_user_display_label,
    npc_apparent.label as npc_apparent_status_label,
    location_type.label as location_type_label,
    quest_priority.label as quest_priority_label,
    q.is_major,
    encounter_type.label as encounter_type_label,
    te.date_expression as timeline_date_expression,
    timeline_type.label as timeline_event_type_label,
    ce.updated_at,
    ce.archived_at,
    ce.deleted_at
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  left join public.status_definitions sd on sd.id = ce.status_id
  left join public.characters ch on ch.entity_id = ce.id
  left join public.campaign_memberships cm
    on cm.campaign_id = ce.campaign_id
   and cm.user_id = ch.controlling_user_id
   and cm.status = 'active'
  left join public.user_profiles up on up.user_id = ch.controlling_user_id
  left join public.npcs n on n.entity_id = ce.id
  left join public.status_definitions npc_apparent on npc_apparent.id = n.apparent_status_id
  left join public.locations l on l.entity_id = ce.id
  left join public.entity_option_definitions location_type on location_type.id = l.location_type_option_id
  left join public.quests q on q.entity_id = ce.id
  left join public.entity_option_definitions quest_priority on quest_priority.id = q.priority_option_id
  left join public.encounters e on e.entity_id = ce.id
  left join public.entity_option_definitions encounter_type on encounter_type.id = e.encounter_type_option_id
  left join public.timeline_events te on te.entity_id = ce.id
  left join public.entity_option_definitions timeline_type on timeline_type.id = te.event_type_option_id
  left join public.media_assets ma
    on ma.id = ce.primary_image_asset_id
   and ma.status = 'ready'
   and ma.deleted_at is null
  left join public.media_asset_variants thumb
    on thumb.media_asset_id = ma.id
   and thumb.version_key = ma.current_version_key
   and thumb.variant = 'thumb_160'
  left join public.media_asset_variants grid
    on grid.media_asset_id = ma.id
   and grid.version_key = ma.current_version_key
   and grid.variant = 'grid_480'
  where ce.campaign_id = p_campaign_id
    and ce.deleted_at is null
    and public.can_view_campaign_entity(ce.id)
  order by ce.updated_at desc;
$$;

create view public.campaign_entity_summaries
with (security_invoker = true)
as
select s.*
from public.campaign_entities ce
cross join lateral public.get_campaign_entity_summaries(ce.campaign_id) s
where s.entity_id = ce.id;

create or replace function public.get_entity_type_options(p_campaign_id uuid)
returns table (
  entity_type_id uuid,
  entity_type_key text,
  label text,
  plural_label text,
  icon_key text,
  default_visibility text,
  sort_order integer,
  is_enabled boolean,
  can_create boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    et.id,
    et.key,
    et.label,
    et.plural_label,
    et.icon_key,
    cets.default_visibility,
    et.sort_order,
    cets.is_enabled,
    public.can_mutate_campaign_config(p_campaign_id) and cets.is_enabled as can_create
  from public.entity_types et
  join public.campaign_entity_type_settings cets
    on cets.entity_type_id = et.id
   and cets.campaign_id = p_campaign_id
  where et.is_active
    and cets.is_enabled
    and public.is_campaign_member(p_campaign_id)
    and (
      cets.default_visibility <> 'gm_only'
      or public.can_view_gm_content(p_campaign_id)
    )
  order by et.sort_order;
$$;

create or replace function public.get_entity_status_options(
  p_campaign_id uuid,
  p_entity_type_key text
)
returns table (
  id uuid,
  key text,
  label text,
  sort_order integer
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select sd.id, sd.key, sd.label, sd.sort_order
  from public.status_definitions sd
  join public.entity_types et on et.id = sd.entity_type_id
  where sd.subject_key = 'entity'
    and et.key = p_entity_type_key
    and sd.is_active
    and (sd.campaign_id is null or sd.campaign_id = p_campaign_id)
    and public.is_campaign_member(p_campaign_id)
  order by sd.sort_order;
$$;

create or replace function public.get_entity_option_definitions(
  p_campaign_id uuid,
  p_entity_type_key text,
  p_group_key text default null
)
returns table (
  id uuid,
  entity_type_key text,
  group_key text,
  key text,
  label text,
  sort_order integer
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select eod.id, et.key, eod.group_key, eod.key, eod.label, eod.sort_order
  from public.entity_option_definitions eod
  join public.entity_types et on et.id = eod.entity_type_id
  where et.key = p_entity_type_key
    and eod.is_active
    and (p_group_key is null or eod.group_key = p_group_key)
    and (eod.campaign_id is null or eod.campaign_id = p_campaign_id)
    and public.is_campaign_member(p_campaign_id)
  order by eod.group_key, eod.sort_order;
$$;

create or replace function public.get_entity_detail(p_entity_id uuid)
returns table (
  campaign_id uuid,
  entity_id uuid,
  entity_type_key text,
  entity_type_label text,
  list_caption text,
  default_visibility text,
  status_key text,
  status_label text,
  relevant_date date,
  sort_key text,
  archived_at timestamptz,
  updated_at timestamptz,
  parent_entity_id uuid,
  parent_entity_label text,
  related_session_entity_id uuid,
  related_session_label text,
  related_plot_arc_entity_id uuid,
  related_plot_arc_label text,
  controlling_user_id uuid,
  controlling_user_display_label text,
  location_type_label text,
  quest_priority_label text,
  is_major boolean,
  encounter_type_label text,
  timeline_date_expression text,
  timeline_event_type_label text,
  npc_apparent_status_label text,
  npc_real_status_label text,
  sections jsonb
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    ce.campaign_id,
    ce.id as entity_id,
    et.key as entity_type_key,
    et.label as entity_type_label,
    ce.list_caption,
    ce.default_visibility,
    sd.key as status_key,
    sd.label as status_label,
    ce.relevant_date,
    ce.sort_key,
    ce.archived_at,
    ce.updated_at,
    case
      when public.can_view_campaign_entity(ce.parent_entity_id) then ce.parent_entity_id
      else null
    end as parent_entity_id,
    public.entity_ref_label(ce.parent_entity_id) as parent_entity_label,
    case
      when public.can_view_campaign_entity(ce.related_session_entity_id) then ce.related_session_entity_id
      else null
    end as related_session_entity_id,
    public.entity_ref_label(ce.related_session_entity_id) as related_session_label,
    case
      when public.can_view_campaign_entity(e.related_plot_arc_entity_id) then e.related_plot_arc_entity_id
      else null
    end as related_plot_arc_entity_id,
    public.entity_ref_label(e.related_plot_arc_entity_id) as related_plot_arc_label,
    ch.controlling_user_id,
    coalesce(cm.display_name_override, up.display_name) as controlling_user_display_label,
    location_type.label as location_type_label,
    quest_priority.label as quest_priority_label,
    q.is_major,
    encounter_type.label as encounter_type_label,
    te.date_expression as timeline_date_expression,
    timeline_type.label as timeline_event_type_label,
    npc_apparent.label as npc_apparent_status_label,
    case when public.can_view_gm_content(ce.campaign_id) then npc_real.label else null end as npc_real_status_label,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', es.id,
          'section_key', es.section_key,
          'label', es.label,
          'visibility', es.visibility,
          'edit_policy', es.edit_policy,
          'content_mode', es.content_mode,
          'body_preview', es.body_preview,
          'version_number', es.version_number
        )
        order by esd.sort_order, es.label
      )
      from public.entity_sections es
      join public.entity_section_definitions esd on esd.id = es.section_definition_id
      where es.entity_id = ce.id
        and (
          es.visibility = 'shared'
          or (es.visibility = 'gm_only' and public.can_view_gm_content(ce.campaign_id))
          or (es.visibility = 'private' and es.created_by = public.current_user_id())
        )
    ), '[]'::jsonb) as sections
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  left join public.status_definitions sd on sd.id = ce.status_id
  left join public.characters ch on ch.entity_id = ce.id
  left join public.campaign_memberships cm
    on cm.campaign_id = ce.campaign_id
   and cm.user_id = ch.controlling_user_id
   and cm.status = 'active'
  left join public.user_profiles up on up.user_id = ch.controlling_user_id
  left join public.npcs n on n.entity_id = ce.id
  left join public.status_definitions npc_apparent on npc_apparent.id = n.apparent_status_id
  left join public.status_definitions npc_real on npc_real.id = n.real_status_id
  left join public.locations l on l.entity_id = ce.id
  left join public.entity_option_definitions location_type on location_type.id = l.location_type_option_id
  left join public.quests q on q.entity_id = ce.id
  left join public.entity_option_definitions quest_priority on quest_priority.id = q.priority_option_id
  left join public.encounters e on e.entity_id = ce.id
  left join public.entity_option_definitions encounter_type on encounter_type.id = e.encounter_type_option_id
  left join public.timeline_events te on te.entity_id = ce.id
  left join public.entity_option_definitions timeline_type on timeline_type.id = te.event_type_option_id
  where ce.id = p_entity_id
    and public.can_view_campaign_entity(ce.id);
$$;

create or replace function public.create_campaign_entity(
  p_campaign_id uuid,
  p_entity_type_key text,
  p_input jsonb default '{}'::jsonb
)
returns table (
  campaign_id uuid,
  entity_id uuid,
  entity_type_key text,
  list_caption text,
  default_visibility text,
  status_key text,
  status_label text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_entity_type_id uuid;
  v_default_visibility text;
  v_requested_visibility text;
  v_visibility text;
  v_list_caption text;
  v_status_id uuid;
  v_entity_id uuid;
  v_parent_entity_id uuid;
  v_related_session_entity_id uuid;
  v_related_plot_arc_entity_id uuid;
  v_option_id uuid;
  v_real_status_id uuid;
  v_controlling_user_id uuid;
  v_date date;
  v_sort_key text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not public.can_mutate_campaign_config(p_campaign_id) then
    raise exception 'Only campaign owners and GMs can create campaign entities';
  end if;

  select et.id, cets.default_visibility
    into v_entity_type_id, v_default_visibility
  from public.entity_types et
  join public.campaign_entity_type_settings cets
    on cets.entity_type_id = et.id
   and cets.campaign_id = p_campaign_id
  where et.key = p_entity_type_key
    and et.is_active
    and cets.is_enabled;

  if v_entity_type_id is null then
    raise exception 'Entity type is disabled or unknown';
  end if;

  v_requested_visibility := nullif(p_input ->> 'default_visibility', '');
  if v_requested_visibility is not null and v_requested_visibility not in ('shared', 'gm_only', 'private') then
    raise exception 'Invalid entity visibility';
  end if;
  v_visibility := coalesce(v_requested_visibility, v_default_visibility);

  if p_entity_type_key in ('plot_arc', 'encounter') and v_requested_visibility is null then
    v_visibility := 'gm_only';
  end if;

  if p_entity_type_key in ('character', 'npc', 'party', 'faction', 'location') then
    v_list_caption := trim(coalesce(nullif(p_input ->> 'list_caption', ''), p_input ->> 'name'));
  else
    v_list_caption := trim(coalesce(nullif(p_input ->> 'list_caption', ''), p_input ->> 'title'));
  end if;

  if v_list_caption is null or length(v_list_caption) = 0 then
    raise exception 'Entity name or title is required';
  end if;

  if p_entity_type_key = 'character' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_controlling_user_id := nullif(p_input ->> 'controlling_user_id', '')::uuid;

    if not exists (
      select 1
      from public.campaign_memberships cm
      where cm.campaign_id = p_campaign_id
        and cm.user_id = v_controlling_user_id
        and cm.status = 'active'
    ) then
      raise exception 'Character controller must be an active campaign member';
    end if;
  elsif p_entity_type_key = 'npc' then
    v_real_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'real_status_id', '')::uuid, true);
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'apparent_status_id', '')::uuid, false);
    v_status_id := coalesce(v_status_id, v_real_status_id);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'faction', nullif(p_input ->> 'faction_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'party' then
    v_status_id := null;
  elsif p_entity_type_key = 'faction' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, false);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'faction', nullif(p_input ->> 'parent_faction_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'location' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, false);
    v_option_id := public.require_entity_option(p_campaign_id, v_entity_type_id, 'location_type', nullif(p_input ->> 'location_type_option_id', '')::uuid, true);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'location', nullif(p_input ->> 'parent_location_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'quest' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_option_id := public.require_entity_option(p_campaign_id, v_entity_type_id, 'quest_priority', nullif(p_input ->> 'priority_option_id', '')::uuid, false);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'quest', nullif(p_input ->> 'parent_quest_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'session' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_date := (p_input ->> 'session_date')::date;
    if v_date is null then
      raise exception 'Session date is required';
    end if;
  elsif p_entity_type_key = 'plot_arc' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
  elsif p_entity_type_key = 'encounter' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_option_id := public.require_entity_option(p_campaign_id, v_entity_type_id, 'encounter_type', nullif(p_input ->> 'encounter_type_option_id', '')::uuid, true);
    v_related_session_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'session', nullif(p_input ->> 'related_session_entity_id', '')::uuid, false);
    v_related_plot_arc_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'plot_arc', nullif(p_input ->> 'related_plot_arc_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'timeline_event' then
    v_option_id := public.require_entity_option(p_campaign_id, v_entity_type_id, 'timeline_event_type', nullif(p_input ->> 'event_type_option_id', '')::uuid, true);
    v_related_session_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'session', nullif(p_input ->> 'related_session_entity_id', '')::uuid, false);
    v_sort_key := nullif(p_input ->> 'sort_key', '');
    if nullif(p_input ->> 'date_expression', '') is null then
      raise exception 'Timeline date expression is required';
    end if;
  else
    raise exception 'Unsupported entity type';
  end if;

  insert into public.campaign_entities (
    campaign_id,
    entity_type_id,
    list_caption,
    default_visibility,
    status_id,
    relevant_date,
    sort_key,
    parent_entity_id,
    related_session_entity_id,
    created_by,
    updated_by
  )
  values (
    p_campaign_id,
    v_entity_type_id,
    v_list_caption,
    v_visibility,
    v_status_id,
    v_date,
    v_sort_key,
    v_parent_entity_id,
    v_related_session_entity_id,
    v_user_id,
    v_user_id
  )
  returning id into v_entity_id;

  if p_entity_type_key = 'character' then
    insert into public.characters (entity_id, name, status_id, controlling_user_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_status_id, v_controlling_user_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'npc' then
    insert into public.npcs (entity_id, name, apparent_status_id, real_status_id, faction_entity_id, created_by, updated_by)
    values (
      v_entity_id,
      trim(p_input ->> 'name'),
      v_status_id,
      v_real_status_id,
      v_parent_entity_id,
      v_user_id,
      v_user_id
    );
  elsif p_entity_type_key = 'party' then
    insert into public.parties (entity_id, name, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_user_id, v_user_id);
  elsif p_entity_type_key = 'faction' then
    insert into public.factions (entity_id, name, status_id, parent_faction_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_status_id, v_parent_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'location' then
    insert into public.locations (entity_id, name, location_type_option_id, status_id, parent_location_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_option_id, v_status_id, v_parent_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'quest' then
    insert into public.quests (entity_id, title, status_id, priority_option_id, is_major, parent_quest_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), v_status_id, v_option_id, coalesce((p_input ->> 'is_major')::boolean, false), v_parent_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'session' then
    insert into public.sessions (entity_id, title, session_date, status_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), v_date, v_status_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'plot_arc' then
    insert into public.plot_arcs (entity_id, title, status_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), v_status_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'encounter' then
    insert into public.encounters (entity_id, title, encounter_type_option_id, status_id, related_session_entity_id, related_plot_arc_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), v_option_id, v_status_id, v_related_session_entity_id, v_related_plot_arc_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'timeline_event' then
    insert into public.timeline_events (entity_id, title, date_expression, sort_key, event_type_option_id, related_session_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), trim(p_input ->> 'date_expression'), v_sort_key, v_option_id, v_related_session_entity_id, v_user_id, v_user_id);
  end if;

  insert into public.entity_sections (
    entity_id,
    section_definition_id,
    section_key,
    label,
    visibility,
    edit_policy,
    content_mode,
    created_by,
    updated_by
  )
  select
    v_entity_id,
    esd.id,
    esd.section_key,
    esd.label,
    esd.default_visibility,
    esd.default_edit_policy,
    esd.default_content_mode,
    v_user_id,
    v_user_id
  from public.entity_section_definitions esd
  where esd.entity_type_id = v_entity_type_id
    and esd.is_active
  order by esd.sort_order;

  return query
  select
    s.campaign_id,
    s.entity_id,
    s.entity_type_key,
    s.list_caption,
    s.default_visibility,
    s.status_key,
    s.status_label,
    s.updated_at
  from public.get_campaign_entity_summaries(p_campaign_id) s
  where s.entity_id = v_entity_id;
end;
$$;

alter table public.characters enable row level security;
alter table public.npcs enable row level security;
alter table public.parties enable row level security;
alter table public.factions enable row level security;
alter table public.locations enable row level security;
alter table public.quests enable row level security;
alter table public.sessions enable row level security;
alter table public.plot_arcs enable row level security;
alter table public.encounters enable row level security;
alter table public.timeline_events enable row level security;
alter table public.entity_sections enable row level security;
alter table public.entity_aliases enable row level security;

create policy "Owners and GMs can read raw character rows"
  on public.characters for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = characters.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw npc rows"
  on public.npcs for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = npcs.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw party rows"
  on public.parties for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = parties.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw faction rows"
  on public.factions for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = factions.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw location rows"
  on public.locations for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = locations.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw quest rows"
  on public.quests for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = quests.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw session rows"
  on public.sessions for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = sessions.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw plot arc rows"
  on public.plot_arcs for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = plot_arcs.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw encounter rows"
  on public.encounters for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = encounters.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw timeline event rows"
  on public.timeline_events for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = timeline_events.entity_id and public.can_view_gm_content(ce.campaign_id)));

create policy "Visible entity sections can be read"
  on public.entity_sections for select to authenticated
  using (
    public.can_view_campaign_entity(entity_id)
    and (
      visibility = 'shared'
      or (visibility = 'gm_only' and exists (
        select 1 from public.campaign_entities ce
        where ce.id = entity_sections.entity_id
          and public.can_view_gm_content(ce.campaign_id)
      ))
      or (visibility = 'private' and created_by = public.current_user_id())
    )
  );

create policy "Visible entity aliases can be read"
  on public.entity_aliases for select to authenticated
  using (
    deleted_at is null
    and public.can_view_campaign_entity(entity_id)
    and (
      visibility = 'shared'
      or (visibility = 'gm_only' and exists (
        select 1 from public.campaign_entities ce
        where ce.id = entity_aliases.entity_id
          and public.can_view_gm_content(ce.campaign_id)
      ))
      or (visibility = 'private' and created_by = public.current_user_id())
    )
  );

revoke all on all tables in schema public from anon, public;
revoke all on all sequences in schema public from anon, public;
grant select on all tables in schema public to authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

revoke execute on all functions in schema public from anon, public;
grant execute on function public.can_view_campaign_entity(uuid) to authenticated, service_role;
grant execute on function public.entity_ref_label(uuid) to authenticated, service_role;
grant execute on function public.require_entity_status(uuid, uuid, uuid, boolean) to authenticated, service_role;
grant execute on function public.require_entity_option(uuid, uuid, text, uuid, boolean) to authenticated, service_role;
grant execute on function public.require_campaign_entity_ref(uuid, text, uuid, boolean) to authenticated, service_role;
grant execute on function public.get_campaign_entity_summaries(uuid) to authenticated, service_role;
grant execute on function public.get_entity_type_options(uuid) to authenticated, service_role;
grant execute on function public.get_entity_status_options(uuid, text) to authenticated, service_role;
grant execute on function public.get_entity_option_definitions(uuid, text, text) to authenticated, service_role;
grant execute on function public.get_entity_detail(uuid) to authenticated, service_role;
grant execute on function public.create_campaign_entity(uuid, text, jsonb) to authenticated, service_role;
