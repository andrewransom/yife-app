create extension if not exists pgcrypto with schema extensions;

create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid()
$$;

create or replace function public.normalize_email(email text)
returns text
language sql
immutable
as $$
  select nullif(lower(trim(email)), '')
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_asset_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme_preference text not null default 'system'
    check (theme_preference in ('system', 'light', 'dark')),
  default_landing_behavior text not null default 'home'
    check (default_landing_behavior in ('home', 'last_campaign')),
  default_campaign_id uuid,
  accessibility_preferences_jsonb jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.entity_types (
  id uuid primary key default gen_random_uuid(),
  key text not null,
  label text not null,
  plural_label text not null,
  icon_key text not null,
  default_visibility text not null check (default_visibility in ('shared', 'gm_only', 'private')),
  sort_order integer not null,
  is_system boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entity_types_key_unique unique (key)
);

create table public.status_definitions (
  id uuid primary key default gen_random_uuid(),
  subject_key text not null,
  entity_type_id uuid references public.entity_types(id) on delete cascade,
  campaign_id uuid,
  key text not null,
  label text not null,
  sort_order integer not null,
  color_token text,
  is_terminal boolean not null default false,
  is_system boolean not null default true,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint status_definitions_subject_check check (
    subject_key in ('campaign', 'entity_resource', 'entity')
  ),
  constraint status_definitions_entity_type_check check (
    (subject_key = 'entity' and entity_type_id is not null)
    or (subject_key <> 'entity' and entity_type_id is null)
  )
);

create unique index status_definitions_key_unique
  on public.status_definitions (subject_key, entity_type_id, campaign_id, key)
  nulls not distinct;

create table public.role_definitions (
  id uuid primary key default gen_random_uuid(),
  key text not null,
  label text not null,
  sort_order integer not null,
  is_system boolean not null default true,
  is_active boolean not null default true,
  constraint role_definitions_key_unique unique (key)
);

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  name text not null check (length(trim(name)) > 0),
  description text,
  status_id uuid not null references public.status_definitions(id) on delete restrict,
  start_date date not null,
  end_date date,
  image_asset_id uuid,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaigns_date_range_check check (end_date is null or end_date >= start_date)
);

create table public.campaign_memberships (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'removed')),
  display_name_override text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index campaign_memberships_active_unique
  on public.campaign_memberships (campaign_id, user_id)
  where status = 'active';

create table public.campaign_membership_roles (
  membership_id uuid not null references public.campaign_memberships(id) on delete cascade,
  role_id uuid not null references public.role_definitions(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (membership_id, role_id)
);

create table public.campaign_invitations (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  email_normalized text not null,
  invited_by_user_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'revoked', 'expired')),
  accepted_by_user_id uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  declined_at timestamptz,
  revoked_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_invitations_email_normalized_check check (email_normalized = public.normalize_email(email_normalized)),
  constraint campaign_invitations_expiry_check check (expires_at is null or expires_at > created_at),
  constraint campaign_invitations_status_timestamps_check check (
    (status = 'pending' and accepted_at is null and declined_at is null and revoked_at is null)
    or (status = 'accepted' and accepted_at is not null and accepted_by_user_id is not null)
    or (status = 'declined' and declined_at is not null)
    or (status = 'revoked' and revoked_at is not null)
    or (status = 'expired')
  )
);

create unique index campaign_invitations_pending_unique
  on public.campaign_invitations (campaign_id, email_normalized)
  where status = 'pending';

