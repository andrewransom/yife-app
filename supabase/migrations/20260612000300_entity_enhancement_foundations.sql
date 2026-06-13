alter table public.campaigns
  add column vtt_url text,
  add column timezone text not null default 'UTC',
  add constraint campaigns_vtt_url_check check (
    vtt_url is null or vtt_url ~* '^https?://'
  ),
  add constraint campaigns_timezone_check check (length(trim(timezone)) > 0);

alter table public.campaign_entities
  add column core_edit_policy text not null default 'gm_edit',
  add constraint campaign_entities_core_edit_policy_check
    check (core_edit_policy in ('gm_edit', 'owner_edit', 'player_edit'));

alter table public.campaign_entities
  drop constraint campaign_entities_default_visibility_check,
  add constraint campaign_entities_default_visibility_check
    check (default_visibility in ('shared', 'gm_only', 'private', 'character_owner_gm'));

alter table public.campaign_entity_type_settings
  drop constraint campaign_entity_type_settings_default_visibility_check,
  add constraint campaign_entity_type_settings_default_visibility_check
    check (default_visibility in ('shared', 'gm_only', 'private', 'character_owner_gm'));

alter table public.entity_section_definitions
  drop constraint entity_section_definitions_default_visibility_check,
  add constraint entity_section_definitions_default_visibility_check
    check (default_visibility in ('shared', 'gm_only', 'private', 'character_owner_gm'));

alter table public.entity_sections
  drop constraint entity_sections_visibility_check,
  add constraint entity_sections_visibility_check
    check (visibility in ('shared', 'gm_only', 'private', 'character_owner_gm'));

alter table public.entity_types
  drop constraint entity_types_default_visibility_check,
  add constraint entity_types_default_visibility_check
    check (default_visibility in ('shared', 'gm_only', 'private', 'character_owner_gm'));

alter table public.status_definitions
  drop constraint status_definitions_subject_check,
  drop constraint status_definitions_entity_type_check,
  add constraint status_definitions_subject_check check (
    subject_key in ('campaign', 'entity_resource', 'entity', 'character_hook')
  ),
  add constraint status_definitions_entity_type_check check (
    (subject_key = 'entity' and entity_type_id is not null)
    or (subject_key <> 'entity' and entity_type_id is null)
  );

create table public.app_symbol_icon_keys (
  key text primary key,
  created_at timestamptz not null default now()
);

insert into public.app_symbol_icon_keys (key)
values
  ('book-open'),
  ('castle'),
  ('circle'),
  ('flag'),
  ('gem'),
  ('landmark'),
  ('map-pin'),
  ('scroll-text'),
  ('shield'),
  ('skull'),
  ('sparkles'),
  ('swords'),
  ('user-round'),
  ('users-round'),
  ('waypoints')
on conflict do nothing;

