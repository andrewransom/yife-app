alter table public.characters
  add column species_ancestry_text text,
  add column pronouns text,
  add column public_summary text,
  add column gm_summary text,
  add column character_sheet_url text,
  add constraint characters_character_sheet_url_check check (
    character_sheet_url is null or character_sheet_url ~* '^https?://'
  );

create table public.character_class_progressions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  character_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  class_name text not null check (length(trim(class_name)) > 0),
  subclass_name text,
  level_number integer not null check (level_number > 0),
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.storylines (
  entity_id uuid primary key references public.campaign_entities(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  storyline_type text not null check (storyline_type in ('quest', 'thread')),
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  priority_option_id uuid references public.campaign_options(id) on delete restrict,
  is_major boolean not null default false,
  parent_storyline_entity_id uuid references public.campaign_entities(id) on delete set null,
  storyline_category_option_id uuid references public.campaign_options(id) on delete restrict,
  public_summary text,
  gm_summary text,
  primary_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  reward_text text,
  completed_at timestamptz,
  sort_order integer,
  palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  symbol_id uuid references public.campaign_symbols(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.character_hooks (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  character_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  description_text text not null check (length(trim(description_text)) > 0),
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  category_option_id uuid references public.campaign_options(id) on delete restrict,
  visibility text not null check (visibility in ('shared', 'gm_only', 'character_owner_gm')),
  gm_note_text text,
  promoted_storyline_entity_id uuid references public.campaign_entities(id) on delete set null,
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.npcs
  add column role_option_id uuid references public.campaign_options(id) on delete restrict,
  add column role_label text,
  add column speech_text text,
  add column party_disposition_option_id uuid references public.campaign_options(id) on delete restrict,
  add column relationship_to_party_text text,
  add column public_summary text,
  add column gm_summary text,
  add column public_current_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column gm_current_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column public_home_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column gm_home_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column reports_to_entity_id uuid references public.campaign_entities(id) on delete set null;

alter table public.parties
  add column status_id uuid references public.status_definitions(id) on delete restrict,
  add column public_summary text,
  add column gm_summary text,
  add column home_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column current_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  add column symbol_id uuid references public.campaign_symbols(id) on delete set null;

create table public.party_members (
  party_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  character_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  role_label text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (party_entity_id, character_entity_id)
);

alter table public.factions
  add column faction_type_option_id uuid references public.campaign_options(id) on delete restrict,
  add column scope_option_id uuid references public.campaign_options(id) on delete restrict,
  add column scope_visibility text not null default 'shared' check (scope_visibility in ('shared', 'gm_only')),
  add column numbers_text text,
  add column numbers_visibility text not null default 'gm_only' check (numbers_visibility in ('shared', 'gm_only')),
  add column public_summary text,
  add column gm_summary text,
  add column party_disposition_option_id uuid references public.campaign_options(id) on delete restrict,
  add column relationship_to_party_text text,
  add column headquarters_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column headquarters_visibility text not null default 'gm_only' check (headquarters_visibility in ('shared', 'gm_only')),
  add column territory_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column territory_visibility text not null default 'shared' check (territory_visibility in ('shared', 'gm_only')),
  add column leader_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column leader_visibility text not null default 'gm_only' check (leader_visibility in ('shared', 'gm_only')),
  add column public_goal_text text,
  add column gm_true_goal_text text,
  add column symbol_image_asset_id uuid references public.media_assets(id) on delete set null,
  add column palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  add column symbol_id uuid references public.campaign_symbols(id) on delete set null;

alter table public.locations
  alter column location_type_option_id drop not null,
  add column public_summary text,
  add column gm_summary text,
  add column known_to_party boolean not null default false,
  add column visited_by_party boolean not null default false,
  add column relationship_to_party_text text,
  add column party_disposition_option_id uuid references public.campaign_options(id) on delete restrict,
  add column controlling_faction_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column controlling_faction_visibility text not null default 'gm_only' check (controlling_faction_visibility in ('shared', 'gm_only')),
  add column owner_or_steward_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column owner_or_steward_visibility text not null default 'gm_only' check (owner_or_steward_visibility in ('shared', 'gm_only')),
  add column ruler_or_authority_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column ruler_or_authority_visibility text not null default 'gm_only' check (ruler_or_authority_visibility in ('shared', 'gm_only')),
  add column population_text text,
  add column population_visibility text not null default 'shared' check (population_visibility in ('shared', 'gm_only')),
  add column size_or_scale_text text,
  add column size_or_scale_visibility text not null default 'shared' check (size_or_scale_visibility in ('shared', 'gm_only')),
  add column terrain_option_id uuid references public.campaign_options(id) on delete restrict,
  add column danger_level_option_id uuid references public.campaign_options(id) on delete restrict,
  add column danger_level_visibility text not null default 'gm_only' check (danger_level_visibility in ('shared', 'gm_only')),
  add column accessibility_option_id uuid references public.campaign_options(id) on delete restrict,
  add column accessibility_visibility text not null default 'shared' check (accessibility_visibility in ('shared', 'gm_only')),
  add column map_image_asset_id uuid references public.media_assets(id) on delete set null,
  add column symbol_image_asset_id uuid references public.media_assets(id) on delete set null,
  add column palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  add column symbol_id uuid references public.campaign_symbols(id) on delete set null;

alter table public.sessions
  alter column title drop not null,
  drop constraint sessions_title_check,
  add column session_number_sort numeric,
  add column session_number_label text,
  add column start_time time,
  add column end_time time,
  add column public_summary text,
  add column gm_summary text,
  add column next_session_teaser text,
  add constraint sessions_title_check check (title is null or length(trim(title)) > 0),
  add constraint sessions_time_order_check check (start_time is null or end_time is null or end_time >= start_time);

alter table public.encounters
  alter column title drop not null,
  drop constraint encounters_title_check,
  add column related_storyline_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column difficulty_option_id uuid references public.campaign_options(id) on delete restrict,
  add column sort_order integer,
  add column palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  add column image_asset_id uuid references public.media_assets(id) on delete set null,
  add constraint encounters_title_check check (title is null or length(trim(title)) > 0);

create table public.encounter_statblocks (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  encounter_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  linked_npc_entity_id uuid references public.campaign_entities(id) on delete set null,
  label text not null check (length(trim(label)) > 0),
  quantity integer not null default 1 check (quantity > 0),
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.encounter_statblock_values (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  encounter_statblock_id uuid not null references public.encounter_statblocks(id) on delete cascade,
  field_id uuid not null references public.campaign_quick_stat_fields(id) on delete restrict,
  value_number numeric,
  value_text text,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint encounter_statblock_values_unique unique (encounter_statblock_id, field_id),
  constraint encounter_statblock_values_one_value_check check (
    (value_number is not null and value_text is null)
    or (value_number is null and value_text is not null)
    or (value_number is null and value_text is null)
  )
);

create table public.encounter_statblock_instances (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  encounter_statblock_id uuid not null references public.encounter_statblocks(id) on delete cascade,
  label text,
  current_hp integer,
  max_hp_override integer,
  is_defeated boolean not null default false,
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint encounter_statblock_instances_hp_check check (
    (current_hp is null or current_hp >= 0)
    and (max_hp_override is null or max_hp_override > 0)
  )
);

alter table public.timeline_events
  add column public_summary text,
  add column gm_summary text,
  add column primary_location_entity_id uuid references public.campaign_entities(id) on delete set null,
  add column palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  add column symbol_id uuid references public.campaign_symbols(id) on delete set null;

create trigger character_class_progressions_set_updated_at
  before update on public.character_class_progressions
  for each row execute function public.set_updated_at();
create trigger storylines_set_updated_at
  before update on public.storylines
  for each row execute function public.set_updated_at();
create trigger character_hooks_set_updated_at
  before update on public.character_hooks
  for each row execute function public.set_updated_at();
create trigger party_members_set_updated_at
  before update on public.party_members
  for each row execute function public.set_updated_at();
create trigger encounter_statblocks_set_updated_at
  before update on public.encounter_statblocks
  for each row execute function public.set_updated_at();
create trigger encounter_statblock_values_set_updated_at
  before update on public.encounter_statblock_values
  for each row execute function public.set_updated_at();
create trigger encounter_statblock_instances_set_updated_at
  before update on public.encounter_statblock_instances
  for each row execute function public.set_updated_at();

create trigger storylines_validate_entity_type
  before insert or update of entity_id on public.storylines
  for each row execute function public.validate_typed_entity('storyline');

create or replace function public.validate_same_campaign_entity_ref()
returns trigger
language plpgsql
as $$
declare
  v_campaign_id uuid;
  v_expected_type text := tg_argv[0];
  v_column_name text := tg_argv[1];
  v_ref_id uuid;
begin
  execute format('select ($1).%I', v_column_name) using new into v_ref_id;
  if v_ref_id is null then
    return new;
  end if;

  if tg_table_name in ('campaign_entities') then
    v_campaign_id := new.campaign_id;
  else
    select ce.campaign_id into v_campaign_id
    from public.campaign_entities ce
    where ce.id = new.entity_id;
  end if;

  if not exists (
    select 1
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = v_ref_id
      and ce.campaign_id = v_campaign_id
      and ce.deleted_at is null
      and (v_expected_type = '*' or et.key = v_expected_type)
  ) then
    raise exception 'Invalid entity reference for %.%', tg_table_name, v_column_name;
  end if;

  return new;
end;
$$;

create trigger storylines_validate_parent
  before insert or update of parent_storyline_entity_id on public.storylines
  for each row execute function public.validate_same_campaign_entity_ref('storyline', 'parent_storyline_entity_id');
create trigger storylines_validate_location
  before insert or update of primary_location_entity_id on public.storylines
  for each row execute function public.validate_same_campaign_entity_ref('location', 'primary_location_entity_id');
create trigger encounters_validate_storyline
  before insert or update of related_storyline_entity_id on public.encounters
  for each row execute function public.validate_same_campaign_entity_ref('storyline', 'related_storyline_entity_id');
create trigger timeline_events_validate_location
  before insert or update of primary_location_entity_id on public.timeline_events
  for each row execute function public.validate_same_campaign_entity_ref('location', 'primary_location_entity_id');

create trigger npcs_validate_faction
  before insert or update of faction_entity_id on public.npcs
  for each row execute function public.validate_same_campaign_entity_ref('faction', 'faction_entity_id');
create trigger npcs_validate_public_current_location
  before insert or update of public_current_location_entity_id on public.npcs
  for each row execute function public.validate_same_campaign_entity_ref('location', 'public_current_location_entity_id');
create trigger npcs_validate_gm_current_location
  before insert or update of gm_current_location_entity_id on public.npcs
  for each row execute function public.validate_same_campaign_entity_ref('location', 'gm_current_location_entity_id');
create trigger npcs_validate_public_home_location
  before insert or update of public_home_location_entity_id on public.npcs
  for each row execute function public.validate_same_campaign_entity_ref('location', 'public_home_location_entity_id');
create trigger npcs_validate_gm_home_location
  before insert or update of gm_home_location_entity_id on public.npcs
  for each row execute function public.validate_same_campaign_entity_ref('location', 'gm_home_location_entity_id');
create trigger npcs_validate_reports_to
  before insert or update of reports_to_entity_id on public.npcs
  for each row execute function public.validate_same_campaign_entity_ref('*', 'reports_to_entity_id');
create trigger parties_validate_home_location
  before insert or update of home_location_entity_id on public.parties
  for each row execute function public.validate_same_campaign_entity_ref('location', 'home_location_entity_id');
create trigger parties_validate_current_location
  before insert or update of current_location_entity_id on public.parties
  for each row execute function public.validate_same_campaign_entity_ref('location', 'current_location_entity_id');
create trigger factions_validate_parent
  before insert or update of parent_faction_entity_id on public.factions
  for each row execute function public.validate_same_campaign_entity_ref('faction', 'parent_faction_entity_id');
create trigger factions_validate_headquarters
  before insert or update of headquarters_location_entity_id on public.factions
  for each row execute function public.validate_same_campaign_entity_ref('location', 'headquarters_location_entity_id');
create trigger factions_validate_territory
  before insert or update of territory_location_entity_id on public.factions
  for each row execute function public.validate_same_campaign_entity_ref('location', 'territory_location_entity_id');
create trigger factions_validate_leader
  before insert or update of leader_entity_id on public.factions
  for each row execute function public.validate_same_campaign_entity_ref('*', 'leader_entity_id');
create trigger locations_validate_parent
  before insert or update of parent_location_entity_id on public.locations
  for each row execute function public.validate_same_campaign_entity_ref('location', 'parent_location_entity_id');
create trigger locations_validate_controlling_faction
  before insert or update of controlling_faction_entity_id on public.locations
  for each row execute function public.validate_same_campaign_entity_ref('faction', 'controlling_faction_entity_id');
create trigger locations_validate_owner_or_steward
  before insert or update of owner_or_steward_entity_id on public.locations
  for each row execute function public.validate_same_campaign_entity_ref('*', 'owner_or_steward_entity_id');
create trigger locations_validate_ruler_or_authority
  before insert or update of ruler_or_authority_entity_id on public.locations
  for each row execute function public.validate_same_campaign_entity_ref('*', 'ruler_or_authority_entity_id');
create trigger encounters_validate_session
  before insert or update of related_session_entity_id on public.encounters
  for each row execute function public.validate_same_campaign_entity_ref('session', 'related_session_entity_id');
create trigger timeline_events_validate_session
  before insert or update of related_session_entity_id on public.timeline_events
  for each row execute function public.validate_same_campaign_entity_ref('session', 'related_session_entity_id');

create or replace function public.validate_campaign_entity_ref_by_campaign()
returns trigger
language plpgsql
as $$
declare
  v_expected_type text := tg_argv[0];
  v_column_name text := tg_argv[1];
  v_ref_id uuid;
begin
  execute format('select ($1).%I', v_column_name) using new into v_ref_id;
  if v_ref_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = v_ref_id
      and ce.campaign_id = new.campaign_id
      and ce.deleted_at is null
      and (v_expected_type = '*' or et.key = v_expected_type)
  ) then
    raise exception 'Invalid entity reference for %.%', tg_table_name, v_column_name;
  end if;

  return new;
end;
$$;

create trigger character_class_progressions_validate_character
  before insert or update of campaign_id, character_entity_id on public.character_class_progressions
  for each row execute function public.validate_campaign_entity_ref_by_campaign('character', 'character_entity_id');
create trigger character_hooks_validate_character
  before insert or update of campaign_id, character_entity_id on public.character_hooks
  for each row execute function public.validate_campaign_entity_ref_by_campaign('character', 'character_entity_id');
create trigger character_hooks_validate_promoted_storyline
  before insert or update of campaign_id, promoted_storyline_entity_id on public.character_hooks
  for each row execute function public.validate_campaign_entity_ref_by_campaign('storyline', 'promoted_storyline_entity_id');
create trigger encounter_statblocks_validate_encounter
  before insert or update of campaign_id, encounter_entity_id on public.encounter_statblocks
  for each row execute function public.validate_campaign_entity_ref_by_campaign('encounter', 'encounter_entity_id');
create trigger encounter_statblocks_validate_linked_npc
  before insert or update of campaign_id, linked_npc_entity_id on public.encounter_statblocks
  for each row execute function public.validate_campaign_entity_ref_by_campaign('npc', 'linked_npc_entity_id');

create or replace function public.validate_entity_pair_ref()
returns trigger
language plpgsql
as $$
declare
  v_parent_column text := tg_argv[0];
  v_parent_type text := tg_argv[1];
  v_ref_column text := tg_argv[2];
  v_ref_type text := tg_argv[3];
  v_parent_id uuid;
  v_ref_id uuid;
  v_campaign_id uuid;
begin
  execute format('select ($1).%I', v_parent_column) using new into v_parent_id;
  execute format('select ($1).%I', v_ref_column) using new into v_ref_id;

  select ce.campaign_id into v_campaign_id
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  where ce.id = v_parent_id
    and ce.deleted_at is null
    and et.key = v_parent_type;

  if v_campaign_id is null then
    raise exception 'Invalid parent entity reference for %.%', tg_table_name, v_parent_column;
  end if;

  if not exists (
    select 1
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = v_ref_id
      and ce.campaign_id = v_campaign_id
      and ce.deleted_at is null
      and et.key = v_ref_type
  ) then
    raise exception 'Invalid child entity reference for %.%', tg_table_name, v_ref_column;
  end if;

  return new;
end;
$$;

create trigger party_members_validate_entities
  before insert or update of party_entity_id, character_entity_id on public.party_members
  for each row execute function public.validate_entity_pair_ref('party_entity_id', 'party', 'character_entity_id', 'character');

create or replace function public.validate_campaign_option_ref()
returns trigger
language plpgsql
as $$
declare
  v_campaign_id uuid;
  v_group_key text := tg_argv[0];
  v_column_name text := tg_argv[1];
  v_option_id uuid;
begin
  execute format('select ($1).%I', v_column_name) using new into v_option_id;
  if v_option_id is null then
    return new;
  end if;

  select ce.campaign_id into v_campaign_id
  from public.campaign_entities ce
  where ce.id = new.entity_id;

  perform public.require_campaign_option(v_campaign_id, v_group_key, v_option_id, true, true);
  return new;
end;
$$;

create trigger storylines_validate_priority
  before insert or update of priority_option_id on public.storylines
  for each row execute function public.validate_campaign_option_ref('storyline_priority', 'priority_option_id');
create trigger storylines_validate_category
  before insert or update of storyline_category_option_id on public.storylines
  for each row execute function public.validate_campaign_option_ref('storyline_category', 'storyline_category_option_id');
create trigger encounters_validate_difficulty
  before insert or update of difficulty_option_id on public.encounters
  for each row execute function public.validate_campaign_option_ref('encounter_difficulty', 'difficulty_option_id');
create trigger npcs_validate_role_option
  before insert or update of role_option_id on public.npcs
  for each row execute function public.validate_campaign_option_ref('npc_role', 'role_option_id');
create trigger npcs_validate_disposition_option
  before insert or update of party_disposition_option_id on public.npcs
  for each row execute function public.validate_campaign_option_ref('party_disposition', 'party_disposition_option_id');
create trigger locations_validate_type_option
  before insert or update of location_type_option_id on public.locations
  for each row execute function public.validate_campaign_option_ref('location_type', 'location_type_option_id');
create trigger locations_validate_disposition_option
  before insert or update of party_disposition_option_id on public.locations
  for each row execute function public.validate_campaign_option_ref('location_party_disposition', 'party_disposition_option_id');
create trigger locations_validate_terrain_option
  before insert or update of terrain_option_id on public.locations
  for each row execute function public.validate_campaign_option_ref('location_terrain', 'terrain_option_id');
create trigger locations_validate_danger_option
  before insert or update of danger_level_option_id on public.locations
  for each row execute function public.validate_campaign_option_ref('location_danger_level', 'danger_level_option_id');
create trigger locations_validate_accessibility_option
  before insert or update of accessibility_option_id on public.locations
  for each row execute function public.validate_campaign_option_ref('location_accessibility', 'accessibility_option_id');
create trigger factions_validate_type_option
  before insert or update of faction_type_option_id on public.factions
  for each row execute function public.validate_campaign_option_ref('faction_type', 'faction_type_option_id');
create trigger factions_validate_scope_option
  before insert or update of scope_option_id on public.factions
  for each row execute function public.validate_campaign_option_ref('faction_scope', 'scope_option_id');
create trigger factions_validate_disposition_option
  before insert or update of party_disposition_option_id on public.factions
  for each row execute function public.validate_campaign_option_ref('party_disposition', 'party_disposition_option_id');

create or replace function public.validate_campaign_option_ref_by_campaign()
returns trigger
language plpgsql
as $$
declare
  v_group_key text := tg_argv[0];
  v_column_name text := tg_argv[1];
  v_option_id uuid;
begin
  execute format('select ($1).%I', v_column_name) using new into v_option_id;
  if v_option_id is null then
    return new;
  end if;

  perform public.require_campaign_option(new.campaign_id, v_group_key, v_option_id, true, true);
  return new;
end;
$$;

create trigger character_hooks_validate_category_option
  before insert or update of category_option_id on public.character_hooks
  for each row execute function public.validate_campaign_option_ref_by_campaign('hook_category', 'category_option_id');

create or replace function public.validate_campaign_palette_ref()
returns trigger
language plpgsql
as $$
declare
  v_column_name text := tg_argv[0];
  v_color_id uuid;
  v_campaign_id uuid;
begin
  execute format('select ($1).%I', v_column_name) using new into v_color_id;
  if v_color_id is null then
    return new;
  end if;

  select ce.campaign_id into v_campaign_id
  from public.campaign_entities ce
  where ce.id = new.entity_id;

  perform public.require_campaign_palette_color(v_campaign_id, v_color_id, false, true);
  return new;
end;
$$;

create or replace function public.validate_campaign_symbol_ref()
returns trigger
language plpgsql
as $$
declare
  v_column_name text := tg_argv[0];
  v_symbol_id uuid;
  v_campaign_id uuid;
begin
  execute format('select ($1).%I', v_column_name) using new into v_symbol_id;
  if v_symbol_id is null then
    return new;
  end if;

  select ce.campaign_id into v_campaign_id
  from public.campaign_entities ce
  where ce.id = new.entity_id;

  perform public.require_campaign_symbol(v_campaign_id, v_symbol_id, false, true);
  return new;
end;
$$;

create trigger storylines_validate_palette
  before insert or update of palette_color_id on public.storylines
  for each row execute function public.validate_campaign_palette_ref('palette_color_id');
create trigger storylines_validate_symbol
  before insert or update of symbol_id on public.storylines
  for each row execute function public.validate_campaign_symbol_ref('symbol_id');
create trigger parties_validate_palette
  before insert or update of palette_color_id on public.parties
  for each row execute function public.validate_campaign_palette_ref('palette_color_id');
create trigger parties_validate_symbol
  before insert or update of symbol_id on public.parties
  for each row execute function public.validate_campaign_symbol_ref('symbol_id');
create trigger factions_validate_palette
  before insert or update of palette_color_id on public.factions
  for each row execute function public.validate_campaign_palette_ref('palette_color_id');
create trigger factions_validate_symbol
  before insert or update of symbol_id on public.factions
  for each row execute function public.validate_campaign_symbol_ref('symbol_id');
create trigger locations_validate_palette
  before insert or update of palette_color_id on public.locations
  for each row execute function public.validate_campaign_palette_ref('palette_color_id');
create trigger locations_validate_symbol
  before insert or update of symbol_id on public.locations
  for each row execute function public.validate_campaign_symbol_ref('symbol_id');
create trigger encounters_validate_palette
  before insert or update of palette_color_id on public.encounters
  for each row execute function public.validate_campaign_palette_ref('palette_color_id');
create trigger timeline_events_validate_palette
  before insert or update of palette_color_id on public.timeline_events
  for each row execute function public.validate_campaign_palette_ref('palette_color_id');
create trigger timeline_events_validate_symbol
  before insert or update of symbol_id on public.timeline_events
  for each row execute function public.validate_campaign_symbol_ref('symbol_id');

create or replace function public.validate_encounter_statblock_value()
returns trigger
language plpgsql
as $$
declare
  v_value_type text;
begin
  if not exists (
    select 1
    from public.encounter_statblocks es
    where es.id = new.encounter_statblock_id
      and es.campaign_id = new.campaign_id
      and es.deleted_at is null
  ) then
    raise exception 'Encounter statblock must belong to the same campaign';
  end if;

  select cqsf.value_type into v_value_type
  from public.campaign_quick_stat_fields cqsf
  join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
  where cqsf.id = new.field_id
    and cqsf.campaign_id = new.campaign_id
    and cqsf.is_active
    and cqst.campaign_id = new.campaign_id
    and cqst.template_kind = 'npc_statblock'
    and cqst.is_active;

  if v_value_type is null then
    raise exception 'Encounter statblock field must belong to the same campaign';
  end if;

  if v_value_type = 'number' and new.value_text is not null then
    raise exception 'Number encounter statblock fields must not store text values';
  end if;

  if v_value_type = 'text' and new.value_number is not null then
    raise exception 'Text encounter statblock fields must not store number values';
  end if;

  return new;
end;
$$;

create trigger encounter_statblock_values_validate
  before insert or update of campaign_id, encounter_statblock_id, field_id, value_number, value_text
  on public.encounter_statblock_values
  for each row execute function public.validate_encounter_statblock_value();

create or replace function public.validate_encounter_statblock_instance()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.encounter_statblocks es
    where es.id = new.encounter_statblock_id
      and es.campaign_id = new.campaign_id
      and es.deleted_at is null
  ) then
    raise exception 'Encounter statblock must belong to the same campaign';
  end if;

  return new;
end;
$$;

create trigger encounter_statblock_instances_validate
  before insert or update of campaign_id, encounter_statblock_id
  on public.encounter_statblock_instances
  for each row execute function public.validate_encounter_statblock_instance();

insert into public.entity_section_definitions (
  entity_type_id,
  section_key,
  label,
  default_visibility,
  default_edit_policy,
  default_content_mode,
  sort_order
)
select et.id, v.section_key, v.label, v.default_visibility, v.default_edit_policy, 'document', v.sort_order
from public.entity_types et
cross join lateral (
  values
    ('details', 'Details', 'shared', 'gm_edit', 10),
    ('gm_details', 'GM Details', 'gm_only', 'gm_edit', 20)
) as v(section_key, label, default_visibility, default_edit_policy, sort_order)
where et.key = 'storyline'
on conflict (entity_type_id, section_key) do update
  set label = excluded.label,
      default_visibility = excluded.default_visibility,
      default_edit_policy = excluded.default_edit_policy,
      sort_order = excluded.sort_order,
      is_active = true;

update public.entity_section_definitions esd
set is_active = false
from public.entity_types et
where et.id = esd.entity_type_id
  and (
    (et.key in ('character', 'npc', 'faction', 'location') and esd.section_key in ('player_summary', 'player_observations'))
    or (et.key = 'party' and esd.section_key in ('description', 'party_notes'))
    or (et.key = 'session' and esd.section_key = 'summary')
    or (et.key = 'timeline_event' and esd.section_key = 'description')
  );

insert into public.entity_section_definitions (
  entity_type_id,
  section_key,
  label,
  default_visibility,
  default_edit_policy,
  default_content_mode,
  sort_order
)
select et.id, v.section_key, v.label, v.default_visibility, v.default_edit_policy, 'document', v.sort_order
from public.entity_types et
join lateral (
  values
    ('character', 'details', 'Details', 'shared', 'gm_edit', 10),
    ('character', 'backstory', 'Backstory', 'character_owner_gm', 'owner_edit', 20),
    ('character', 'gm_notes', 'GM Notes', 'gm_only', 'gm_edit', 30),
    ('character', 'journal', 'Journal', 'private', 'owner_edit', 40),
    ('npc', 'details', 'Details', 'shared', 'gm_edit', 10),
    ('npc', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 20),
    ('party', 'details', 'Details', 'shared', 'gm_edit', 10),
    ('party', 'gm_notes', 'GM Notes', 'gm_only', 'gm_edit', 20),
    ('faction', 'details', 'Details', 'shared', 'gm_edit', 10),
    ('faction', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 20),
    ('location', 'details', 'Details', 'shared', 'gm_edit', 10),
    ('location', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 20),
    ('session', 'session_notes', 'Session Notes', 'shared', 'gm_edit', 10),
    ('session', 'gm_prep', 'GM Prep', 'gm_only', 'gm_edit', 20),
    ('session', 'gm_private_notes', 'GM Private Notes', 'gm_only', 'gm_edit', 30),
    ('encounter', 'gm_prep', 'GM Prep', 'gm_only', 'gm_edit', 10),
    ('encounter', 'outcomes', 'Outcomes', 'gm_only', 'gm_edit', 20),
    ('timeline_event', 'details', 'Details', 'shared', 'gm_edit', 10),
    ('timeline_event', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 20)
) as v(entity_type_key, section_key, label, default_visibility, default_edit_policy, sort_order)
on v.entity_type_key = et.key
on conflict (entity_type_id, section_key) do update
  set label = excluded.label,
      default_visibility = excluded.default_visibility,
      default_edit_policy = excluded.default_edit_policy,
      default_content_mode = excluded.default_content_mode,
      sort_order = excluded.sort_order,
      is_active = true;

update public.entity_types
set is_active = false,
    sort_order = case key when 'quest' then 600 when 'plot_arc' then 610 else sort_order end
where key in ('quest', 'plot_arc');

delete from public.campaign_entity_type_settings cets
using public.entity_types et
where cets.entity_type_id = et.id
  and et.key in ('quest', 'plot_arc');

insert into public.campaign_entity_type_settings (
  campaign_id,
  entity_type_id,
  default_visibility,
  is_enabled,
  created_by,
  updated_by
)
select c.id, et.id, et.default_visibility, true, c.created_by, c.updated_by
from public.campaigns c
join public.entity_types et on et.key = 'storyline'
on conflict (campaign_id, entity_type_id) do update
  set default_visibility = excluded.default_visibility,
      is_enabled = true,
      updated_by = excluded.updated_by;

update public.status_definitions sd
set is_active = false
from public.entity_types et
where sd.subject_key = 'entity'
  and sd.entity_type_id = et.id
  and et.key in ('quest', 'plot_arc');

drop view if exists public.campaign_entity_summaries;
drop function if exists public.get_campaign_entity_summaries(uuid);
drop function if exists public.get_entity_detail(uuid);
drop function if exists public.create_campaign_entity(uuid, text, jsonb);
drop function if exists public.get_entity_option_definitions(uuid, text, text);
drop function if exists public.require_entity_option(uuid, uuid, text, uuid, boolean);

drop index if exists public.encounters_plot_arc_idx;

alter table public.locations
  drop constraint if exists locations_location_type_option_id_fkey,
  add constraint locations_location_type_option_id_fkey
    foreign key (location_type_option_id) references public.campaign_options(id) on delete restrict;

alter table public.encounters
  drop constraint if exists encounters_encounter_type_option_id_fkey,
  drop column if exists related_plot_arc_entity_id,
  add constraint encounters_encounter_type_option_id_fkey
    foreign key (encounter_type_option_id) references public.campaign_options(id) on delete restrict;

alter table public.timeline_events
  drop constraint if exists timeline_events_event_type_option_id_fkey,
  add constraint timeline_events_event_type_option_id_fkey
    foreign key (event_type_option_id) references public.campaign_options(id) on delete restrict;

drop table if exists public.quests cascade;
drop table if exists public.plot_arcs cascade;
drop table if exists public.entity_option_definitions cascade;

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
  related_storyline_entity_id uuid,
  related_storyline_label text,
  controlling_user_display_label text,
  npc_apparent_status_label text,
  location_type_label text,
  storyline_type text,
  storyline_priority_label text,
  storyline_category_label text,
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
    ce.id,
    et.key,
    ce.list_caption,
    ce.default_visibility,
    sd.key,
    sd.label,
    ma.id,
    ma.alt_text,
    thumb.storage_bucket,
    thumb.storage_path,
    thumb.width,
    thumb.height,
    grid.storage_bucket,
    grid.storage_path,
    grid.width,
    grid.height,
    ma.is_decorative,
    ce.relevant_date,
    ce.sort_key,
    case when public.can_view_campaign_entity(ce.parent_entity_id) then ce.parent_entity_id else null end,
    public.entity_ref_label(ce.parent_entity_id),
    case when public.can_view_campaign_entity(ce.related_session_entity_id) then ce.related_session_entity_id else null end,
    public.entity_ref_label(ce.related_session_entity_id),
    case when public.can_view_campaign_entity(e.related_storyline_entity_id) then e.related_storyline_entity_id else null end,
    public.entity_ref_label(e.related_storyline_entity_id),
    case
      when public.can_view_entity_visibility(ce.campaign_id, 'character_owner_gm', public.current_user_id(), ce.id)
        then coalesce(cm.display_name_override, up.display_name)
      else null
    end,
    npc_apparent.label,
    location_type.label,
    st.storyline_type,
    storyline_priority.label,
    storyline_category.label,
    st.is_major,
    encounter_type.label,
    te.date_expression,
    timeline_type.label,
    ce.updated_at,
    ce.archived_at,
    ce.deleted_at
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  left join public.status_definitions sd on sd.id = ce.status_id
  left join public.characters ch on ch.entity_id = ce.id
  left join public.campaign_memberships cm on cm.campaign_id = ce.campaign_id and cm.user_id = ch.controlling_user_id and cm.status = 'active'
  left join public.user_profiles up on up.user_id = ch.controlling_user_id
  left join public.npcs n on n.entity_id = ce.id
  left join public.status_definitions npc_apparent on npc_apparent.id = n.apparent_status_id
  left join public.locations l on l.entity_id = ce.id
  left join public.campaign_options location_type on location_type.id = l.location_type_option_id
  left join public.storylines st on st.entity_id = ce.id
  left join public.campaign_options storyline_priority on storyline_priority.id = st.priority_option_id
  left join public.campaign_options storyline_category on storyline_category.id = st.storyline_category_option_id
  left join public.encounters e on e.entity_id = ce.id
  left join public.campaign_options encounter_type on encounter_type.id = e.encounter_type_option_id
  left join public.timeline_events te on te.entity_id = ce.id
  left join public.campaign_options timeline_type on timeline_type.id = te.event_type_option_id
  left join public.media_assets ma on ma.id = ce.primary_image_asset_id and ma.status = 'ready' and ma.deleted_at is null
  left join public.media_asset_variants thumb on thumb.media_asset_id = ma.id and thumb.version_key = ma.current_version_key and thumb.variant = 'thumb_160'
  left join public.media_asset_variants grid on grid.media_asset_id = ma.id and grid.version_key = ma.current_version_key and grid.variant = 'grid_480'
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
  related_storyline_entity_id uuid,
  related_storyline_label text,
  controlling_user_id uuid,
  controlling_user_display_label text,
  location_type_label text,
  storyline_type text,
  storyline_priority_label text,
  storyline_category_label text,
  is_major boolean,
  encounter_type_label text,
  timeline_date_expression text,
  timeline_event_type_label text,
  npc_apparent_status_label text,
  npc_real_status_label text,
  typed_data jsonb,
  sections jsonb
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    ce.campaign_id,
    ce.id,
    et.key,
    et.label,
    ce.list_caption,
    ce.default_visibility,
    sd.key,
    sd.label,
    ce.relevant_date,
    ce.sort_key,
    ce.archived_at,
    ce.updated_at,
    case when public.can_view_campaign_entity(ce.parent_entity_id) then ce.parent_entity_id else null end,
    public.entity_ref_label(ce.parent_entity_id),
    case when public.can_view_campaign_entity(ce.related_session_entity_id) then ce.related_session_entity_id else null end,
    public.entity_ref_label(ce.related_session_entity_id),
    case when public.can_view_campaign_entity(e.related_storyline_entity_id) then e.related_storyline_entity_id else null end,
    public.entity_ref_label(e.related_storyline_entity_id),
    ch.controlling_user_id,
    coalesce(cm.display_name_override, up.display_name),
    location_type.label,
    st.storyline_type,
    storyline_priority.label,
    storyline_category.label,
    st.is_major,
    encounter_type.label,
    te.date_expression,
    timeline_type.label,
    npc_apparent.label,
    case when public.can_view_gm_content(ce.campaign_id) then npc_real.label else null end,
    case et.key
      when 'character' then jsonb_build_object(
        'species_ancestry_text', ch.species_ancestry_text,
        'pronouns', ch.pronouns,
        'public_summary', ch.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then ch.gm_summary else null end,
        'character_sheet_url', ch.character_sheet_url
      )
      when 'npc' then jsonb_build_object(
        'faction', case
          when public.can_view_campaign_entity(n.faction_entity_id)
            then jsonb_build_object('id', n.faction_entity_id, 'label', public.entity_ref_label(n.faction_entity_id))
          else null
        end,
        'role_option_id', n.role_option_id,
        'role_label', coalesce(
          (select co.label from public.campaign_options co where co.id = n.role_option_id),
          n.role_label
        ),
        'speech_text', case when public.can_view_gm_content(ce.campaign_id) then n.speech_text else null end,
        'party_disposition_option_id', n.party_disposition_option_id,
        'party_disposition_label', (select co.label from public.campaign_options co where co.id = n.party_disposition_option_id),
        'relationship_to_party_text', n.relationship_to_party_text,
        'public_summary', n.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then n.gm_summary else null end,
        'public_current_location', case
          when public.can_view_campaign_entity(n.public_current_location_entity_id)
            then jsonb_build_object('id', n.public_current_location_entity_id, 'label', public.entity_ref_label(n.public_current_location_entity_id))
          else null
        end,
        'gm_current_location', case
          when public.can_view_gm_content(ce.campaign_id) and public.can_view_campaign_entity(n.gm_current_location_entity_id)
            then jsonb_build_object('id', n.gm_current_location_entity_id, 'label', public.entity_ref_label(n.gm_current_location_entity_id))
          else null
        end,
        'public_home_location', case
          when public.can_view_campaign_entity(n.public_home_location_entity_id)
            then jsonb_build_object('id', n.public_home_location_entity_id, 'label', public.entity_ref_label(n.public_home_location_entity_id))
          else null
        end,
        'gm_home_location', case
          when public.can_view_gm_content(ce.campaign_id) and public.can_view_campaign_entity(n.gm_home_location_entity_id)
            then jsonb_build_object('id', n.gm_home_location_entity_id, 'label', public.entity_ref_label(n.gm_home_location_entity_id))
          else null
        end,
        'reports_to', case
          when public.can_view_campaign_entity(n.reports_to_entity_id)
            then jsonb_build_object('id', n.reports_to_entity_id, 'label', public.entity_ref_label(n.reports_to_entity_id))
          else null
        end,
        'has_stat_block', case when public.can_view_gm_content(ce.campaign_id) then (n.stat_block_jsonb is not null) else null end
      )
      when 'party' then jsonb_build_object(
        'public_summary', p.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then p.gm_summary else null end,
        'home_location', case
          when public.can_view_campaign_entity(p.home_location_entity_id)
            then jsonb_build_object('id', p.home_location_entity_id, 'label', public.entity_ref_label(p.home_location_entity_id))
          else null
        end,
        'current_location', case
          when public.can_view_campaign_entity(p.current_location_entity_id)
            then jsonb_build_object('id', p.current_location_entity_id, 'label', public.entity_ref_label(p.current_location_entity_id))
          else null
        end,
        'palette_color', case
          when p.palette_color_id is not null then (
            select jsonb_build_object('id', cpc.id, 'key', cpc.key, 'label', cpc.label, 'color_token', cpc.color_token, 'text_color_token', cpc.text_color_token)
            from public.campaign_palette_colors cpc
            where cpc.id = p.palette_color_id
          )
          else null
        end,
        'symbol', case
          when p.symbol_id is not null then (
            select jsonb_build_object('id', cs.id, 'key', cs.key, 'label', cs.label, 'icon_key', cs.icon_key)
            from public.campaign_symbols cs
            where cs.id = p.symbol_id
          )
          else null
        end
      )
      when 'faction' then jsonb_build_object(
        'parent_faction', case
          when public.can_view_campaign_entity(f.parent_faction_entity_id)
            then jsonb_build_object('id', f.parent_faction_entity_id, 'label', public.entity_ref_label(f.parent_faction_entity_id))
          else null
        end,
        'faction_type_option_id', f.faction_type_option_id,
        'faction_type_label', (select co.label from public.campaign_options co where co.id = f.faction_type_option_id),
        'scope_option_id', case when f.scope_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id) then f.scope_option_id else null end,
        'scope_label', case
          when f.scope_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id)
            then (select co.label from public.campaign_options co where co.id = f.scope_option_id)
          else null
        end,
        'numbers_text', case when f.numbers_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id) then f.numbers_text else null end,
        'public_summary', f.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then f.gm_summary else null end,
        'party_disposition_option_id', f.party_disposition_option_id,
        'party_disposition_label', (select co.label from public.campaign_options co where co.id = f.party_disposition_option_id),
        'relationship_to_party_text', f.relationship_to_party_text,
        'headquarters_location', case
          when (f.headquarters_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id))
            and public.can_view_campaign_entity(f.headquarters_location_entity_id)
            then jsonb_build_object('id', f.headquarters_location_entity_id, 'label', public.entity_ref_label(f.headquarters_location_entity_id))
          else null
        end,
        'territory_location', case
          when (f.territory_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id))
            and public.can_view_campaign_entity(f.territory_location_entity_id)
            then jsonb_build_object('id', f.territory_location_entity_id, 'label', public.entity_ref_label(f.territory_location_entity_id))
          else null
        end,
        'leader', case
          when (f.leader_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id))
            and public.can_view_campaign_entity(f.leader_entity_id)
            then jsonb_build_object('id', f.leader_entity_id, 'label', public.entity_ref_label(f.leader_entity_id))
          else null
        end,
        'public_goal_text', f.public_goal_text,
        'gm_true_goal_text', case when public.can_view_gm_content(ce.campaign_id) then f.gm_true_goal_text else null end,
        'palette_color', case
          when f.palette_color_id is not null then (
            select jsonb_build_object('id', cpc.id, 'key', cpc.key, 'label', cpc.label, 'color_token', cpc.color_token, 'text_color_token', cpc.text_color_token)
            from public.campaign_palette_colors cpc
            where cpc.id = f.palette_color_id
          )
          else null
        end,
        'symbol', case
          when f.symbol_id is not null then (
            select jsonb_build_object('id', cs.id, 'key', cs.key, 'label', cs.label, 'icon_key', cs.icon_key)
            from public.campaign_symbols cs
            where cs.id = f.symbol_id
          )
          else null
        end
      )
      when 'location' then jsonb_build_object(
        'public_summary', l.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then l.gm_summary else null end,
        'known_to_party', l.known_to_party,
        'visited_by_party', l.visited_by_party,
        'relationship_to_party_text', l.relationship_to_party_text,
        'party_disposition_option_id', l.party_disposition_option_id,
        'party_disposition_label', (select co.label from public.campaign_options co where co.id = l.party_disposition_option_id),
        'controlling_faction', case
          when (l.controlling_faction_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id))
            and public.can_view_campaign_entity(l.controlling_faction_entity_id)
            then jsonb_build_object('id', l.controlling_faction_entity_id, 'label', public.entity_ref_label(l.controlling_faction_entity_id))
          else null
        end,
        'owner_or_steward', case
          when (l.owner_or_steward_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id))
            and public.can_view_campaign_entity(l.owner_or_steward_entity_id)
            then jsonb_build_object('id', l.owner_or_steward_entity_id, 'label', public.entity_ref_label(l.owner_or_steward_entity_id))
          else null
        end,
        'ruler_or_authority', case
          when (l.ruler_or_authority_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id))
            and public.can_view_campaign_entity(l.ruler_or_authority_entity_id)
            then jsonb_build_object('id', l.ruler_or_authority_entity_id, 'label', public.entity_ref_label(l.ruler_or_authority_entity_id))
          else null
        end,
        'population_text', case when l.population_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id) then l.population_text else null end,
        'size_or_scale_text', case when l.size_or_scale_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id) then l.size_or_scale_text else null end,
        'terrain_option_id', l.terrain_option_id,
        'terrain_label', (select co.label from public.campaign_options co where co.id = l.terrain_option_id),
        'danger_level_option_id', case when l.danger_level_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id) then l.danger_level_option_id else null end,
        'danger_level_label', case
          when l.danger_level_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id)
            then (select co.label from public.campaign_options co where co.id = l.danger_level_option_id)
          else null
        end,
        'accessibility_option_id', case when l.accessibility_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id) then l.accessibility_option_id else null end,
        'accessibility_label', case
          when l.accessibility_visibility = 'shared' or public.can_view_gm_content(ce.campaign_id)
            then (select co.label from public.campaign_options co where co.id = l.accessibility_option_id)
          else null
        end,
        'palette_color', case
          when l.palette_color_id is not null then (
            select jsonb_build_object('id', cpc.id, 'key', cpc.key, 'label', cpc.label, 'color_token', cpc.color_token, 'text_color_token', cpc.text_color_token)
            from public.campaign_palette_colors cpc
            where cpc.id = l.palette_color_id
          )
          else null
        end,
        'symbol', case
          when l.symbol_id is not null then (
            select jsonb_build_object('id', cs.id, 'key', cs.key, 'label', cs.label, 'icon_key', cs.icon_key)
            from public.campaign_symbols cs
            where cs.id = l.symbol_id
          )
          else null
        end
      )
      when 'storyline' then jsonb_build_object(
        'public_summary', st.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then st.gm_summary else null end,
        'primary_location', case
          when public.can_view_campaign_entity(st.primary_location_entity_id)
            then jsonb_build_object('id', st.primary_location_entity_id, 'label', public.entity_ref_label(st.primary_location_entity_id))
          else null
        end,
        'reward_text', st.reward_text,
        'completed_at', st.completed_at,
        'sort_order', st.sort_order,
        'palette_color', case
          when st.palette_color_id is not null then (
            select jsonb_build_object('id', cpc.id, 'key', cpc.key, 'label', cpc.label, 'color_token', cpc.color_token, 'text_color_token', cpc.text_color_token)
            from public.campaign_palette_colors cpc
            where cpc.id = st.palette_color_id
          )
          else null
        end,
        'symbol', case
          when st.symbol_id is not null then (
            select jsonb_build_object('id', cs.id, 'key', cs.key, 'label', cs.label, 'icon_key', cs.icon_key)
            from public.campaign_symbols cs
            where cs.id = st.symbol_id
          )
          else null
        end
      )
      when 'session' then jsonb_build_object(
        'title', s.title,
        'session_number_sort', s.session_number_sort,
        'session_number_label', s.session_number_label,
        'start_time', s.start_time,
        'end_time', s.end_time,
        'public_summary', s.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then s.gm_summary else null end,
        'next_session_teaser', s.next_session_teaser
      )
      when 'encounter' then jsonb_build_object(
        'title', e.title,
        'difficulty_option_id', e.difficulty_option_id,
        'difficulty_label', (select co.label from public.campaign_options co where co.id = e.difficulty_option_id),
        'sort_order', e.sort_order,
        'palette_color', case
          when e.palette_color_id is not null then (
            select jsonb_build_object('id', cpc.id, 'key', cpc.key, 'label', cpc.label, 'color_token', cpc.color_token, 'text_color_token', cpc.text_color_token)
            from public.campaign_palette_colors cpc
            where cpc.id = e.palette_color_id
          )
          else null
        end,
        'image_asset_id', e.image_asset_id
      )
      when 'timeline_event' then jsonb_build_object(
        'public_summary', te.public_summary,
        'gm_summary', case when public.can_view_gm_content(ce.campaign_id) then te.gm_summary else null end,
        'primary_location', case
          when public.can_view_campaign_entity(te.primary_location_entity_id)
            then jsonb_build_object('id', te.primary_location_entity_id, 'label', public.entity_ref_label(te.primary_location_entity_id))
          else null
        end,
        'palette_color', case
          when te.palette_color_id is not null then (
            select jsonb_build_object('id', cpc.id, 'key', cpc.key, 'label', cpc.label, 'color_token', cpc.color_token, 'text_color_token', cpc.text_color_token)
            from public.campaign_palette_colors cpc
            where cpc.id = te.palette_color_id
          )
          else null
        end,
        'symbol', case
          when te.symbol_id is not null then (
            select jsonb_build_object('id', cs.id, 'key', cs.key, 'label', cs.label, 'icon_key', cs.icon_key)
            from public.campaign_symbols cs
            where cs.id = te.symbol_id
          )
          else null
        end
      )
      else '{}'::jsonb
    end,
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
        and public.can_view_entity_visibility(ce.campaign_id, es.visibility, es.created_by, es.entity_id)
    ), '[]'::jsonb)
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  left join public.status_definitions sd on sd.id = ce.status_id
  left join public.characters ch on ch.entity_id = ce.id
  left join public.parties p on p.entity_id = ce.id
  left join public.factions f on f.entity_id = ce.id
  left join public.campaign_memberships cm on cm.campaign_id = ce.campaign_id and cm.user_id = ch.controlling_user_id and cm.status = 'active'
  left join public.user_profiles up on up.user_id = ch.controlling_user_id
  left join public.npcs n on n.entity_id = ce.id
  left join public.status_definitions npc_apparent on npc_apparent.id = n.apparent_status_id
  left join public.status_definitions npc_real on npc_real.id = n.real_status_id
  left join public.locations l on l.entity_id = ce.id
  left join public.sessions s on s.entity_id = ce.id
  left join public.campaign_options location_type on location_type.id = l.location_type_option_id
  left join public.storylines st on st.entity_id = ce.id
  left join public.campaign_options storyline_priority on storyline_priority.id = st.priority_option_id
  left join public.campaign_options storyline_category on storyline_category.id = st.storyline_category_option_id
  left join public.encounters e on e.entity_id = ce.id
  left join public.campaign_options encounter_type on encounter_type.id = e.encounter_type_option_id
  left join public.timeline_events te on te.entity_id = ce.id
  left join public.campaign_options timeline_type on timeline_type.id = te.event_type_option_id
  where ce.id = p_entity_id
    and public.can_view_campaign_entity(ce.id);