create table public.campaign_invitation_roles (
  invitation_id uuid not null references public.campaign_invitations(id) on delete cascade,
  role_id uuid not null references public.role_definitions(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (invitation_id, role_id)
);

create table public.campaign_entity_type_settings (
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  entity_type_id uuid not null references public.entity_types(id) on delete cascade,
  default_visibility text not null check (default_visibility in ('shared', 'gm_only', 'private')),
  is_enabled boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (campaign_id, entity_type_id)
);

create table public.entity_section_definitions (
  id uuid primary key default gen_random_uuid(),
  entity_type_id uuid not null references public.entity_types(id) on delete cascade,
  section_key text not null,
  label text not null,
  default_visibility text not null check (default_visibility in ('shared', 'gm_only', 'private')),
  default_edit_policy text not null
    check (default_edit_policy in ('gm_edit', 'owner_edit', 'player_edit', 'append_contributions')),
  default_content_mode text not null check (default_content_mode in ('document', 'contribution_feed')),
  sort_order integer not null,
  is_system boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entity_section_definitions_key_unique unique (entity_type_id, section_key)
);

create table public.entity_option_definitions (
  id uuid primary key default gen_random_uuid(),
  entity_type_id uuid references public.entity_types(id) on delete cascade,
  campaign_id uuid references public.campaigns(id) on delete cascade,
  group_key text not null,
  key text not null,
  label text not null,
  sort_order integer not null,
  is_system boolean not null default true,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index entity_option_definitions_key_unique
  on public.entity_option_definitions (entity_type_id, campaign_id, group_key, key)
  nulls not distinct;

create table public.relationship_types (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references public.campaigns(id) on delete cascade,
  key text not null,
  label text not null,
  inverse_label text,
  default_directionality text not null default 'directed'
    check (default_directionality in ('directed', 'undirected')),
  sort_order integer not null,
  is_system boolean not null default true,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index relationship_types_key_unique
  on public.relationship_types (campaign_id, key)
  nulls not distinct;

create table public.campaign_entities (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  entity_type_id uuid not null references public.entity_types(id) on delete restrict,
  list_caption text not null check (length(trim(list_caption)) > 0),
  default_visibility text not null check (default_visibility in ('shared', 'gm_only', 'private')),
  status_id uuid references public.status_definitions(id) on delete restrict,
  primary_image_asset_id uuid,
  relevant_date date,
  sort_key text,
  parent_entity_id uuid references public.campaign_entities(id) on delete set null,
  related_session_entity_id uuid references public.campaign_entities(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  deleted_at timestamptz
);

create index campaign_entities_campaign_updated_idx
  on public.campaign_entities (campaign_id, updated_at desc)
  where deleted_at is null;

create table public.campaign_currency_definitions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  key text not null,
  label text not null,
  value_in_standard numeric not null check (value_in_standard > 0),
  is_standard boolean not null default false,
  sort_order integer not null,
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_currency_definitions_key_unique unique (campaign_id, key)
);

create unique index campaign_currency_definitions_standard_unique
  on public.campaign_currency_definitions (campaign_id)
  where is_standard;

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references public.campaigns(id) on delete cascade,
  owner_user_id uuid references auth.users(id) on delete cascade,
  asset_scope text not null check (asset_scope in ('campaign', 'user_profile')),
  storage_bucket text not null default 'yife-images',
  status text not null default 'uploading' check (status in ('uploading', 'ready', 'failed', 'deleted')),
  current_version_key text not null default 'v1',
  title text,
  alt_text text,
  is_decorative boolean not null default false,
  crop_anchor text not null default 'center'
    check (crop_anchor in (
      'top-left', 'top-center', 'top-right',
      'center-left', 'center', 'center-right',
      'bottom-left', 'bottom-center', 'bottom-right'
    )),
  dominant_color text,
  blurhash text,
  original_filename text,
  original_mime_type text,
  original_byte_size bigint check (original_byte_size is null or original_byte_size > 0),
  original_width integer check (original_width is null or original_width > 0),
  original_height integer check (original_height is null or original_height > 0),
  retain_original boolean not null default false,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint media_assets_scope_check check (
    (asset_scope = 'campaign' and campaign_id is not null and owner_user_id is null)
    or (asset_scope = 'user_profile' and campaign_id is null and owner_user_id is not null)
  ),
  constraint media_assets_deleted_status_check check (
    (status = 'deleted' and deleted_at is not null)
    or (status <> 'deleted')
  )
);

create index media_assets_campaign_ready_idx
  on public.media_assets (campaign_id, status, created_at desc);
create index media_assets_created_by_idx
  on public.media_assets (created_by, created_at desc);
create index media_assets_deleted_idx
  on public.media_assets (deleted_at)
  where deleted_at is not null;

create table public.media_asset_variants (
  id uuid primary key default gen_random_uuid(),
  media_asset_id uuid not null references public.media_assets(id) on delete cascade,
  variant text not null check (variant in ('thumb_160', 'grid_480', 'original_1600')),
  storage_bucket text not null,
  storage_path text not null,
  width integer not null check (width > 0),
  height integer not null check (height > 0),
  format text not null,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  version_key text not null,
  created_at timestamptz not null default now(),
  constraint media_asset_variants_unique unique (media_asset_id, variant, version_key),
  constraint media_asset_variants_path_unique unique (storage_bucket, storage_path)
);

create index media_asset_variants_asset_idx
  on public.media_asset_variants (media_asset_id);
create index media_asset_variants_variant_idx
  on public.media_asset_variants (variant);

alter table public.user_profiles
  add constraint user_profiles_avatar_asset_fk
  foreign key (avatar_asset_id) references public.media_assets(id) on delete set null;

alter table public.user_settings
  add constraint user_settings_default_campaign_fk
  foreign key (default_campaign_id) references public.campaigns(id) on delete set null;

alter table public.campaigns
  add constraint campaigns_image_asset_fk
  foreign key (image_asset_id) references public.media_assets(id) on delete set null;

alter table public.campaign_entities
  add constraint campaign_entities_primary_image_fk
  foreign key (primary_image_asset_id) references public.media_assets(id) on delete set null;

create trigger user_profiles_set_updated_at
  before update on public.user_profiles
  for each row execute function public.set_updated_at();
create trigger user_settings_set_updated_at
  before update on public.user_settings
  for each row execute function public.set_updated_at();
create trigger entity_types_set_updated_at
  before update on public.entity_types
  for each row execute function public.set_updated_at();
create trigger status_definitions_set_updated_at
  before update on public.status_definitions
  for each row execute function public.set_updated_at();
create trigger campaigns_set_updated_at
  before update on public.campaigns
  for each row execute function public.set_updated_at();
create trigger campaign_memberships_set_updated_at
  before update on public.campaign_memberships
  for each row execute function public.set_updated_at();
create trigger campaign_invitations_set_updated_at
  before update on public.campaign_invitations
  for each row execute function public.set_updated_at();
create trigger campaign_entity_type_settings_set_updated_at
  before update on public.campaign_entity_type_settings
  for each row execute function public.set_updated_at();
create trigger entity_section_definitions_set_updated_at
  before update on public.entity_section_definitions
  for each row execute function public.set_updated_at();
create trigger entity_option_definitions_set_updated_at
  before update on public.entity_option_definitions
  for each row execute function public.set_updated_at();
create trigger relationship_types_set_updated_at
  before update on public.relationship_types
  for each row execute function public.set_updated_at();
create trigger campaign_entities_set_updated_at
  before update on public.campaign_entities
  for each row execute function public.set_updated_at();
create trigger campaign_currency_definitions_set_updated_at
  before update on public.campaign_currency_definitions
  for each row execute function public.set_updated_at();
create trigger media_assets_set_updated_at
  before update on public.media_assets
  for each row execute function public.set_updated_at();

insert into public.role_definitions (key, label, sort_order)
values
  ('owner', 'Owner', 10),
  ('game_master', 'Game Master', 20),
  ('player', 'Player', 30);

insert into public.entity_types (key, label, plural_label, icon_key, default_visibility, sort_order)
values
  ('character', 'Character', 'Characters', 'user-round', 'shared', 10),
  ('npc', 'NPC', 'NPCs', 'user-round-cog', 'shared', 20),
  ('party', 'Party', 'Parties', 'users-round', 'shared', 30),
  ('faction', 'Faction', 'Factions', 'shield', 'shared', 40),
  ('location', 'Location', 'Locations', 'map-pin', 'shared', 50),
  ('quest', 'Quest', 'Quests', 'scroll-text', 'shared', 60),
  ('session', 'Session', 'Sessions', 'calendar-days', 'shared', 70),
  ('plot_arc', 'Plot Arc', 'Plot Arcs', 'route', 'gm_only', 80),
  ('encounter', 'Encounter', 'Encounters', 'swords', 'gm_only', 90),
  ('timeline_event', 'Timeline Event', 'Timeline Events', 'clock', 'shared', 100);

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
values
  ('campaign', null, 'planned', 'Planned', 10, false),
  ('campaign', null, 'active', 'Active', 20, false),
  ('campaign', null, 'paused', 'Paused', 30, false),
  ('campaign', null, 'completed', 'Completed', 40, true),
  ('campaign', null, 'archived', 'Archived', 50, true),
  ('entity_resource', null, 'active', 'Active', 10, false),
  ('entity_resource', null, 'inactive', 'Inactive', 20, false),
  ('entity_resource', null, 'lost', 'Lost', 30, true),
  ('entity_resource', null, 'consumed', 'Consumed', 40, true),
  ('entity_resource', null, 'archived', 'Archived', 50, true);

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, s.key, s.label, s.sort_order, s.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('active', 'Active', 10, false),
    ('inactive', 'Inactive', 20, false),
    ('dead', 'Dead', 30, true),
    ('retired', 'Retired', 40, true),
    ('missing', 'Missing', 50, false)
) as s(key, label, sort_order, is_terminal)
where et.key = 'character';

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, s.key, s.label, s.sort_order, s.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('alive', 'Alive', 10, false),
    ('dead', 'Dead', 20, true),
    ('missing', 'Missing', 30, false),
    ('unknown', 'Unknown', 40, false),
    ('inactive', 'Inactive', 50, false)
) as s(key, label, sort_order, is_terminal)
where et.key = 'npc';

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, s.key, s.label, s.sort_order, s.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('open', 'Open', 10, false),
    ('in_progress', 'In Progress', 20, false),
    ('completed', 'Completed', 30, true),
    ('failed', 'Failed', 40, true),
    ('abandoned', 'Abandoned', 50, true),
    ('hidden', 'Hidden', 60, false)
) as s(key, label, sort_order, is_terminal)
where et.key = 'quest';

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, s.key, s.label, s.sort_order, s.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('planned', 'Planned', 10, false),
    ('completed', 'Completed', 20, true),
    ('cancelled', 'Cancelled', 30, true)
) as s(key, label, sort_order, is_terminal)
where et.key = 'session';

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, s.key, s.label, s.sort_order, s.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('planned', 'Planned', 10, false),
    ('active', 'Active', 20, false),
    ('resolved', 'Resolved', 30, true),
    ('abandoned', 'Abandoned', 40, true),
    ('hidden', 'Hidden', 50, false)
) as s(key, label, sort_order, is_terminal)
where et.key = 'plot_arc';