create table public.option_preset_packs (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  description text,
  sort_order integer not null,
  is_system boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.option_preset_groups (
  id uuid primary key default gen_random_uuid(),
  preset_pack_id uuid not null references public.option_preset_packs(id) on delete cascade,
  group_key text not null,
  label text not null,
  description text,
  sort_order integer not null,
  is_active boolean not null default true,
  constraint option_preset_groups_key_unique unique (preset_pack_id, group_key)
);

create table public.palette_preset_colors (
  id uuid primary key default gen_random_uuid(),
  preset_pack_id uuid not null references public.option_preset_packs(id) on delete cascade,
  key text not null,
  label text not null,
  color_token text not null,
  text_color_token text,
  sort_order integer not null,
  is_active boolean not null default true,
  constraint palette_preset_colors_key_unique unique (preset_pack_id, key)
);

create table public.symbol_preset_symbols (
  id uuid primary key default gen_random_uuid(),
  preset_pack_id uuid not null references public.option_preset_packs(id) on delete cascade,
  key text not null,
  label text not null,
  icon_key text not null references public.app_symbol_icon_keys(key) on delete restrict,
  sort_order integer not null,
  is_active boolean not null default true,
  constraint symbol_preset_symbols_key_unique unique (preset_pack_id, key)
);

create table public.option_preset_items (
  id uuid primary key default gen_random_uuid(),
  preset_group_id uuid not null references public.option_preset_groups(id) on delete cascade,
  key text not null,
  label text not null,
  description text,
  default_palette_color_key text,
  default_symbol_key text,
  sort_order integer not null,
  is_active boolean not null default true,
  constraint option_preset_items_key_unique unique (preset_group_id, key)
);

create table public.campaign_palette_colors (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  key text not null,
  label text not null,
  color_token text not null,
  text_color_token text,
  sort_order integer not null,
  is_active boolean not null default true,
  source_preset_pack_id uuid references public.option_preset_packs(id) on delete set null,
  source_preset_color_id uuid references public.palette_preset_colors(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_palette_colors_key_unique unique (campaign_id, key)
);

create table public.campaign_symbols (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  key text not null,
  label text not null,
  icon_key text not null references public.app_symbol_icon_keys(key) on delete restrict,
  sort_order integer not null,
  is_active boolean not null default true,
  source_preset_pack_id uuid references public.option_preset_packs(id) on delete set null,
  source_preset_symbol_id uuid references public.symbol_preset_symbols(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_symbols_key_unique unique (campaign_id, key)
);

create table public.campaign_option_groups (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  key text not null,
  label text not null,
  description text,
  sort_order integer not null,
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_option_groups_key_unique unique (campaign_id, key)
);

create table public.campaign_options (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  group_id uuid not null references public.campaign_option_groups(id) on delete cascade,
  key text not null,
  label text not null,
  description text,
  default_palette_color_id uuid references public.campaign_palette_colors(id) on delete set null,
  default_symbol_id uuid references public.campaign_symbols(id) on delete set null,
  sort_order integer not null,
  is_active boolean not null default true,
  source_preset_pack_id uuid references public.option_preset_packs(id) on delete set null,
  source_preset_group_id uuid references public.option_preset_groups(id) on delete set null,
  source_preset_item_id uuid references public.option_preset_items(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_options_key_unique unique (group_id, key)
);

create table public.quick_stat_preset_templates (
  id uuid primary key default gen_random_uuid(),
  preset_pack_id uuid not null references public.option_preset_packs(id) on delete cascade,
  key text not null,
  template_kind text not null check (template_kind in ('character', 'npc_statblock')),
  label text not null,
  sort_order integer not null,
  is_active boolean not null default true,
  constraint quick_stat_preset_templates_key_unique unique (preset_pack_id, key),
  constraint quick_stat_preset_templates_kind_unique unique (preset_pack_id, template_kind)
);

create table public.quick_stat_preset_fields (
  id uuid primary key default gen_random_uuid(),
  preset_template_id uuid not null references public.quick_stat_preset_templates(id) on delete cascade,
  key text not null,
  label text not null,
  compact_label text not null,
  value_type text not null check (value_type in ('number', 'text')),
  default_visibility text not null check (default_visibility in ('shared', 'gm_only', 'private', 'character_owner_gm')),
  min_value numeric,
  max_value numeric,
  sort_order integer not null,
  is_active boolean not null default true,
  constraint quick_stat_preset_fields_key_unique unique (preset_template_id, key),
  constraint quick_stat_preset_fields_range_check check (
    min_value is null or max_value is null or min_value <= max_value
  )
);

create table public.campaign_quick_stat_templates (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  template_kind text not null check (template_kind in ('character', 'npc_statblock')),
  label text not null,
  is_active boolean not null default true,
  source_preset_template_id uuid references public.quick_stat_preset_templates(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index campaign_quick_stat_templates_active_kind_unique
  on public.campaign_quick_stat_templates (campaign_id, template_kind)
  where is_active;

create table public.campaign_quick_stat_fields (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  template_id uuid not null references public.campaign_quick_stat_templates(id) on delete cascade,
  key text not null,
  label text not null,
  compact_label text not null,
  value_type text not null check (value_type in ('number', 'text')),
  default_visibility text not null check (default_visibility in ('shared', 'gm_only', 'private', 'character_owner_gm')),
  min_value numeric,
  max_value numeric,
  sort_order integer not null,
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_quick_stat_fields_key_unique unique (template_id, key),
  constraint campaign_quick_stat_fields_range_check check (
    min_value is null or max_value is null or min_value <= max_value
  )
);

create table public.entity_quick_stat_values (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  field_id uuid not null references public.campaign_quick_stat_fields(id) on delete restrict,
  value_number numeric,
  value_text text,
  visibility text not null check (visibility in ('shared', 'gm_only', 'private', 'character_owner_gm')),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entity_quick_stat_values_unique unique (entity_id, field_id),
  constraint entity_quick_stat_values_one_value_check check (
    (value_number is not null and value_text is null)
    or (value_number is null and value_text is not null)
    or (value_number is null and value_text is null)
  )
);

create index campaign_options_group_idx on public.campaign_options (group_id, sort_order);
create index entity_quick_stat_values_entity_idx on public.entity_quick_stat_values (entity_id);

create trigger option_preset_packs_set_updated_at
  before update on public.option_preset_packs
  for each row execute function public.set_updated_at();
create trigger campaign_palette_colors_set_updated_at
  before update on public.campaign_palette_colors
  for each row execute function public.set_updated_at();
create trigger campaign_symbols_set_updated_at
  before update on public.campaign_symbols
  for each row execute function public.set_updated_at();
create trigger campaign_option_groups_set_updated_at
  before update on public.campaign_option_groups
  for each row execute function public.set_updated_at();
create trigger campaign_options_set_updated_at
  before update on public.campaign_options
  for each row execute function public.set_updated_at();
create trigger campaign_quick_stat_templates_set_updated_at
  before update on public.campaign_quick_stat_templates
  for each row execute function public.set_updated_at();
create trigger campaign_quick_stat_fields_set_updated_at
  before update on public.campaign_quick_stat_fields
  for each row execute function public.set_updated_at();
create trigger entity_quick_stat_values_set_updated_at
  before update on public.entity_quick_stat_values
  for each row execute function public.set_updated_at();

create or replace function public.validate_campaign_option_owner()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.campaign_option_groups cog
    where cog.id = new.group_id
      and cog.campaign_id = new.campaign_id
  ) then
    raise exception 'Campaign option group must belong to the same campaign';
  end if;

  if new.default_palette_color_id is not null and not exists (
    select 1
    from public.campaign_palette_colors cpc
    where cpc.id = new.default_palette_color_id
      and cpc.campaign_id = new.campaign_id
  ) then
    raise exception 'Campaign option palette color must belong to the same campaign';
  end if;

  if new.default_symbol_id is not null and not exists (
    select 1
    from public.campaign_symbols cs
    where cs.id = new.default_symbol_id
      and cs.campaign_id = new.campaign_id
  ) then
    raise exception 'Campaign option symbol must belong to the same campaign';
  end if;

  return new;
end;
$$;

create trigger campaign_options_validate_owner
  before insert or update of campaign_id, group_id, default_palette_color_id, default_symbol_id
  on public.campaign_options
  for each row execute function public.validate_campaign_option_owner();

create or replace function public.validate_quick_stat_field_owner()
returns trigger
language plpgsql
as $$
declare
  v_template_kind text;
begin
  select cqst.template_kind
  into v_template_kind
  from public.campaign_quick_stat_templates cqst
  where cqst.id = new.template_id
    and cqst.campaign_id = new.campaign_id;

  if v_template_kind is null then
    raise exception 'Quick stat field template must belong to the same campaign';
  end if;

  if v_template_kind = 'npc_statblock' and new.default_visibility <> 'gm_only' then
    raise exception 'NPC statblock fields must use gm_only visibility';
  end if;

  return new;
end;
$$;

create trigger campaign_quick_stat_fields_validate_owner
  before insert or update of campaign_id, template_id, default_visibility
  on public.campaign_quick_stat_fields
  for each row execute function public.validate_quick_stat_field_owner();

create or replace function public.validate_entity_quick_stat_value()
returns trigger
language plpgsql
as $$
declare
  v_value_type text;
  v_entity_type_key text;
begin
  select cqsf.value_type into v_value_type
  from public.campaign_quick_stat_fields cqsf
  where cqsf.id = new.field_id
    and cqsf.campaign_id = new.campaign_id;

  if v_value_type is null then
    raise exception 'Quick stat field must belong to the same campaign';
  end if;

  select et.key
  into v_entity_type_key
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  where ce.id = new.entity_id
    and ce.campaign_id = new.campaign_id;

  if v_entity_type_key is null then
    raise exception 'Quick stat entity must belong to the same campaign';
  end if;

  if v_entity_type_key = 'npc' and new.visibility <> 'gm_only' then
    raise exception 'NPC quick stat values must use gm_only visibility';
  end if;

  if v_value_type = 'number' and new.value_text is not null then
    raise exception 'Number quick stat fields must not store text values';
  end if;

  if v_value_type = 'text' and new.value_number is not null then
    raise exception 'Text quick stat fields must not store number values';
  end if;

  return new;
end;
$$;

create trigger entity_quick_stat_values_validate
  before insert or update of campaign_id, entity_id, field_id, value_number, value_text, visibility
  on public.entity_quick_stat_values
  for each row execute function public.validate_entity_quick_stat_value();

insert into public.option_preset_packs (key, label, description, sort_order)
values ('dnd_fantasy', 'D&D Fantasy', 'D&D-friendly fantasy defaults for a new campaign.', 10)
on conflict (key) do update
  set label = excluded.label,
      description = excluded.description,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.palette_preset_colors (preset_pack_id, key, label, color_token, text_color_token, sort_order)
select opp.id, v.key, v.label, v.color_token, v.text_color_token, v.sort_order
from public.option_preset_packs opp
cross join lateral (
  values
    ('red', 'Red', 'red', 'white', 10),
    ('amber', 'Amber', 'amber', 'black', 20),
    ('green', 'Green', 'green', 'white', 30),
    ('blue', 'Blue', 'blue', 'white', 40),
    ('violet', 'Violet', 'violet', 'white', 50),
    ('slate', 'Slate', 'slate', 'white', 60)
) as v(key, label, color_token, text_color_token, sort_order)
where opp.key = 'dnd_fantasy'
on conflict (preset_pack_id, key) do update
  set label = excluded.label,
      color_token = excluded.color_token,
      text_color_token = excluded.text_color_token,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.symbol_preset_symbols (preset_pack_id, key, label, icon_key, sort_order)
select opp.id, v.key, v.label, v.icon_key, v.sort_order
from public.option_preset_packs opp
cross join lateral (
  values
    ('person', 'Person', 'user-round', 10),
    ('party', 'Party', 'users-round', 20),
    ('faction', 'Faction', 'shield', 30),
    ('location', 'Location', 'map-pin', 40),
    ('storyline', 'Storyline', 'scroll-text', 50),
    ('encounter', 'Encounter', 'swords', 60),
    ('mystery', 'Mystery', 'sparkles', 70)
) as v(key, label, icon_key, sort_order)
where opp.key = 'dnd_fantasy'
on conflict (preset_pack_id, key) do update
  set label = excluded.label,
      icon_key = excluded.icon_key,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.option_preset_groups (preset_pack_id, group_key, label, sort_order)
select opp.id, v.group_key, v.label, v.sort_order
from public.option_preset_packs opp
cross join lateral (
  values
    ('npc_role', 'NPC Role', 10),
    ('party_disposition', 'Party Disposition', 20),
    ('hook_category', 'Hook Category', 30),
    ('faction_type', 'Faction Type', 40),
    ('faction_scope', 'Faction Scope', 50),
    ('location_type', 'Location Type', 60),
    ('location_terrain', 'Location Terrain', 70),
    ('location_danger_level', 'Location Danger Level', 80),
    ('location_accessibility', 'Location Accessibility', 90),
    ('location_party_disposition', 'Location Party Disposition', 100),
    ('storyline_category', 'Storyline Category', 110),
    ('storyline_priority', 'Storyline Priority', 120),
    ('encounter_type', 'Encounter Type', 130),
    ('encounter_difficulty', 'Encounter Difficulty', 140),
    ('timeline_event_type', 'Timeline Event Type', 150)
) as v(group_key, label, sort_order)
where opp.key = 'dnd_fantasy'
on conflict (preset_pack_id, group_key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.option_preset_items (
  preset_group_id,
  key,
  label,
  default_palette_color_key,
  default_symbol_key,
  sort_order
)
select opg.id, v.key, v.label, v.default_palette_color_key, v.default_symbol_key, v.sort_order
from public.option_preset_packs opp
join public.option_preset_groups opg on opg.preset_pack_id = opp.id
cross join lateral (
  values
    ('npc_role', 'ally', 'Ally', 'green', 'person', 10),
    ('npc_role', 'contact', 'Contact', 'blue', 'person', 20),
    ('npc_role', 'rival', 'Rival', 'red', 'person', 30),
    ('npc_role', 'villain', 'Villain', 'violet', 'skull', 40),
    ('party_disposition', 'friendly', 'Friendly', 'green', null, 10),
    ('party_disposition', 'neutral', 'Neutral', 'slate', null, 20),
    ('party_disposition', 'hostile', 'Hostile', 'red', null, 30),
    ('hook_category', 'bond', 'Bond', 'blue', 'storyline', 10),
    ('hook_category', 'debt', 'Debt', 'amber', 'storyline', 20),
    ('hook_category', 'secret', 'Secret', 'violet', 'mystery', 30),
    ('faction_type', 'guild', 'Guild', 'blue', 'faction', 10),
    ('faction_type', 'noble_house', 'Noble House', 'violet', 'castle', 20),
    ('faction_type', 'cult', 'Cult', 'red', 'skull', 30),
    ('faction_scope', 'local', 'Local', 'green', null, 10),
    ('faction_scope', 'regional', 'Regional', 'blue', null, 20),
    ('faction_scope', 'global', 'Global', 'violet', null, 30),
    ('location_type', 'world', 'World', 'blue', 'location', 10),
    ('location_type', 'continent', 'Continent', 'blue', 'location', 20),
    ('location_type', 'country', 'Country', 'green', 'location', 30),
    ('location_type', 'region', 'Region', 'green', 'location', 40),
    ('location_type', 'town', 'Town', 'amber', 'location', 50),
    ('location_type', 'city', 'City', 'amber', 'location', 60),
    ('location_type', 'wilderness_area', 'Wilderness Area', 'green', 'location', 70),
    ('location_type', 'district', 'District', 'slate', 'location', 80),
    ('location_type', 'landmark', 'Landmark', 'violet', 'landmark', 90),
    ('location_type', 'building', 'Building', 'slate', 'location', 100),
    ('location_type', 'room', 'Room', 'slate', 'location', 110),
    ('location_type', 'dungeon', 'Dungeon', 'red', 'skull', 120),
    ('location_type', 'plane', 'Plane', 'violet', 'sparkles', 130),
    ('location_type', 'other', 'Other', 'slate', 'location', 140),
    ('location_terrain', 'urban', 'Urban', 'slate', null, 10),
    ('location_terrain', 'forest', 'Forest', 'green', null, 20),
    ('location_terrain', 'mountain', 'Mountain', 'slate', null, 30),
    ('location_terrain', 'underground', 'Underground', 'red', null, 40),
    ('location_danger_level', 'safe', 'Safe', 'green', null, 10),
    ('location_danger_level', 'risky', 'Risky', 'amber', null, 20),
    ('location_danger_level', 'deadly', 'Deadly', 'red', null, 30),
    ('location_accessibility', 'open', 'Open', 'green', null, 10),
    ('location_accessibility', 'restricted', 'Restricted', 'amber', null, 20),
    ('location_accessibility', 'hidden', 'Hidden', 'violet', null, 30),
    ('location_party_disposition', 'welcoming', 'Welcoming', 'green', null, 10),
    ('location_party_disposition', 'watchful', 'Watchful', 'amber', null, 20),
    ('location_party_disposition', 'dangerous', 'Dangerous', 'red', null, 30),
    ('storyline_category', 'main', 'Main', 'violet', 'storyline', 10),
    ('storyline_category', 'side', 'Side', 'blue', 'storyline', 20),
    ('storyline_category', 'personal', 'Personal', 'green', 'person', 30),
    ('storyline_priority', 'low', 'Low', 'slate', null, 10),
    ('storyline_priority', 'normal', 'Normal', 'blue', null, 20),
    ('storyline_priority', 'high', 'High', 'amber', null, 30),
    ('storyline_priority', 'urgent', 'Urgent', 'red', null, 40),
    ('encounter_type', 'roleplay', 'Roleplay', 'blue', 'encounter', 10),
    ('encounter_type', 'exploration', 'Exploration', 'green', 'encounter', 20),
    ('encounter_type', 'combat', 'Combat', 'red', 'encounter', 30),
    ('encounter_type', 'puzzle', 'Puzzle', 'violet', 'encounter', 40),
    ('encounter_type', 'travel', 'Travel', 'green', 'encounter', 50),
    ('encounter_type', 'mixed', 'Mixed', 'amber', 'encounter', 60),
    ('encounter_type', 'other', 'Other', 'slate', 'encounter', 70),
    ('encounter_difficulty', 'easy', 'Easy', 'green', null, 10),
    ('encounter_difficulty', 'medium', 'Medium', 'blue', null, 20),
    ('encounter_difficulty', 'hard', 'Hard', 'amber', null, 30),
    ('encounter_difficulty', 'deadly', 'Deadly', 'red', null, 40),
    ('timeline_event_type', 'world_history', 'World History', 'slate', 'book-open', 10),
    ('timeline_event_type', 'campaign_event', 'Campaign Event', 'blue', 'book-open', 20),
    ('timeline_event_type', 'session_event', 'Session Event', 'green', 'book-open', 30),
    ('timeline_event_type', 'character_event', 'Character Event', 'green', 'person', 40),
    ('timeline_event_type', 'faction_event', 'Faction Event', 'violet', 'faction', 50),
    ('timeline_event_type', 'location_event', 'Location Event', 'blue', 'location', 60),
    ('timeline_event_type', 'storyline_event', 'Storyline Event', 'amber', 'storyline', 70),
    ('timeline_event_type', 'omen_prophecy', 'Omen/Prophecy', 'violet', 'mystery', 80),
    ('timeline_event_type', 'other', 'Other', 'slate', 'book-open', 90)
) as v(group_key, key, label, default_palette_color_key, default_symbol_key, sort_order)
where opp.key = 'dnd_fantasy'
  and opg.group_key = v.group_key
on conflict (preset_group_id, key) do update
  set label = excluded.label,
      default_palette_color_key = excluded.default_palette_color_key,
      default_symbol_key = excluded.default_symbol_key,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.quick_stat_preset_templates (preset_pack_id, key, template_kind, label, sort_order)
select opp.id, v.key, v.template_kind, v.label, v.sort_order
from public.option_preset_packs opp
cross join lateral (
  values
    ('character_basic', 'character', 'Character Quick Stats', 10),
    ('npc_basic', 'npc_statblock', 'NPC/Encounter Statblock', 20)
) as v(key, template_kind, label, sort_order)
where opp.key = 'dnd_fantasy'
on conflict (preset_pack_id, key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.quick_stat_preset_fields (
  preset_template_id,
  key,
  label,
  compact_label,
  value_type,
  default_visibility,
  min_value,
  max_value,
  sort_order
)
select qst.id, v.key, v.label, v.compact_label, v.value_type, v.default_visibility, v.min_value, v.max_value, v.sort_order
from public.option_preset_packs opp
join public.quick_stat_preset_templates qst on qst.preset_pack_id = opp.id
cross join lateral (
  values
    ('character', 'level', 'Level', 'Lv', 'number', 'character_owner_gm', 1::numeric, null::numeric, 10),
    ('character', 'armor_class', 'Armor Class', 'AC', 'number', 'character_owner_gm', null::numeric, null::numeric, 20),
    ('character', 'hit_points', 'Hit Points', 'HP', 'text', 'character_owner_gm', null::numeric, null::numeric, 30),
    ('character', 'passive_perception', 'Passive Perception', 'PP', 'number', 'character_owner_gm', null::numeric, null::numeric, 40),
    ('npc_statblock', 'level_cr', 'Level / CR', 'Lv/CR', 'text', 'gm_only', null::numeric, null::numeric, 10),
    ('npc_statblock', 'max_hp', 'Max HP', 'Max HP', 'number', 'gm_only', null::numeric, null::numeric, 20),
    ('npc_statblock', 'current_hp', 'Current HP', 'HP', 'number', 'gm_only', null::numeric, null::numeric, 30),
    ('npc_statblock', 'armor_class', 'Armor Class', 'AC', 'number', 'gm_only', null::numeric, null::numeric, 40),
    ('npc_statblock', 'hit_bonus', 'Hit Bonus', 'Hit', 'text', 'gm_only', null::numeric, null::numeric, 50),
    ('npc_statblock', 'damage', 'Damage', 'Dmg', 'text', 'gm_only', null::numeric, null::numeric, 60),
    ('npc_statblock', 'damage_type', 'Damage Type', 'Type', 'text', 'gm_only', null::numeric, null::numeric, 70),
    ('npc_statblock', 'main_action', 'Main Action', 'Action', 'text', 'gm_only', null::numeric, null::numeric, 80),
    ('npc_statblock', 'action_summary', 'Action Summary', 'Summary', 'text', 'gm_only', null::numeric, null::numeric, 90)
) as v(template_kind, key, label, compact_label, value_type, default_visibility, min_value, max_value, sort_order)
where opp.key = 'dnd_fantasy'
  and qst.template_kind = v.template_kind
on conflict (preset_template_id, key) do update
  set label = excluded.label,
      compact_label = excluded.compact_label,
      value_type = excluded.value_type,
      default_visibility = excluded.default_visibility,
      min_value = excluded.min_value,
      max_value = excluded.max_value,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.entity_types (key, label, plural_label, icon_key, default_visibility, sort_order)
values ('storyline', 'Storyline', 'Storylines', 'scroll-text', 'shared', 60)
on conflict (key) do update
  set label = excluded.label,
      plural_label = excluded.plural_label,
      icon_key = excluded.icon_key,
      default_visibility = excluded.default_visibility,
      sort_order = excluded.sort_order,
      is_active = true;

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, v.key, v.label, v.sort_order, v.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('open', 'Open', 10, false),
    ('active', 'Active', 20, false),
    ('completed', 'Completed', 30, true),
    ('resolved', 'Resolved', 40, true),
    ('failed', 'Failed', 50, true),
    ('abandoned', 'Abandoned', 60, true)
) as v(key, label, sort_order, is_terminal)
where et.key = 'storyline'
on conflict (subject_key, entity_type_id, campaign_id, key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_terminal = excluded.is_terminal,
      is_active = true;

update public.status_definitions sd
set sort_order = v.sort_order,
    is_terminal = v.is_terminal,
    is_active = true
from public.entity_types et
join (
  values
    ('active', 10, false),
    ('retired', 20, true),
    ('dead', 30, true),
    ('missing', 40, false),
    ('inactive', 50, false)
) as v(key, sort_order, is_terminal) on true
where sd.entity_type_id = et.id
  and et.key = 'character'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.key = v.key;

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
values
  ('character_hook', null, 'unused', 'Unused', 10, false),
  ('character_hook', null, 'seeded', 'Seeded', 20, false),
  ('character_hook', null, 'active', 'Active', 30, false),
  ('character_hook', null, 'resolved', 'Resolved', 40, true),
  ('character_hook', null, 'retired', 'Retired', 50, true)
on conflict (subject_key, entity_type_id, campaign_id, key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_terminal = excluded.is_terminal,
      is_active = true;

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, v.key, v.label, v.sort_order, v.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('active', 'Active', 10, false),
    ('inactive', 'Inactive', 20, false),
    ('disbanded', 'Disbanded', 30, true),
    ('former', 'Former', 40, true),
    ('temporary', 'Temporary', 50, false)
) as v(key, label, sort_order, is_terminal)
where et.key = 'party'
on conflict (subject_key, entity_type_id, campaign_id, key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_terminal = excluded.is_terminal,
      is_active = true;

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, v.key, v.label, v.sort_order, v.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('active', 'Active', 10, false),
    ('inactive', 'Inactive', 20, false),
    ('collapsed', 'Collapsed', 30, true),
    ('unknown', 'Unknown', 40, false)
) as v(key, label, sort_order, is_terminal)
where et.key = 'faction'
on conflict (subject_key, entity_type_id, campaign_id, key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_terminal = excluded.is_terminal,
      is_active = true;

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, v.key, v.label, v.sort_order, v.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('active', 'Active', 10, false),
    ('ruined', 'Ruined', 20, true),
    ('abandoned', 'Abandoned', 30, true),
    ('destroyed', 'Destroyed', 40, true),
    ('unknown', 'Unknown', 50, false)
) as v(key, label, sort_order, is_terminal)
where et.key = 'location'
on conflict (subject_key, entity_type_id, campaign_id, key) do update
  set label = excluded.label,
      sort_order = excluded.sort_order,
      is_terminal = excluded.is_terminal,
      is_active = true;

create or replace function public.can_view_entity_visibility(
  p_campaign_id uuid,
  p_visibility text,
  p_created_by uuid,
  p_entity_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when p_visibility = 'shared' then public.is_campaign_member(p_campaign_id)
    when p_visibility = 'gm_only' then public.can_view_gm_content(p_campaign_id)
    when p_visibility = 'private' then p_created_by = public.current_user_id()
    when p_visibility = 'character_owner_gm' then
      public.can_view_gm_content(p_campaign_id)
      or exists (
        select 1
        from public.characters ch
        where ch.entity_id = p_entity_id
          and ch.controlling_user_id = public.current_user_id()
      )
    else false
  end
$$;

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
      and public.can_view_entity_visibility(
        ce.campaign_id,
        ce.default_visibility,
        ce.created_by,
        ce.id
      )
  )
$$;

create or replace function public.can_edit_entity_core(p_entity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = p_entity_id
      and ce.deleted_at is null
      and public.is_campaign_member(ce.campaign_id)
      and (
        public.can_view_gm_content(ce.campaign_id)
        or (
          ce.core_edit_policy = 'owner_edit'
          and et.key = 'character'
          and exists (
            select 1
            from public.characters ch
            where ch.entity_id = ce.id
              and ch.controlling_user_id = public.current_user_id()
          )
        )
        or (
          ce.core_edit_policy = 'owner_edit'
          and et.key <> 'character'
          and ce.created_by = public.current_user_id()
        )
        or (ce.core_edit_policy = 'player_edit' and public.can_view_campaign_entity(ce.id))
      )
  )
$$;

drop policy "Visible campaign entities can be read" on public.campaign_entities;
create policy "Visible campaign entities can be read"
  on public.campaign_entities for select
  to authenticated
  using (
    public.is_campaign_member(campaign_id)
    and deleted_at is null
    and public.can_view_entity_visibility(campaign_id, default_visibility, created_by, id)
  );

drop policy "Visible entity sections can be read" on public.entity_sections;
create policy "Visible entity sections can be read"
  on public.entity_sections for select to authenticated
  using (
    public.can_view_campaign_entity(entity_id)
    and exists (
      select 1
      from public.campaign_entities ce
      where ce.id = entity_sections.entity_id
        and public.can_view_entity_visibility(
          ce.campaign_id,
          entity_sections.visibility,
          entity_sections.created_by,
          entity_sections.entity_id
        )
    )
  );

create or replace function public.require_campaign_option(
  p_campaign_id uuid,
  p_group_key text,
  p_option_id uuid,
  p_required boolean default true,
  p_require_active boolean default true
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
    from public.campaign_options co
    join public.campaign_option_groups cog on cog.id = co.group_id
    where co.id = p_option_id
      and co.campaign_id = p_campaign_id
      and cog.campaign_id = p_campaign_id
      and cog.key = p_group_key
      and (not p_require_active or (co.is_active and cog.is_active))
  ) then
    raise exception 'Invalid campaign option';
  end if;

  return p_option_id;
end;
$$;

create or replace function public.require_campaign_palette_color(
  p_campaign_id uuid,
  p_palette_color_id uuid,
  p_required boolean default false,
  p_require_active boolean default true
)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_palette_color_id is null then
    if p_required then
      raise exception 'Palette color is required';
    end if;
    return null;
  end if;

  if not exists (
    select 1
    from public.campaign_palette_colors cpc
    where cpc.id = p_palette_color_id
      and cpc.campaign_id = p_campaign_id
      and (not p_require_active or cpc.is_active)
  ) then
    raise exception 'Invalid campaign palette color';
  end if;

  return p_palette_color_id;
end;
$$;

create or replace function public.require_campaign_symbol(
  p_campaign_id uuid,
  p_symbol_id uuid,
  p_required boolean default false,
  p_require_active boolean default true
)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_symbol_id is null then
    if p_required then
      raise exception 'Symbol is required';
    end if;
    return null;
  end if;

  if not exists (
    select 1
    from public.campaign_symbols cs
    where cs.id = p_symbol_id
      and cs.campaign_id = p_campaign_id
      and (not p_require_active or cs.is_active)
  ) then
    raise exception 'Invalid campaign symbol';
  end if;

  return p_symbol_id;
end;
$$;

create or replace function public.import_campaign_preset_pack(
  p_campaign_id uuid,
  p_preset_pack_key text default 'dnd_fantasy',
  p_group_keys text[] default null
)
returns table (
  palette_colors_imported integer,
  symbols_imported integer,
  option_groups_imported integer,
  options_imported integer,
  quick_stat_templates_imported integer,
  quick_stat_fields_imported integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_pack_id uuid;
  v_palette_count integer := 0;
  v_symbol_count integer := 0;
  v_group_count integer := 0;
  v_option_count integer := 0;
  v_template_count integer := 0;
  v_field_count integer := 0;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not public.can_mutate_campaign_config(p_campaign_id) then
    raise exception 'Only campaign owners and GMs can import campaign presets';
  end if;

  select id into v_pack_id
  from public.option_preset_packs
  where key = coalesce(nullif(p_preset_pack_key, ''), 'dnd_fantasy')
    and is_active;

  if v_pack_id is null then
    raise exception 'Preset pack is not active or unknown';
  end if;

  insert into public.campaign_palette_colors (
    campaign_id,
    key,
    label,
    color_token,
    text_color_token,
    sort_order,
    source_preset_pack_id,
    source_preset_color_id,
    created_by,
    updated_by
  )
  select p_campaign_id, ppc.key, ppc.label, ppc.color_token, ppc.text_color_token,
    ppc.sort_order, v_pack_id, ppc.id, v_user_id, v_user_id
  from public.palette_preset_colors ppc
  where ppc.preset_pack_id = v_pack_id
    and ppc.is_active
  on conflict (campaign_id, key) do nothing;
  get diagnostics v_palette_count = row_count;

  insert into public.campaign_symbols (
    campaign_id,
    key,
    label,
    icon_key,
    sort_order,
    source_preset_pack_id,
    source_preset_symbol_id,
    created_by,
    updated_by
  )
  select p_campaign_id, sps.key, sps.label, sps.icon_key, sps.sort_order,
    v_pack_id, sps.id, v_user_id, v_user_id
  from public.symbol_preset_symbols sps
  where sps.preset_pack_id = v_pack_id
    and sps.is_active
  on conflict (campaign_id, key) do nothing;
  get diagnostics v_symbol_count = row_count;

  insert into public.campaign_option_groups (
    campaign_id,
    key,
    label,
    description,
    sort_order,
    created_by,
    updated_by
  )
  select p_campaign_id, opg.group_key, opg.label, opg.description, opg.sort_order,
    v_user_id, v_user_id
  from public.option_preset_groups opg
  where opg.preset_pack_id = v_pack_id
    and opg.is_active
    and (p_group_keys is null or opg.group_key = any(p_group_keys))
  on conflict (campaign_id, key) do nothing;
  get diagnostics v_group_count = row_count;

  insert into public.campaign_options (
    campaign_id,
    group_id,
    key,
    label,
    description,
    default_palette_color_id,
    default_symbol_id,
    sort_order,
    source_preset_pack_id,
    source_preset_group_id,
    source_preset_item_id,
    created_by,
    updated_by
  )
  select
    p_campaign_id,
    cog.id,
    opi.key,
    opi.label,
    opi.description,
    cpc.id,
    cs.id,
    opi.sort_order,
    v_pack_id,
    opg.id,
    opi.id,
    v_user_id,
    v_user_id
  from public.option_preset_items opi
  join public.option_preset_groups opg on opg.id = opi.preset_group_id
  join public.campaign_option_groups cog
    on cog.campaign_id = p_campaign_id
   and cog.key = opg.group_key
  left join public.campaign_palette_colors cpc
    on cpc.campaign_id = p_campaign_id
   and cpc.key = opi.default_palette_color_key
  left join public.campaign_symbols cs
    on cs.campaign_id = p_campaign_id
   and cs.key = opi.default_symbol_key
  where opg.preset_pack_id = v_pack_id
    and opg.is_active
    and opi.is_active
    and (p_group_keys is null or opg.group_key = any(p_group_keys))
  on conflict (group_id, key) do nothing;
  get diagnostics v_option_count = row_count;

  insert into public.campaign_quick_stat_templates (
    campaign_id,
    template_kind,
    label,
    source_preset_template_id,
    created_by,
    updated_by
  )
  select p_campaign_id, qst.template_kind, qst.label, qst.id, v_user_id, v_user_id
  from public.quick_stat_preset_templates qst
  where qst.preset_pack_id = v_pack_id
    and qst.is_active
  on conflict do nothing;
  get diagnostics v_template_count = row_count;

  insert into public.campaign_quick_stat_fields (
    campaign_id,
    template_id,
    key,
    label,
    compact_label,
    value_type,
    default_visibility,
    min_value,
    max_value,
    sort_order,
    created_by,
    updated_by
  )
  select
    p_campaign_id,
    cqst.id,
    qsf.key,
    qsf.label,
    qsf.compact_label,
    qsf.value_type,
    qsf.default_visibility,
    qsf.min_value,
    qsf.max_value,
    qsf.sort_order,
    v_user_id,
    v_user_id
  from public.quick_stat_preset_fields qsf
  join public.quick_stat_preset_templates qst on qst.id = qsf.preset_template_id
  join public.campaign_quick_stat_templates cqst
    on cqst.campaign_id = p_campaign_id
   and cqst.source_preset_template_id = qst.id
  where qst.preset_pack_id = v_pack_id
    and qst.is_active
    and qsf.is_active
  on conflict (template_id, key) do nothing;
  get diagnostics v_field_count = row_count;

  return query
  select v_palette_count, v_symbol_count, v_group_count, v_option_count, v_template_count, v_field_count;
end;
$$;

drop function public.create_campaign(text, date, text, date, text);

create or replace function public.create_campaign(
  p_name text,
  p_start_date date,
  p_description text default null,
  p_end_date date default null,
  p_status_key text default 'planned',
  p_vtt_url text default null,
  p_timezone text default 'UTC',
  p_preset_pack_key text default 'dnd_fantasy'
)
returns table (
  campaign_id uuid,
  name text,
  description text,
  status_key text,
  status_label text,
  membership_id uuid,
  role_keys text[]
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_status_id uuid;
  v_campaign_id uuid;
  v_membership_id uuid;
  v_owner_role_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Campaign name is required';
  end if;

  if p_start_date is null then
    raise exception 'Campaign start date is required';
  end if;

  if p_end_date is not null and p_end_date < p_start_date then
    raise exception 'Campaign end date cannot be before start date';
  end if;

  if nullif(p_vtt_url, '') is not null and nullif(p_vtt_url, '') !~* '^https?://' then
    raise exception 'VTT URL must start with http:// or https://';
  end if;

  perform public.ensure_user_defaults();

  select sd.id into v_status_id
  from public.status_definitions sd
  where sd.subject_key = 'campaign'
    and sd.entity_type_id is null
    and sd.campaign_id is null
    and sd.key = coalesce(nullif(p_status_key, ''), 'planned')
    and sd.is_active;

  if v_status_id is null then
    raise exception 'Invalid campaign status';
  end if;

  select rd.id into v_owner_role_id
  from public.role_definitions rd
  where rd.key = 'owner'
    and rd.is_active;

  if v_owner_role_id is null then
    raise exception 'Owner role is not seeded';
  end if;

  insert into public.campaigns (
    owner_user_id,
    name,
    description,
    status_id,
    vtt_url,
    timezone,
    start_date,
    end_date,
    created_by,
    updated_by
  )
  values (
    v_user_id,
    trim(p_name),
    nullif(p_description, ''),
    v_status_id,
    nullif(p_vtt_url, ''),
    coalesce(nullif(p_timezone, ''), 'UTC'),
    p_start_date,
    p_end_date,
    v_user_id,
    v_user_id
  )
  returning id into v_campaign_id;

  insert into public.campaign_memberships (campaign_id, user_id, status)
  values (v_campaign_id, v_user_id, 'active')
  returning id into v_membership_id;

  insert into public.campaign_membership_roles (membership_id, role_id)
  values (v_membership_id, v_owner_role_id);

  insert into public.campaign_entity_type_settings (
    campaign_id,
    entity_type_id,
    default_visibility,
    is_enabled,
    created_by,
    updated_by
  )
  select v_campaign_id, et.id, et.default_visibility, true, v_user_id, v_user_id
  from public.entity_types et
  where et.is_active;

  insert into public.campaign_currency_definitions (
    campaign_id,
    key,
    label,
    value_in_standard,
    is_standard,
    sort_order,
    created_by,
    updated_by
  )
  values
    (v_campaign_id, 'cp', 'Copper', 0.01, false, 10, v_user_id, v_user_id),
    (v_campaign_id, 'sp', 'Silver', 0.1, false, 20, v_user_id, v_user_id),
    (v_campaign_id, 'ep', 'Electrum', 0.5, false, 30, v_user_id, v_user_id),
    (v_campaign_id, 'gp', 'Gold', 1, true, 40, v_user_id, v_user_id),
    (v_campaign_id, 'pp', 'Platinum', 10, false, 50, v_user_id, v_user_id);

  perform public.import_campaign_preset_pack(v_campaign_id, p_preset_pack_key, null);

  return query
  select c.id, c.name, c.description, sd.key, sd.label, v_membership_id, array['owner']::text[]
  from public.campaigns c
  join public.status_definitions sd on sd.id = c.status_id
  where c.id = v_campaign_id;
end;
$$;

create or replace function public.get_campaign_options(
  p_campaign_id uuid,
  p_group_key text default null,
  p_include_inactive boolean default false
)
returns table (
  id uuid,
  group_id uuid,
  group_key text,
  key text,
  label text,
  description text,
  default_palette_color_id uuid,
  default_palette_color_token text,
  default_symbol_id uuid,
  default_symbol_icon_key text,
  sort_order integer,
  is_active boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    co.id,
    cog.id,
    cog.key,
    co.key,
    co.label,
    co.description,
    co.default_palette_color_id,
    cpc.color_token,
    co.default_symbol_id,
    cs.icon_key,
    co.sort_order,
    co.is_active
  from public.campaign_options co
  join public.campaign_option_groups cog on cog.id = co.group_id
  left join public.campaign_palette_colors cpc on cpc.id = co.default_palette_color_id
  left join public.campaign_symbols cs on cs.id = co.default_symbol_id
  where co.campaign_id = p_campaign_id
    and public.is_campaign_member(p_campaign_id)
    and (p_group_key is null or cog.key = p_group_key)
    and (p_include_inactive or (co.is_active and cog.is_active))
  order by cog.sort_order, co.sort_order, co.label;
$$;

create or replace function public.get_campaign_palette_colors(
  p_campaign_id uuid,
  p_include_inactive boolean default false
)
returns table (
  id uuid,
  key text,
  label text,
  color_token text,
  text_color_token text,
  sort_order integer,
  is_active boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select cpc.id, cpc.key, cpc.label, cpc.color_token, cpc.text_color_token, cpc.sort_order, cpc.is_active
  from public.campaign_palette_colors cpc
  where cpc.campaign_id = p_campaign_id
    and public.is_campaign_member(p_campaign_id)
    and (p_include_inactive or cpc.is_active)
  order by cpc.sort_order, cpc.label;
$$;

create or replace function public.get_campaign_symbols(
  p_campaign_id uuid,
  p_include_inactive boolean default false
)
returns table (
  id uuid,
  key text,
  label text,
  icon_key text,
  sort_order integer,
  is_active boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select cs.id, cs.key, cs.label, cs.icon_key, cs.sort_order, cs.is_active
  from public.campaign_symbols cs
  where cs.campaign_id = p_campaign_id
    and public.is_campaign_member(p_campaign_id)
    and (p_include_inactive or cs.is_active)
  order by cs.sort_order, cs.label;
$$;

alter table public.app_symbol_icon_keys enable row level security;
alter table public.option_preset_packs enable row level security;
alter table public.option_preset_groups enable row level security;
alter table public.palette_preset_colors enable row level security;
alter table public.symbol_preset_symbols enable row level security;
alter table public.option_preset_items enable row level security;
alter table public.campaign_palette_colors enable row level security;
alter table public.campaign_symbols enable row level security;
alter table public.campaign_option_groups enable row level security;
alter table public.campaign_options enable row level security;
alter table public.quick_stat_preset_templates enable row level security;
alter table public.quick_stat_preset_fields enable row level security;
alter table public.campaign_quick_stat_templates enable row level security;
alter table public.campaign_quick_stat_fields enable row level security;
alter table public.entity_quick_stat_values enable row level security;

create policy "Authenticated users can read symbol icon keys"
  on public.app_symbol_icon_keys for select to authenticated
  using (true);
create policy "Authenticated users can read active preset packs"
  on public.option_preset_packs for select to authenticated
  using (is_active);
create policy "Authenticated users can read active preset groups"
  on public.option_preset_groups for select to authenticated
  using (is_active);
create policy "Authenticated users can read active preset palette colors"
  on public.palette_preset_colors for select to authenticated
  using (is_active);
create policy "Authenticated users can read active preset symbols"
  on public.symbol_preset_symbols for select to authenticated
  using (is_active);
create policy "Authenticated users can read active preset items"
  on public.option_preset_items for select to authenticated
  using (is_active);
create policy "Authenticated users can read active quick stat preset templates"
  on public.quick_stat_preset_templates for select to authenticated
  using (is_active);
create policy "Authenticated users can read active quick stat preset fields"
  on public.quick_stat_preset_fields for select to authenticated
  using (is_active);

create policy "Campaign members can read palette colors"
  on public.campaign_palette_colors for select to authenticated
  using (public.is_campaign_member(campaign_id));
create policy "Owners and GMs can manage palette colors"
  on public.campaign_palette_colors for all to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Campaign members can read symbols"
  on public.campaign_symbols for select to authenticated
  using (public.is_campaign_member(campaign_id));
create policy "Owners and GMs can manage symbols"
  on public.campaign_symbols for all to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Campaign members can read option groups"
  on public.campaign_option_groups for select to authenticated
  using (public.is_campaign_member(campaign_id));
create policy "Owners and GMs can manage option groups"
  on public.campaign_option_groups for all to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Campaign members can read options"
  on public.campaign_options for select to authenticated
  using (public.is_campaign_member(campaign_id));
create policy "Owners and GMs can manage options"
  on public.campaign_options for all to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Campaign members can read quick stat templates"
  on public.campaign_quick_stat_templates for select to authenticated
  using (public.is_campaign_member(campaign_id));
create policy "Owners and GMs can manage quick stat templates"
  on public.campaign_quick_stat_templates for all to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Campaign members can read quick stat fields"
  on public.campaign_quick_stat_fields for select to authenticated
  using (public.is_campaign_member(campaign_id));
create policy "Owners and GMs can manage quick stat fields"
  on public.campaign_quick_stat_fields for all to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Visible quick stat values can be read"
  on public.entity_quick_stat_values for select to authenticated
  using (
    public.is_campaign_member(campaign_id)
    and public.can_view_campaign_entity(entity_id)
    and public.can_view_entity_visibility(campaign_id, visibility, created_by, entity_id)
  );
create policy "Core editors can manage quick stat values"
  on public.entity_quick_stat_values for all to authenticated
  using (public.can_edit_entity_core(entity_id))
  with check (public.can_edit_entity_core(entity_id));

revoke all on all tables in schema public from anon, public;
grant select on all tables in schema public to authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

revoke execute on all functions in schema public from anon, public;
grant execute on function public.current_user_id() to authenticated, service_role;
grant execute on function public.normalize_email(text) to authenticated, service_role;
grant execute on function public.current_user_email_normalized() to authenticated, service_role;
grant execute on function public.is_campaign_member(uuid) to authenticated, service_role;
grant execute on function public.is_campaign_owner(uuid) to authenticated, service_role;
grant execute on function public.has_campaign_role(uuid, text) to authenticated, service_role;
grant execute on function public.is_campaign_gm(uuid) to authenticated, service_role;
grant execute on function public.can_view_gm_content(uuid) to authenticated, service_role;
grant execute on function public.can_mutate_campaign_config(uuid) to authenticated, service_role;
grant execute on function public.ensure_user_defaults() to authenticated, service_role;
grant execute on function public.get_my_campaigns() to authenticated, service_role;
grant execute on function public.get_campaign_membership_summary(uuid) to authenticated, service_role;
grant execute on function public.get_campaign_entity_summaries(uuid) to authenticated, service_role;
grant execute on function public.get_safe_member_profiles(uuid) to authenticated, service_role;
grant execute on function public.can_view_entity_visibility(uuid, text, uuid, uuid) to authenticated, service_role;
grant execute on function public.can_view_campaign_entity(uuid) to authenticated, service_role;
grant execute on function public.can_edit_entity_core(uuid) to authenticated, service_role;
grant execute on function public.require_campaign_option(uuid, text, uuid, boolean, boolean) to authenticated, service_role;
grant execute on function public.require_campaign_palette_color(uuid, uuid, boolean, boolean) to authenticated, service_role;
grant execute on function public.require_campaign_symbol(uuid, uuid, boolean, boolean) to authenticated, service_role;
grant execute on function public.import_campaign_preset_pack(uuid, text, text[]) to authenticated, service_role;
grant execute on function public.create_campaign(text, date, text, date, text, text, text, text) to authenticated, service_role;
grant execute on function public.get_campaign_options(uuid, text, boolean) to authenticated, service_role;
grant execute on function public.get_campaign_palette_colors(uuid, boolean) to authenticated, service_role;
grant execute on function public.get_campaign_symbols(uuid, boolean) to authenticated, service_role;