$$;

create or replace function public.promote_character_hook_to_storyline(
  p_hook_id uuid,
  p_visibility text default null
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
  v_hook public.character_hooks%rowtype;
  v_character public.characters%rowtype;
  v_requested_visibility text := nullif(p_visibility, '');
  v_storyline_visibility text;
  v_status_id uuid;
  v_created_entity_id uuid;
  v_default_input jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ch.*
    into v_hook
  from public.character_hooks ch
  where ch.id = p_hook_id
    and ch.deleted_at is null;

  if v_hook.id is null then
    raise exception 'Character hook not found';
  end if;

  if not public.can_view_campaign_entity(v_hook.character_entity_id) then
    raise exception 'Character hook is not accessible';
  end if;

  select ch.*
    into v_character
  from public.characters ch
  where ch.entity_id = v_hook.character_entity_id;

  if v_character.entity_id is null then
    raise exception 'Character hook is not attached to a Character';
  end if;

  if not (
    public.can_view_gm_content(v_hook.campaign_id)
    or v_character.controlling_user_id = v_user_id
  ) then
    raise exception 'Only campaign owners, GMs, or the Character controller can promote this hook';
  end if;

  if v_hook.promoted_storyline_entity_id is not null and exists (
    select 1
    from public.campaign_entities ce
    where ce.id = v_hook.promoted_storyline_entity_id
      and ce.deleted_at is null
  ) then
    return query
    select s.campaign_id, s.entity_id, s.entity_type_key, s.list_caption, s.default_visibility, s.status_key, s.status_label, s.updated_at
    from public.get_campaign_entity_summaries(v_hook.campaign_id) s
    where s.entity_id = v_hook.promoted_storyline_entity_id;
    return;
  end if;

  if v_requested_visibility is not null and v_requested_visibility not in ('shared', 'gm_only', 'private') then
    raise exception 'Invalid Storyline visibility';
  end if;

  if v_hook.visibility = 'gm_only' then
    v_storyline_visibility := 'gm_only';
  elsif v_hook.visibility = 'character_owner_gm' then
    if v_character.controlling_user_id = v_user_id then
      v_storyline_visibility := 'private';
    else
      v_storyline_visibility := 'gm_only';
    end if;
  else
    if public.can_view_gm_content(v_hook.campaign_id) then
      v_storyline_visibility := coalesce(v_requested_visibility, 'shared');
    else
      v_storyline_visibility := coalesce(v_requested_visibility, 'shared');
      if v_storyline_visibility = 'gm_only' then
        raise exception 'Only campaign owners and GMs can create GM-only Storylines';
      end if;
    end if;
  end if;

  select sd.id
    into v_status_id
  from public.status_definitions sd
  join public.entity_types et on et.id = sd.entity_type_id
  where et.key = 'storyline'
    and sd.subject_key = 'entity'
    and sd.campaign_id is null
    and sd.key = 'open'
    and sd.is_active;

  if v_status_id is null then
    raise exception 'Storyline open status is not available';
  end if;

  v_default_input := jsonb_build_object(
    'title', v_hook.description_text,
    'status_id', v_status_id,
    'storyline_type', 'quest',
    'default_visibility', v_storyline_visibility
  );

  select created.entity_id
    into v_created_entity_id
  from public.create_campaign_entity(v_hook.campaign_id, 'storyline', v_default_input) created;

  update public.character_hooks
  set promoted_storyline_entity_id = v_created_entity_id,
      updated_by = v_user_id
  where id = v_hook.id;

  return query
  select s.campaign_id, s.entity_id, s.entity_type_key, s.list_caption, s.default_visibility, s.status_key, s.status_label, s.updated_at
  from public.get_campaign_entity_summaries(v_hook.campaign_id) s
  where s.entity_id = v_created_entity_id;
end;
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
  v_core_edit_policy text := 'gm_edit';
  v_list_caption text;
  v_status_id uuid;
  v_entity_id uuid;
  v_parent_entity_id uuid;
  v_related_session_entity_id uuid;
  v_related_storyline_entity_id uuid;
  v_option_id uuid;
  v_category_option_id uuid;
  v_real_status_id uuid;
  v_controlling_user_id uuid;
  v_date date;
  v_sort_key text;
  v_storyline_type text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_entity_type_key = 'storyline' then
    if not public.is_campaign_member(p_campaign_id) then
      raise exception 'Only campaign members can create Storylines';
    end if;
  elsif not public.can_mutate_campaign_config(p_campaign_id) then
    raise exception 'Only campaign owners and GMs can create this entity type';
  end if;

  select et.id, cets.default_visibility
    into v_entity_type_id, v_default_visibility
  from public.entity_types et
  join public.campaign_entity_type_settings cets on cets.entity_type_id = et.id and cets.campaign_id = p_campaign_id
  where et.key = p_entity_type_key
    and et.is_active
    and cets.is_enabled;

  if v_entity_type_id is null then
    raise exception 'Entity type is disabled or unknown';
  end if;

  v_requested_visibility := nullif(p_input ->> 'default_visibility', '');
  if v_requested_visibility is not null and v_requested_visibility not in ('shared', 'gm_only', 'private', 'character_owner_gm') then
    raise exception 'Invalid entity visibility';
  end if;
  v_visibility := coalesce(v_requested_visibility, v_default_visibility);

  if v_visibility = 'gm_only' and not public.can_view_gm_content(p_campaign_id) then
    raise exception 'Only campaign owners and GMs can create GM-only records';
  end if;

  if p_entity_type_key = 'encounter' and v_requested_visibility is null then
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
    v_core_edit_policy := 'owner_edit';
    if not exists (select 1 from public.campaign_memberships cm where cm.campaign_id = p_campaign_id and cm.user_id = v_controlling_user_id and cm.status = 'active') then
      raise exception 'Character controller must be an active campaign member';
    end if;
  elsif p_entity_type_key = 'npc' then
    v_real_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'real_status_id', '')::uuid, true);
    v_status_id := coalesce(public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'apparent_status_id', '')::uuid, false), v_real_status_id);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'faction', nullif(p_input ->> 'faction_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'party' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, false);
  elsif p_entity_type_key = 'faction' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, false);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'faction', nullif(p_input ->> 'parent_faction_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'location' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, false);
    v_option_id := public.require_campaign_option(p_campaign_id, 'location_type', nullif(p_input ->> 'location_type_option_id', '')::uuid, true);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'location', nullif(p_input ->> 'parent_location_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'storyline' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_option_id := public.require_campaign_option(p_campaign_id, 'storyline_priority', nullif(p_input ->> 'priority_option_id', '')::uuid, false);
    v_category_option_id := public.require_campaign_option(p_campaign_id, 'storyline_category', nullif(p_input ->> 'storyline_category_option_id', '')::uuid, false);
    v_parent_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'storyline', nullif(p_input ->> 'parent_storyline_entity_id', '')::uuid, false);
    v_storyline_type := coalesce(nullif(p_input ->> 'storyline_type', ''), 'quest');
    if v_storyline_type not in ('quest', 'thread') then
      raise exception 'Invalid Storyline type';
    end if;
    if public.can_view_gm_content(p_campaign_id) then
      v_core_edit_policy := 'gm_edit';
    elsif v_visibility = 'shared' then
      v_core_edit_policy := 'player_edit';
    else
      v_visibility := 'private';
      v_core_edit_policy := 'owner_edit';
    end if;
  elsif p_entity_type_key = 'session' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_date := (p_input ->> 'session_date')::date;
    if v_date is null then raise exception 'Session date is required'; end if;
  elsif p_entity_type_key = 'encounter' then
    v_status_id := public.require_entity_status(p_campaign_id, v_entity_type_id, nullif(p_input ->> 'status_id', '')::uuid, true);
    v_option_id := public.require_campaign_option(p_campaign_id, 'encounter_type', nullif(p_input ->> 'encounter_type_option_id', '')::uuid, true);
    v_related_session_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'session', nullif(p_input ->> 'related_session_entity_id', '')::uuid, false);
    v_related_storyline_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'storyline', nullif(p_input ->> 'related_storyline_entity_id', '')::uuid, false);
  elsif p_entity_type_key = 'timeline_event' then
    v_option_id := public.require_campaign_option(p_campaign_id, 'timeline_event_type', nullif(p_input ->> 'event_type_option_id', '')::uuid, true);
    v_related_session_entity_id := public.require_campaign_entity_ref(p_campaign_id, 'session', nullif(p_input ->> 'related_session_entity_id', '')::uuid, false);
    v_sort_key := nullif(p_input ->> 'sort_key', '');
    if nullif(p_input ->> 'date_expression', '') is null then raise exception 'Timeline date expression is required'; end if;
  else
    raise exception 'Unsupported entity type';
  end if;

  insert into public.campaign_entities (
    campaign_id, entity_type_id, list_caption, default_visibility, core_edit_policy,
    status_id, relevant_date, sort_key, parent_entity_id, related_session_entity_id,
    created_by, updated_by
  )
  values (
    p_campaign_id, v_entity_type_id, v_list_caption, v_visibility, v_core_edit_policy,
    v_status_id, v_date, v_sort_key, v_parent_entity_id, v_related_session_entity_id,
    v_user_id, v_user_id
  )
  returning id into v_entity_id;

  if p_entity_type_key = 'character' then
    insert into public.characters (entity_id, name, status_id, controlling_user_id, species_ancestry_text, pronouns, public_summary, gm_summary, character_sheet_url, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_status_id, v_controlling_user_id, nullif(p_input ->> 'species_ancestry_text', ''), nullif(p_input ->> 'pronouns', ''), nullif(p_input ->> 'public_summary', ''), nullif(p_input ->> 'gm_summary', ''), nullif(p_input ->> 'character_sheet_url', ''), v_user_id, v_user_id);
  elsif p_entity_type_key = 'npc' then
    insert into public.npcs (entity_id, name, apparent_status_id, real_status_id, faction_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_status_id, v_real_status_id, v_parent_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'party' then
    insert into public.parties (entity_id, name, status_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_status_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'faction' then
    insert into public.factions (entity_id, name, status_id, parent_faction_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_status_id, v_parent_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'location' then
    insert into public.locations (entity_id, name, location_type_option_id, status_id, parent_location_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'name'), v_option_id, v_status_id, v_parent_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'storyline' then
    insert into public.storylines (entity_id, title, storyline_type, status_id, priority_option_id, is_major, parent_storyline_entity_id, storyline_category_option_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), v_storyline_type, v_status_id, v_option_id, coalesce((p_input ->> 'is_major')::boolean, false), v_parent_entity_id, v_category_option_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'session' then
    insert into public.sessions (entity_id, title, session_date, status_id, created_by, updated_by)
    values (v_entity_id, nullif(trim(p_input ->> 'title'), ''), v_date, v_status_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'encounter' then
    insert into public.encounters (entity_id, title, encounter_type_option_id, status_id, related_session_entity_id, related_storyline_entity_id, created_by, updated_by)
    values (v_entity_id, nullif(trim(p_input ->> 'title'), ''), v_option_id, v_status_id, v_related_session_entity_id, v_related_storyline_entity_id, v_user_id, v_user_id);
  elsif p_entity_type_key = 'timeline_event' then
    insert into public.timeline_events (entity_id, title, date_expression, sort_key, event_type_option_id, related_session_entity_id, created_by, updated_by)
    values (v_entity_id, trim(p_input ->> 'title'), trim(p_input ->> 'date_expression'), v_sort_key, v_option_id, v_related_session_entity_id, v_user_id, v_user_id);
  end if;

  insert into public.entity_sections (entity_id, section_definition_id, section_key, label, visibility, edit_policy, content_mode, created_by, updated_by)
  select v_entity_id, esd.id, esd.section_key, esd.label, esd.default_visibility, esd.default_edit_policy, esd.default_content_mode, v_user_id, v_user_id
  from public.entity_section_definitions esd
  where esd.entity_type_id = v_entity_type_id
    and esd.is_active
  order by esd.sort_order;

  return query
  select s.campaign_id, s.entity_id, s.entity_type_key, s.list_caption, s.default_visibility, s.status_key, s.status_label, s.updated_at
  from public.get_campaign_entity_summaries(p_campaign_id) s
  where s.entity_id = v_entity_id;
end;
$$;

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
    cets.is_enabled
      and (
        public.can_mutate_campaign_config(p_campaign_id)
        or (et.key = 'storyline' and public.is_campaign_member(p_campaign_id))
      ) as can_create
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

alter table public.character_class_progressions enable row level security;
alter table public.storylines enable row level security;
alter table public.character_hooks enable row level security;
alter table public.party_members enable row level security;
alter table public.encounter_statblocks enable row level security;
alter table public.encounter_statblock_values enable row level security;
alter table public.encounter_statblock_instances enable row level security;

create policy "Owners and GMs can read raw storyline rows"
  on public.storylines for select to authenticated
  using (exists (select 1 from public.campaign_entities ce where ce.id = storylines.entity_id and public.can_view_gm_content(ce.campaign_id)));
create policy "Owners and GMs can read raw character hooks"
  on public.character_hooks for select to authenticated
  using (deleted_at is null and public.can_view_gm_content(campaign_id));
create policy "Character classes follow character visibility"
  on public.character_class_progressions for select to authenticated
  using (public.can_view_campaign_entity(character_entity_id));
create policy "Party members follow party visibility"
  on public.party_members for select to authenticated
  using (
    public.can_view_campaign_entity(party_entity_id)
    and public.can_view_campaign_entity(character_entity_id)
  );
create policy "Owners and GMs can read encounter statblocks"
  on public.encounter_statblocks for select to authenticated
  using (deleted_at is null and public.can_view_gm_content(campaign_id));
create policy "Owners and GMs can read encounter statblock values"
  on public.encounter_statblock_values for select to authenticated
  using (public.can_view_gm_content(campaign_id));
create policy "Owners and GMs can read encounter statblock instances"
  on public.encounter_statblock_instances for select to authenticated
  using (deleted_at is null and public.can_view_gm_content(campaign_id));

revoke all on all tables in schema public from anon, public;
grant select on all tables in schema public to authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

revoke execute on all functions in schema public from anon, public;
grant execute on all functions in schema public to authenticated, service_role;