insert into public.status_definitions (subject_key, entity_type_id, key, label, sort_order, is_terminal)
select 'entity', et.id, s.key, s.label, s.sort_order, s.is_terminal
from public.entity_types et
cross join lateral (
  values
    ('planned', 'Planned', 10, false),
    ('ready', 'Ready', 20, false),
    ('completed', 'Completed', 30, true),
    ('skipped', 'Skipped', 40, true),
    ('archived', 'Archived', 50, true)
) as s(key, label, sort_order, is_terminal)
where et.key = 'encounter';

insert into public.entity_option_definitions (entity_type_id, group_key, key, label, sort_order)
select et.id, 'location_type', v.key, v.label, v.sort_order
from public.entity_types et
cross join lateral (
  values
    ('world', 'World', 10),
    ('continent', 'Continent', 20),
    ('country', 'Country', 30),
    ('region', 'Region', 40),
    ('town', 'Town', 50),
    ('city', 'City', 60),
    ('wilderness_area', 'Wilderness Area', 70),
    ('district', 'District', 80),
    ('landmark', 'Landmark', 90),
    ('building', 'Building', 100),
    ('room', 'Room', 110),
    ('dungeon', 'Dungeon', 120),
    ('plane', 'Plane', 130),
    ('other', 'Other', 140)
) as v(key, label, sort_order)
where et.key = 'location';

insert into public.entity_option_definitions (entity_type_id, group_key, key, label, sort_order)
select et.id, 'timeline_event_type', v.key, v.label, v.sort_order
from public.entity_types et
cross join lateral (
  values
    ('world_history', 'World History', 10),
    ('campaign_event', 'Campaign Event', 20),
    ('session_event', 'Session Event', 30),
    ('character_event', 'Character Event', 40),
    ('faction_event', 'Faction Event', 50),
    ('location_event', 'Location Event', 60),
    ('quest_event', 'Quest Event', 70),
    ('omen_prophecy', 'Omen/Prophecy', 80),
    ('other', 'Other', 90)
) as v(key, label, sort_order)
where et.key = 'timeline_event';

insert into public.entity_option_definitions (entity_type_id, group_key, key, label, sort_order)
select et.id, 'encounter_type', v.key, v.label, v.sort_order
from public.entity_types et
cross join lateral (
  values
    ('roleplay', 'Roleplay', 10),
    ('exploration', 'Exploration', 20),
    ('combat', 'Combat', 30),
    ('puzzle', 'Puzzle', 40),
    ('travel', 'Travel', 50),
    ('mixed', 'Mixed', 60),
    ('other', 'Other', 70)
) as v(key, label, sort_order)
where et.key = 'encounter';

insert into public.entity_option_definitions (entity_type_id, group_key, key, label, sort_order)
select et.id, 'quest_priority', v.key, v.label, v.sort_order
from public.entity_types et
cross join lateral (
  values
    ('low', 'Low', 10),
    ('normal', 'Normal', 20),
    ('high', 'High', 30),
    ('urgent', 'Urgent', 40)
) as v(key, label, sort_order)
where et.key = 'quest';

insert into public.relationship_types (key, label, inverse_label, default_directionality, sort_order)
values
  ('related_to', 'Related to', 'Related to', 'undirected', 10),
  ('ally_of', 'Ally of', 'Ally of', 'undirected', 20),
  ('enemy_of', 'Enemy of', 'Enemy of', 'undirected', 30),
  ('member_of', 'Member of', 'Has member', 'directed', 40),
  ('leader_of', 'Leader of', 'Led by', 'directed', 50),
  ('located_in', 'Located in', 'Contains', 'directed', 60),
  ('owns', 'Owns', 'Owned by', 'directed', 70),
  ('works_for', 'Works for', 'Employs', 'directed', 80),
  ('seeks', 'Seeks', 'Sought by', 'directed', 90),
  ('protects', 'Protects', 'Protected by', 'directed', 100),
  ('threatens', 'Threatens', 'Threatened by', 'directed', 110),
  ('created_by', 'Created by', 'Created', 'directed', 120),
  ('parent_of', 'Parent of', 'Child of', 'directed', 130),
  ('child_of', 'Child of', 'Parent of', 'directed', 140);

insert into public.entity_section_definitions (
  entity_type_id,
  section_key,
  label,
  default_visibility,
  default_edit_policy,
  default_content_mode,
  sort_order
)
select et.id, v.section_key, v.label, v.default_visibility, v.default_edit_policy, v.default_content_mode, v.sort_order
from public.entity_types et
join lateral (
  values
    ('character', 'player_summary', 'Player Summary', 'shared', 'gm_edit', 'document', 10),
    ('character', 'backstory', 'Backstory', 'shared', 'owner_edit', 'document', 20),
    ('character', 'gm_notes', 'GM Notes', 'gm_only', 'gm_edit', 'document', 30),
    ('npc', 'player_summary', 'Player Summary', 'shared', 'gm_edit', 'document', 10),
    ('npc', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 'document', 20),
    ('npc', 'player_observations', 'Player Observations', 'shared', 'append_contributions', 'contribution_feed', 30),
    ('party', 'description', 'Description', 'shared', 'gm_edit', 'document', 10),
    ('party', 'party_notes', 'Party Notes', 'shared', 'player_edit', 'document', 20),
    ('faction', 'player_summary', 'Player Summary', 'shared', 'gm_edit', 'document', 10),
    ('faction', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 'document', 20),
    ('location', 'player_summary', 'Player Summary', 'shared', 'gm_edit', 'document', 10),
    ('location', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 'document', 20),
    ('quest', 'player_summary', 'Player Summary', 'shared', 'gm_edit', 'document', 10),
    ('quest', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 'document', 20),
    ('quest', 'player_observations', 'Player Observations', 'shared', 'append_contributions', 'contribution_feed', 30),
    ('session', 'summary', 'Summary', 'shared', 'gm_edit', 'document', 10),
    ('session', 'gm_prep', 'GM Prep', 'gm_only', 'gm_edit', 'document', 20),
    ('session', 'gm_private_notes', 'GM Private Notes', 'gm_only', 'gm_edit', 'document', 30),
    ('plot_arc', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 'document', 10),
    ('encounter', 'gm_prep', 'GM Prep', 'gm_only', 'gm_edit', 'document', 10),
    ('encounter', 'outcomes', 'Outcomes', 'shared', 'gm_edit', 'document', 20),
    ('timeline_event', 'description', 'Description', 'shared', 'gm_edit', 'document', 10),
    ('timeline_event', 'gm_details', 'GM Details', 'gm_only', 'gm_edit', 'document', 20)
) as v(entity_type_key, section_key, label, default_visibility, default_edit_policy, default_content_mode, sort_order)
on v.entity_type_key = et.key;

create or replace function public.current_user_email_normalized()
returns text
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select public.normalize_email(u.email)
  from auth.users u
  where u.id = public.current_user_id()
$$;

create or replace function public.is_campaign_member(campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.campaign_memberships cm
    where cm.campaign_id = is_campaign_member.campaign_id
      and cm.user_id = public.current_user_id()
      and cm.status = 'active'
  )
$$;

create or replace function public.has_campaign_role(campaign_id uuid, role_key text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.campaign_memberships cm
    join public.campaign_membership_roles cmr on cmr.membership_id = cm.id
    join public.role_definitions rd on rd.id = cmr.role_id
    where cm.campaign_id = has_campaign_role.campaign_id
      and cm.user_id = public.current_user_id()
      and cm.status = 'active'
      and rd.key = has_campaign_role.role_key
      and rd.is_active
  )
$$;

create or replace function public.is_campaign_owner(campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.campaigns c
    join public.campaign_memberships cm
      on cm.campaign_id = c.id
     and cm.user_id = c.owner_user_id
     and cm.status = 'active'
    where c.id = is_campaign_owner.campaign_id
      and c.owner_user_id = public.current_user_id()
  )
$$;

create or replace function public.is_campaign_gm(campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.has_campaign_role(is_campaign_gm.campaign_id, 'game_master')
$$;

create or replace function public.can_view_gm_content(campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.is_campaign_owner(can_view_gm_content.campaign_id)
      or public.is_campaign_gm(can_view_gm_content.campaign_id)
$$;

create or replace function public.can_mutate_campaign_config(campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can_view_gm_content(can_mutate_campaign_config.campaign_id)
$$;

create or replace function public.ensure_user_defaults()
returns table (
  user_id uuid,
  display_name text,
  theme_preference text,
  default_landing_behavior text
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_email text;
  v_display_name text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select u.email into v_email
  from auth.users u
  where u.id = v_user_id;

  if v_email is not null and position('@' in v_email) > 1 then
    v_display_name := split_part(v_email, '@', 1);
  else
    v_display_name := '';
  end if;

  insert into public.user_profiles (user_id, display_name)
  values (v_user_id, v_display_name)
  on conflict on constraint user_profiles_pkey do update
    set display_name = coalesce(nullif(public.user_profiles.display_name, ''), excluded.display_name);

  insert into public.user_settings (user_id)
  values (v_user_id)
  on conflict on constraint user_settings_pkey do nothing;

  return query
  select up.user_id, up.display_name, us.theme_preference, us.default_landing_behavior
  from public.user_profiles up
  join public.user_settings us on us.user_id = up.user_id
  where up.user_id = v_user_id;
end;
$$;

create or replace function public.validate_campaign_status()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.status_definitions sd
    where sd.id = new.status_id
      and sd.subject_key = 'campaign'
      and sd.entity_type_id is null
      and sd.campaign_id is null
      and sd.is_active
  ) then
    raise exception 'Invalid campaign status';
  end if;

  return new;
end;
$$;

create trigger campaigns_validate_status
  before insert or update of status_id on public.campaigns
  for each row execute function public.validate_campaign_status();

create or replace function public.prevent_campaign_owner_change()
returns trigger
language plpgsql
as $$
begin
  if new.owner_user_id is distinct from old.owner_user_id then
    raise exception 'Campaign owner transfer is not implemented';
  end if;
  return new;
end;
$$;

create trigger campaigns_prevent_owner_change
  before update of owner_user_id on public.campaigns
  for each row execute function public.prevent_campaign_owner_change();

create or replace function public.prevent_owner_membership_change()
returns trigger
language plpgsql
as $$
declare
  v_owner uuid;
begin
  if tg_op = 'DELETE' then
    select c.owner_user_id into v_owner
    from public.campaigns c
    where c.id = old.campaign_id;

    if old.user_id = v_owner then
      raise exception 'Canonical owner membership cannot be removed';
    end if;

    return old;
  end if;

  select c.owner_user_id into v_owner
  from public.campaigns c
  where c.id = new.campaign_id;

  if old.user_id = v_owner and (
    new.status <> 'active'
    or new.user_id is distinct from old.user_id
    or new.campaign_id is distinct from old.campaign_id
  ) then
    raise exception 'Canonical owner membership must remain active';
  end if;

  return new;
end;
$$;

create trigger campaign_memberships_preserve_owner
  before update or delete on public.campaign_memberships
  for each row execute function public.prevent_owner_membership_change();

create or replace function public.prevent_owner_role_change()
returns trigger
language plpgsql
as $$
declare
  v_membership public.campaign_memberships%rowtype;
  v_role_key text;
  v_owner uuid;
begin
  if tg_op = 'DELETE' then
    select * into v_membership from public.campaign_memberships where id = old.membership_id;
    select key into v_role_key from public.role_definitions where id = old.role_id;
    select owner_user_id into v_owner from public.campaigns where id = v_membership.campaign_id;

    if v_role_key = 'owner' and v_membership.user_id = v_owner and v_membership.status = 'active' then
      raise exception 'Canonical owner role cannot be removed';
    end if;

    return old;
  end if;

  select * into v_membership from public.campaign_memberships where id = old.membership_id;
  select key into v_role_key from public.role_definitions where id = old.role_id;
  select owner_user_id into v_owner from public.campaigns where id = v_membership.campaign_id;

  if v_role_key = 'owner' and v_membership.user_id = v_owner and (
    new.membership_id is distinct from old.membership_id
    or new.role_id is distinct from old.role_id
  ) then
    raise exception 'Canonical owner role cannot be changed';
  end if;

  return new;
end;
$$;

create trigger campaign_membership_roles_preserve_owner
  before update or delete on public.campaign_membership_roles
  for each row execute function public.prevent_owner_role_change();

create or replace function public.validate_campaign_primary_image()
returns trigger
language plpgsql
as $$
begin
  if new.image_asset_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.media_assets ma
    where ma.id = new.image_asset_id
      and ma.asset_scope = 'campaign'
      and ma.campaign_id = new.id
      and ma.status = 'ready'
      and ma.deleted_at is null
  ) then
    raise exception 'Campaign primary image must be a ready same-campaign asset';
  end if;

  return new;
end;
$$;

create trigger campaigns_validate_primary_image
  before insert or update of image_asset_id on public.campaigns
  for each row execute function public.validate_campaign_primary_image();

create or replace function public.validate_profile_avatar()
returns trigger
language plpgsql
as $$
begin
  if new.avatar_asset_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.media_assets ma
    where ma.id = new.avatar_asset_id
      and ma.asset_scope = 'user_profile'
      and ma.owner_user_id = new.user_id
      and ma.status = 'ready'
      and ma.deleted_at is null
  ) then
    raise exception 'Profile avatar must be a ready user-profile asset owned by the user';
  end if;

  return new;
end;
$$;

create trigger user_profiles_validate_avatar
  before insert or update of avatar_asset_id on public.user_profiles
  for each row execute function public.validate_profile_avatar();

create or replace function public.validate_campaign_entity_primary_image()
returns trigger
language plpgsql
as $$
begin
  if new.primary_image_asset_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.media_assets ma
    where ma.id = new.primary_image_asset_id
      and ma.asset_scope = 'campaign'
      and ma.campaign_id = new.campaign_id
      and ma.status = 'ready'
      and ma.deleted_at is null
  ) then
    raise exception 'Entity primary image must be a ready same-campaign asset';
  end if;

  return new;
end;
$$;

create trigger campaign_entities_validate_primary_image
  before insert or update of primary_image_asset_id on public.campaign_entities
  for each row execute function public.validate_campaign_entity_primary_image();

create or replace function public.validate_media_asset_variant_retention()
returns trigger
language plpgsql
as $$
begin
  if new.variant = 'original_1600' and not exists (
    select 1
    from public.media_assets ma
    where ma.id = new.media_asset_id
      and ma.retain_original
  ) then
    raise exception 'original_1600 variants require the parent asset to retain originals';
  end if;

  return new;
end;
$$;

create trigger media_asset_variants_validate_retention
  before insert or update of media_asset_id, variant on public.media_asset_variants
  for each row execute function public.validate_media_asset_variant_retention();

create or replace function public.validate_media_asset_original_retention()
returns trigger
language plpgsql
as $$
begin
  if not new.retain_original and exists (
    select 1
    from public.media_asset_variants mav
    where mav.media_asset_id = new.id
      and mav.variant = 'original_1600'
  ) then
    raise exception 'Assets with original_1600 variants must retain originals';
  end if;

  return new;
end;
$$;

create constraint trigger media_assets_validate_original_retention
  after insert or update of retain_original on public.media_assets
  deferrable initially immediate
  for each row execute function public.validate_media_asset_original_retention();

create or replace function public.validate_ready_media_asset_variants()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'ready' then
    if not exists (
      select 1
      from public.media_asset_variants mav
      where mav.media_asset_id = new.id
        and mav.version_key = new.current_version_key
        and mav.variant = 'thumb_160'
    ) or not exists (
      select 1
      from public.media_asset_variants mav
      where mav.media_asset_id = new.id
        and mav.version_key = new.current_version_key
        and mav.variant = 'grid_480'
    ) then
      raise exception 'Ready media assets require active thumb_160 and grid_480 variants';
    end if;
  end if;

  return new;
end;
$$;

create constraint trigger media_assets_require_ready_variants
  after insert or update of status, current_version_key on public.media_assets
  deferrable initially immediate
  for each row execute function public.validate_ready_media_asset_variants();

create or replace function public.create_campaign(
  p_name text,
  p_start_date date,
  p_description text default null,
  p_end_date date default null,
  p_status_key text default 'planned'
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

  return query
  select c.id, c.name, c.description, sd.key, sd.label, v_membership_id, array['owner']::text[]
  from public.campaigns c
  join public.status_definitions sd on sd.id = c.status_id
  where c.id = v_campaign_id;
end;
$$;

create or replace function public.get_my_campaigns()
returns table (
  campaign_id uuid,
  name text,
  description text,
  status_key text,
  status_label text,
  membership_status text,
  role_keys text[],
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
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    c.id as campaign_id,
    c.name,
    c.description,
    sd.key as status_key,
    sd.label as status_label,
    cm.status as membership_status,
    coalesce(array_agg(rd.key order by rd.sort_order) filter (where rd.key is not null), '{}'::text[]) as role_keys,
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
    c.updated_at
  from public.campaign_memberships cm
  join public.campaigns c on c.id = cm.campaign_id
  join public.status_definitions sd on sd.id = c.status_id
  left join public.campaign_membership_roles cmr on cmr.membership_id = cm.id
  left join public.role_definitions rd on rd.id = cmr.role_id and rd.is_active
  left join public.media_assets ma
    on ma.id = c.image_asset_id
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
  where cm.user_id = public.current_user_id()
    and cm.status = 'active'
  group by c.id, sd.key, sd.label, cm.status, ma.id, thumb.id, grid.id
  order by c.updated_at desc;
$$;

create or replace function public.get_campaign_membership_summary(p_campaign_id uuid)
returns table (
  campaign_id uuid,
  user_id uuid,
  membership_status text,
  role_keys text[]
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    cm.campaign_id,
    cm.user_id,
    cm.status as membership_status,
    coalesce(array_agg(rd.key order by rd.sort_order) filter (where rd.key is not null), '{}'::text[]) as role_keys
  from public.campaign_memberships cm
  left join public.campaign_membership_roles cmr on cmr.membership_id = cm.id
  left join public.role_definitions rd on rd.id = cmr.role_id and rd.is_active
  where cm.campaign_id = p_campaign_id
    and cm.user_id = public.current_user_id()
    and cm.status = 'active'
  group by cm.campaign_id, cm.user_id, cm.status;
$$;

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
  parent_entity_id uuid,
  related_session_entity_id uuid,
  updated_at timestamptz,
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
    ce.parent_entity_id,
    ce.related_session_entity_id,
    ce.updated_at,
    ce.deleted_at
  from public.campaign_entities ce
  join public.entity_types et on et.id = ce.entity_type_id
  left join public.status_definitions sd on sd.id = ce.status_id
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
    and public.is_campaign_member(ce.campaign_id)
    and (
      ce.default_visibility = 'shared'
      or (ce.default_visibility = 'gm_only' and public.can_view_gm_content(ce.campaign_id))
      or (ce.default_visibility = 'private' and ce.created_by = public.current_user_id())
    )
  order by ce.updated_at desc;
$$;

create or replace function public.get_safe_member_profiles(p_campaign_id uuid)
returns table (
  campaign_id uuid,
  user_id uuid,
  display_name text,
  display_name_override text,
  avatar_asset_id uuid,
  avatar_thumb_bucket text,
  avatar_thumb_path text,
  avatar_thumb_width integer,
  avatar_thumb_height integer,
  avatar_is_decorative boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    cm.campaign_id,
    up.user_id,
    up.display_name,
    cm.display_name_override,
    ma.id as avatar_asset_id,
    thumb.storage_bucket as avatar_thumb_bucket,
    thumb.storage_path as avatar_thumb_path,
    thumb.width as avatar_thumb_width,
    thumb.height as avatar_thumb_height,
    ma.is_decorative as avatar_is_decorative
  from public.campaign_memberships viewer
  join public.campaign_memberships cm
    on cm.campaign_id = viewer.campaign_id
   and cm.status = 'active'
  join public.user_profiles up on up.user_id = cm.user_id
  left join public.media_assets ma
    on ma.id = up.avatar_asset_id
   and ma.asset_scope = 'user_profile'
   and ma.status = 'ready'
   and ma.deleted_at is null
  left join public.media_asset_variants thumb
    on thumb.media_asset_id = ma.id
   and thumb.version_key = ma.current_version_key
   and thumb.variant = 'thumb_160'
  where viewer.campaign_id = p_campaign_id
    and viewer.user_id = public.current_user_id()
    and viewer.status = 'active'
  order by coalesce(cm.display_name_override, up.display_name), up.user_id;
$$;

create view public.campaign_entity_summaries
with (security_invoker = true)
as
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
  ce.parent_entity_id,
  ce.related_session_entity_id,
  ce.updated_at,
  ce.deleted_at
from public.campaign_entities ce
join public.entity_types et on et.id = ce.entity_type_id
left join public.status_definitions sd on sd.id = ce.status_id
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
where ce.deleted_at is null
  and public.is_campaign_member(ce.campaign_id)
  and (
    ce.default_visibility = 'shared'
    or (ce.default_visibility = 'gm_only' and public.can_view_gm_content(ce.campaign_id))
    or (ce.default_visibility = 'private' and ce.created_by = public.current_user_id())
  );

alter table public.user_profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.entity_types enable row level security;
alter table public.status_definitions enable row level security;
alter table public.role_definitions enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_memberships enable row level security;
alter table public.campaign_membership_roles enable row level security;
alter table public.campaign_invitations enable row level security;
alter table public.campaign_invitation_roles enable row level security;
alter table public.campaign_entity_type_settings enable row level security;
alter table public.entity_section_definitions enable row level security;
alter table public.entity_option_definitions enable row level security;
alter table public.relationship_types enable row level security;
alter table public.campaign_entities enable row level security;
alter table public.campaign_currency_definitions enable row level security;
alter table public.media_assets enable row level security;
alter table public.media_asset_variants enable row level security;

create policy "Users can read their own profile"
  on public.user_profiles for select
  to authenticated
  using (
    user_id = public.current_user_id()
    or exists (
      select 1
      from public.campaign_memberships self_cm
      join public.campaign_memberships target_cm
        on target_cm.campaign_id = self_cm.campaign_id
       and target_cm.user_id = user_profiles.user_id
       and target_cm.status = 'active'
      where self_cm.user_id = public.current_user_id()
        and self_cm.status = 'active'
    )
  );

create policy "Users can insert their own profile"
  on public.user_profiles for insert
  to authenticated
  with check (user_id = public.current_user_id());

create policy "Users can update their own profile"
  on public.user_profiles for update
  to authenticated
  using (user_id = public.current_user_id())
  with check (user_id = public.current_user_id());

create policy "Users can read their own settings"
  on public.user_settings for select
  to authenticated
  using (user_id = public.current_user_id());

create policy "Users can insert their own settings"
  on public.user_settings for insert
  to authenticated
  with check (user_id = public.current_user_id());

create policy "Users can update their own settings"
  on public.user_settings for update
  to authenticated
  using (user_id = public.current_user_id())
  with check (user_id = public.current_user_id());

create policy "Authenticated users can read role definitions"
  on public.role_definitions for select
  to authenticated
  using (is_active);

create policy "Authenticated users can read entity types"
  on public.entity_types for select
  to authenticated
  using (is_active);

create policy "Authenticated users can read active system statuses"
  on public.status_definitions for select
  to authenticated
  using (
    is_active
    and (
      campaign_id is null
      or public.is_campaign_member(campaign_id)
    )
  );

create policy "Owners and GMs can insert campaign statuses"
  on public.status_definitions for insert
  to authenticated
  with check (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Owners and GMs can update campaign statuses"
  on public.status_definitions for update
  to authenticated
  using (campaign_id is not null and public.can_mutate_campaign_config(campaign_id))
  with check (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Owners and GMs can delete campaign statuses"
  on public.status_definitions for delete
  to authenticated
  using (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Campaign members can read campaigns"
  on public.campaigns for select
  to authenticated
  using (public.is_campaign_member(id));

create policy "Owners and GMs can update campaign settings"
  on public.campaigns for update
  to authenticated
  using (public.can_mutate_campaign_config(id))
  with check (public.can_mutate_campaign_config(id));

create policy "Campaign members can read memberships"
  on public.campaign_memberships for select
  to authenticated
  using (public.is_campaign_member(campaign_id));

create policy "Owners can manage memberships"
  on public.campaign_memberships for insert
  to authenticated
  with check (public.is_campaign_owner(campaign_id));

create policy "Owners can update memberships"
  on public.campaign_memberships for update
  to authenticated
  using (public.is_campaign_owner(campaign_id))
  with check (public.is_campaign_owner(campaign_id));

create policy "Campaign members can read membership roles"
  on public.campaign_membership_roles for select
  to authenticated
  using (
    exists (
      select 1
      from public.campaign_memberships cm
      where cm.id = campaign_membership_roles.membership_id
        and public.is_campaign_member(cm.campaign_id)
    )
  );

create policy "Owners can insert membership roles"
  on public.campaign_membership_roles for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.campaign_memberships cm
      where cm.id = campaign_membership_roles.membership_id
        and public.is_campaign_owner(cm.campaign_id)
    )
  );

create policy "Owners can update membership roles"
  on public.campaign_membership_roles for update
  to authenticated
  using (
    exists (
      select 1
      from public.campaign_memberships cm
      where cm.id = campaign_membership_roles.membership_id
        and public.is_campaign_owner(cm.campaign_id)
    )
  )
  with check (
    exists (
      select 1
      from public.campaign_memberships cm
      where cm.id = campaign_membership_roles.membership_id
        and public.is_campaign_owner(cm.campaign_id)
    )
  );

create policy "Owners can delete membership roles"
  on public.campaign_membership_roles for delete
  to authenticated
  using (
    exists (
      select 1
      from public.campaign_memberships cm
      where cm.id = campaign_membership_roles.membership_id
        and public.is_campaign_owner(cm.campaign_id)
    )
  );

create policy "Owners and GMs can read campaign invitations"
  on public.campaign_invitations for select
  to authenticated
  using (
    public.can_mutate_campaign_config(campaign_id)
    or email_normalized = public.current_user_email_normalized()
  );

create policy "Owners and GMs can insert campaign invitations"
  on public.campaign_invitations for insert
  to authenticated
  with check (
    public.can_mutate_campaign_config(campaign_id)
    and invited_by_user_id = public.current_user_id()
    and email_normalized = public.normalize_email(email_normalized)
  );

create policy "Owners and GMs can update campaign invitations"
  on public.campaign_invitations for update
  to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Invitation role visibility follows invitations"
  on public.campaign_invitation_roles for select
  to authenticated
  using (
    exists (
      select 1
      from public.campaign_invitations ci
      where ci.id = campaign_invitation_roles.invitation_id
        and (
          public.can_mutate_campaign_config(ci.campaign_id)
          or ci.email_normalized = public.current_user_email_normalized()
        )
    )
  );

create policy "Owners and GMs can insert invitation roles"
  on public.campaign_invitation_roles for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.campaign_invitations ci
      where ci.id = campaign_invitation_roles.invitation_id
        and public.can_mutate_campaign_config(ci.campaign_id)
    )
  );

create policy "Owners and GMs can update invitation roles"
  on public.campaign_invitation_roles for update
  to authenticated
  using (
    exists (
      select 1
      from public.campaign_invitations ci
      where ci.id = campaign_invitation_roles.invitation_id
        and public.can_mutate_campaign_config(ci.campaign_id)
    )
  )
  with check (
    exists (
      select 1
      from public.campaign_invitations ci
      where ci.id = campaign_invitation_roles.invitation_id
        and public.can_mutate_campaign_config(ci.campaign_id)
    )
  );

create policy "Owners and GMs can delete invitation roles"
  on public.campaign_invitation_roles for delete
  to authenticated
  using (
    exists (
      select 1
      from public.campaign_invitations ci
      where ci.id = campaign_invitation_roles.invitation_id
        and public.can_mutate_campaign_config(ci.campaign_id)
    )
  );

create policy "Campaign members can read entity type settings"
  on public.campaign_entity_type_settings for select
  to authenticated
  using (public.is_campaign_member(campaign_id));

create policy "Owners and GMs can update entity type settings"
  on public.campaign_entity_type_settings for update
  to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Authenticated users can read section definitions"
  on public.entity_section_definitions for select
  to authenticated
  using (is_active);

create policy "Authenticated users can read system or campaign options"
  on public.entity_option_definitions for select
  to authenticated
  using (
    is_active
    and (
      campaign_id is null
      or public.is_campaign_member(campaign_id)
    )
  );

create policy "Owners and GMs can insert campaign options"
  on public.entity_option_definitions for insert
  to authenticated
  with check (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Owners and GMs can update campaign options"
  on public.entity_option_definitions for update
  to authenticated
  using (campaign_id is not null and public.can_mutate_campaign_config(campaign_id))
  with check (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Owners and GMs can delete campaign options"
  on public.entity_option_definitions for delete
  to authenticated
  using (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Authenticated users can read system or campaign relationship types"
  on public.relationship_types for select
  to authenticated
  using (
    is_active
    and (
      campaign_id is null
      or public.is_campaign_member(campaign_id)
    )
  );

create policy "Owners and GMs can insert campaign relationship types"
  on public.relationship_types for insert
  to authenticated
  with check (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Owners and GMs can update campaign relationship types"
  on public.relationship_types for update
  to authenticated
  using (campaign_id is not null and public.can_mutate_campaign_config(campaign_id))
  with check (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Owners and GMs can delete campaign relationship types"
  on public.relationship_types for delete
  to authenticated
  using (campaign_id is not null and public.can_mutate_campaign_config(campaign_id));

create policy "Visible campaign entities can be read"
  on public.campaign_entities for select
  to authenticated
  using (
    public.is_campaign_member(campaign_id)
    and deleted_at is null
    and (
      default_visibility = 'shared'
      or (default_visibility = 'gm_only' and public.can_view_gm_content(campaign_id))
      or (default_visibility = 'private' and created_by = public.current_user_id())
    )
  );

create policy "Campaign members can read currency definitions"
  on public.campaign_currency_definitions for select
  to authenticated
  using (public.is_campaign_member(campaign_id));

create policy "Owners and GMs can insert currency definitions"
  on public.campaign_currency_definitions for insert
  to authenticated
  with check (
    public.can_mutate_campaign_config(campaign_id)
    and created_by = public.current_user_id()
    and updated_by = public.current_user_id()
  );

create policy "Owners and GMs can update currency definitions"
  on public.campaign_currency_definitions for update
  to authenticated
  using (public.can_mutate_campaign_config(campaign_id))
  with check (public.can_mutate_campaign_config(campaign_id));

create policy "Owner and GMs can read campaign media metadata"
  on public.media_assets for select
  to authenticated
  using (
    (asset_scope = 'campaign' and public.can_mutate_campaign_config(campaign_id))
    or (asset_scope = 'campaign' and created_by = public.current_user_id() and public.is_campaign_member(campaign_id))
    or (asset_scope = 'user_profile' and owner_user_id = public.current_user_id())
  );

create policy "Owners and GMs can insert campaign media metadata"
  on public.media_assets for insert
  to authenticated
  with check (
    (
      asset_scope = 'campaign'
      and public.can_mutate_campaign_config(campaign_id)
      and created_by = public.current_user_id()
      and updated_by = public.current_user_id()
    )
    or (
      asset_scope = 'user_profile'
      and owner_user_id = public.current_user_id()
      and created_by = public.current_user_id()
      and updated_by = public.current_user_id()
    )
  );

create policy "Owners and GMs can update campaign media metadata"
  on public.media_assets for update
  to authenticated
  using (
    (asset_scope = 'campaign' and public.can_mutate_campaign_config(campaign_id))
    or (asset_scope = 'user_profile' and owner_user_id = public.current_user_id())
  )
  with check (
    (asset_scope = 'campaign' and public.can_mutate_campaign_config(campaign_id))
    or (asset_scope = 'user_profile' and owner_user_id = public.current_user_id())
  );

create policy "Media variants follow asset metadata"
  on public.media_asset_variants for select
  to authenticated
  using (
    exists (
      select 1
      from public.media_assets ma
      where ma.id = media_asset_variants.media_asset_id
        and (
          (ma.asset_scope = 'campaign' and public.can_mutate_campaign_config(ma.campaign_id))
          or (ma.asset_scope = 'campaign' and ma.created_by = public.current_user_id() and public.is_campaign_member(ma.campaign_id))
          or (ma.asset_scope = 'user_profile' and ma.owner_user_id = public.current_user_id())
        )
    )
  );

create policy "Media variant writes follow asset metadata"
  on public.media_asset_variants for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.media_assets ma
      where ma.id = media_asset_variants.media_asset_id
        and (
          (ma.asset_scope = 'campaign' and public.can_mutate_campaign_config(ma.campaign_id))
          or (ma.asset_scope = 'user_profile' and ma.owner_user_id = public.current_user_id())
        )
    )
  );

create policy "Media variant updates follow asset metadata"
  on public.media_asset_variants for update
  to authenticated
  using (
    exists (
      select 1
      from public.media_assets ma
      where ma.id = media_asset_variants.media_asset_id
        and (
          (ma.asset_scope = 'campaign' and public.can_mutate_campaign_config(ma.campaign_id))
          or (ma.asset_scope = 'user_profile' and ma.owner_user_id = public.current_user_id())
        )
    )
  )
  with check (
    exists (
      select 1
      from public.media_assets ma
      where ma.id = media_asset_variants.media_asset_id
        and (
          (ma.asset_scope = 'campaign' and public.can_mutate_campaign_config(ma.campaign_id))
          or (ma.asset_scope = 'user_profile' and ma.owner_user_id = public.current_user_id())
        )
    )
  );

grant usage on schema public to anon, authenticated, service_role;
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
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
grant execute on function public.create_campaign(text, date, text, date, text) to authenticated, service_role;
grant execute on function public.get_my_campaigns() to authenticated, service_role;
grant execute on function public.get_campaign_membership_summary(uuid) to authenticated, service_role;
grant execute on function public.get_campaign_entity_summaries(uuid) to authenticated, service_role;
grant execute on function public.get_safe_member_profiles(uuid) to authenticated, service_role;
