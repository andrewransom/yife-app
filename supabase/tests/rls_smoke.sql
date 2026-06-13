create or replace function pg_temp.assert_true(condition boolean, message text)
returns void
language plpgsql
as $$
begin
  if not condition then
    raise exception 'assertion failed: %', message;
  end if;
end;
$$;

create or replace function pg_temp.expect_error(statement text, message text)
returns void
language plpgsql
as $$
begin
  execute statement;
  raise exception 'expected error: %', message;
exception
  when others then
    if sqlerrm like 'expected error:%' then
      raise;
    end if;
end;
$$;

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data
)
values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'owner@example.test', 'not-used', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'gm@example.test', 'not-used', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000000', '33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'player@example.test', 'not-used', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000000', '44444444-4444-4444-4444-444444444444', 'authenticated', 'authenticated', 'removed@example.test', 'not-used', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000000', '55555555-5555-5555-5555-555555555555', 'authenticated', 'authenticated', 'stranger@example.test', 'not-used', now(), now(), now(), '{}'::jsonb, '{}'::jsonb)
on conflict (id) do nothing;

select pg_temp.assert_true(count(*) = 3, 'system roles seeded')
from public.role_definitions
where key in ('owner', 'game_master', 'player');

select pg_temp.assert_true(count(*) = 10, 'system entity types seeded')
from public.entity_types
where key in ('character', 'npc', 'party', 'faction', 'location', 'quest', 'session', 'plot_arc', 'encounter', 'timeline_event');

select pg_temp.assert_true(count(*) >= 5, 'system statuses seeded')
from public.status_definitions
where subject_key = 'campaign';

select pg_temp.assert_true(count(*) >= 14, 'system relationship types seeded')
from public.relationship_types;

select pg_temp.assert_true(count(*) >= 4, 'system option definitions seeded')
from public.entity_option_definitions;

select pg_temp.assert_true(not exists (
  select 1
  from information_schema.table_privileges
  where table_schema = 'public'
    and grantee = 'anon'
), 'anon has no direct public table privileges');

select pg_temp.assert_true(not exists (
  select 1
  from information_schema.routine_privileges
  where routine_schema = 'public'
    and lower(grantee) in ('anon', 'public')
), 'anon and public have no public function execute privileges');

select pg_temp.expect_error(
  $$select public.create_campaign('No Auth', current_date)$$,
  'create_campaign rejects unauthenticated callers'
);

select pg_temp.expect_error(
  $$select public.ensure_user_defaults()$$,
  'ensure_user_defaults rejects unauthenticated callers'
);

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select set_config('request.jwt.claim.role', 'authenticated', false);

select pg_temp.assert_true(public.current_user_id() = '11111111-1111-1111-1111-111111111111'::uuid, 'current_user_id reads auth uid');

select *
into temporary table ensured_owner
from public.ensure_user_defaults();

select pg_temp.assert_true(count(*) = 1, 'ensure_user_defaults creates owner profile/settings')
from ensured_owner;

select public.ensure_user_defaults();

select pg_temp.assert_true(count(*) = 1, 'ensure_user_defaults is idempotent for profile')
from public.user_profiles
where user_id = '11111111-1111-1111-1111-111111111111';

select *
into temporary table created_campaign
from public.create_campaign('Smoke Campaign', current_date, 'Test campaign');

select pg_temp.assert_true(status_key = 'planned', 'create_campaign defaults status to planned')
from created_campaign;

select pg_temp.assert_true(array['owner']::text[] <@ role_keys, 'create_campaign returns owner role')
from created_campaign;

reset role;
select set_config('request.jwt.claim.sub', '', false);
select set_config('request.jwt.claim.role', '', false);

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select public.create_campaign('Bad Dates', current_date, null, current_date - 1);
    reset role;$$,
  'create_campaign rejects invalid date ranges'
);
reset role;
select set_config('request.jwt.claim.sub', '', false);

insert into public.user_profiles (user_id, display_name)
values
  ('22222222-2222-2222-2222-222222222222', 'GM'),
  ('33333333-3333-3333-3333-333333333333', 'Player'),
  ('44444444-4444-4444-4444-444444444444', 'Removed'),
  ('55555555-5555-5555-5555-555555555555', 'Stranger')
on conflict (user_id) do nothing;

insert into public.user_settings (user_id)
values
  ('22222222-2222-2222-2222-222222222222'),
  ('33333333-3333-3333-3333-333333333333'),
  ('44444444-4444-4444-4444-444444444444'),
  ('55555555-5555-5555-5555-555555555555')
on conflict (user_id) do nothing;

create temporary table gm_membership as
with inserted as (
  insert into public.campaign_memberships (campaign_id, user_id, status)
  select campaign_id, '22222222-2222-2222-2222-222222222222', 'active'
  from created_campaign
  returning id
)
select id from inserted;

create temporary table player_membership as
with inserted as (
  insert into public.campaign_memberships (campaign_id, user_id, status)
  select campaign_id, '33333333-3333-3333-3333-333333333333', 'active'
  from created_campaign
  returning id
)
select id from inserted;

create temporary table removed_membership as
with inserted as (
  insert into public.campaign_memberships (campaign_id, user_id, status)
  select campaign_id, '44444444-4444-4444-4444-444444444444', 'removed'
  from created_campaign
  returning id
)
select id from inserted;

insert into public.campaign_membership_roles (membership_id, role_id)
select gm_membership.id, rd.id
from gm_membership
join public.role_definitions rd on rd.key = 'game_master';

insert into public.campaign_membership_roles (membership_id, role_id)
select player_membership.id, rd.id
from player_membership
join public.role_definitions rd on rd.key = 'player';

set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select pg_temp.assert_true(public.is_campaign_gm((select campaign_id from created_campaign)), 'active GM helper returns true');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(not public.is_campaign_gm((select campaign_id from created_campaign)), 'player GM helper returns false');
select pg_temp.assert_true(public.is_campaign_member((select campaign_id from created_campaign)), 'active player member helper returns true');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', false);
select pg_temp.assert_true(not public.is_campaign_member((select campaign_id from created_campaign)), 'removed member helper returns false');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', false);
select pg_temp.assert_true(not public.is_campaign_member((select campaign_id from created_campaign)), 'non-member helper returns false');
select pg_temp.assert_true(not exists (select 1 from public.campaigns where id = (select campaign_id from created_campaign)), 'non-member cannot read campaign');
reset role;

select pg_temp.expect_error(
  $$update public.campaign_memberships
    set status = 'removed'
    where campaign_id = (select campaign_id from created_campaign)
      and user_id = '11111111-1111-1111-1111-111111111111'::uuid$$,
  'canonical owner cannot be removed'
);

select pg_temp.expect_error(
  $$delete from public.campaign_membership_roles cmr
    using public.campaign_memberships cm, public.role_definitions rd
    where cmr.membership_id = cm.id
      and cmr.role_id = rd.id
      and cm.campaign_id = (select campaign_id from created_campaign)
      and cm.user_id = '11111111-1111-1111-1111-111111111111'::uuid
      and rd.key = 'owner'$$,
  'canonical owner role cannot be removed'
);

select pg_temp.expect_error(
  $$insert into public.campaign_invitations (campaign_id, email_normalized, invited_by_user_id)
    select campaign_id, 'pending@example.test', '11111111-1111-1111-1111-111111111111'
    from created_campaign;
    insert into public.campaign_invitations (campaign_id, email_normalized, invited_by_user_id)
    select campaign_id, 'pending@example.test', '11111111-1111-1111-1111-111111111111'
    from created_campaign$$,
  'duplicate active invitation is rejected'
);

insert into public.status_definitions (
  subject_key,
  campaign_id,
  key,
  label,
  sort_order,
  is_system,
  created_by,
  updated_by
)
select 'campaign', campaign_id, 'custom_status', 'Custom Status', 900, false, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
from created_campaign;

insert into public.entity_option_definitions (
  entity_type_id,
  campaign_id,
  group_key,
  key,
  label,
  sort_order,
  is_system,
  created_by,
  updated_by
)
select et.id, cc.campaign_id, 'quest_priority', 'campaign_custom', 'Campaign Custom', 900, false, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
from created_campaign cc
join public.entity_types et on et.key = 'quest';

insert into public.relationship_types (
  campaign_id,
  key,
  label,
  inverse_label,
  default_directionality,
  sort_order,
  is_system,
  created_by,
  updated_by
)
select campaign_id, 'campaign_custom', 'Campaign Custom', 'Campaign Custom Inverse', 'directed', 900, false, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
from created_campaign;

create temporary table shared_entity as
with inserted as (
  insert into public.campaign_entities (
    campaign_id,
    entity_type_id,
    list_caption,
    default_visibility,
    created_by,
    updated_by
  )
  select campaign_id, et.id, 'Shared Entity', 'shared', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
  from created_campaign, public.entity_types et
  where et.key = 'npc'
  returning id
)
select id from inserted;

create temporary table gm_entity as
with inserted as (
  insert into public.campaign_entities (
    campaign_id,
    entity_type_id,
    list_caption,
    default_visibility,
    created_by,
    updated_by
  )
  select campaign_id, et.id, 'GM Entity', 'gm_only', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
  from created_campaign, public.entity_types et
  where et.key = 'npc'
  returning id
)
select id from inserted;

create temporary table player_private_entity as
with inserted as (
  insert into public.campaign_entities (
    campaign_id,
    entity_type_id,
    list_caption,
    default_visibility,
    created_by,
    updated_by
  )
  select campaign_id, et.id, 'Player Private Entity', 'private', '33333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333'
  from created_campaign, public.entity_types et
  where et.key = 'timeline_event'
  returning id
)
select id from inserted;

create temporary table deleted_entity as
with inserted as (
  insert into public.campaign_entities (
    campaign_id,
    entity_type_id,
    list_caption,
    default_visibility,
    created_by,
    updated_by,
    deleted_at
  )
  select campaign_id, et.id, 'Deleted Entity', 'shared', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', now()
  from created_campaign, public.entity_types et
  where et.key = 'npc'
  returning id
)
select id from inserted;

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(exists (
  select 1 from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where list_caption = 'Shared Entity'
), 'player can read shared entity summary');
select pg_temp.assert_true(not exists (
  select 1 from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where list_caption = 'GM Entity'
), 'player cannot read GM-only entity summary');
select pg_temp.assert_true(exists (
  select 1 from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where list_caption = 'Player Private Entity'
), 'creator can read own private entity summary');
select pg_temp.assert_true(not exists (
  select 1 from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where list_caption = 'Deleted Entity'
), 'entity summaries exclude soft-deleted entities');
select pg_temp.assert_true(not exists (
  select 1 from public.campaign_entities
  where campaign_id = (select campaign_id from created_campaign)
    and list_caption = 'Deleted Entity'
), 'direct entity reads exclude soft-deleted entities');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select pg_temp.assert_true(exists (
  select 1 from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where list_caption = 'GM Entity'
), 'GM can read GM-only entity summary');
update public.campaign_entities
set default_visibility = 'shared',
    updated_by = '22222222-2222-2222-2222-222222222222'
where campaign_id = (select campaign_id from created_campaign)
  and list_caption = 'Player Private Entity';
reset role;

select pg_temp.assert_true(default_visibility = 'private', 'GM direct update cannot expose private entity rows')
from public.campaign_entities
where campaign_id = (select campaign_id from created_campaign)
  and list_caption = 'Player Private Entity';

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    insert into public.campaign_entities (
      campaign_id,
      entity_type_id,
      list_caption,
      default_visibility,
      created_by,
      updated_by
    )
    select campaign_id, et.id, 'Direct Insert Blocked', 'shared', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
    from created_campaign, public.entity_types et
    where et.key = 'npc'$$,
  'direct campaign entity inserts are reserved for typed RPCs'
);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', false);
select pg_temp.assert_true(not exists (
  select 1 from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
), 'removed member cannot read entity summaries');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(not exists (
  select 1 from public.user_settings
  where user_id = '11111111-1111-1111-1111-111111111111'::uuid
), 'co-member cannot read user settings');
select pg_temp.assert_true(exists (
  select 1 from public.get_safe_member_profiles((select campaign_id from created_campaign))
  where user_id = '11111111-1111-1111-1111-111111111111'::uuid
), 'co-member can read safe profile surface');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(exists (
  select 1 from public.status_definitions
  where campaign_id = (select campaign_id from created_campaign)
    and key = 'custom_status'
), 'member can read campaign-scoped status rows');
select pg_temp.assert_true(exists (
  select 1 from public.entity_option_definitions
  where campaign_id = (select campaign_id from created_campaign)
    and key = 'campaign_custom'
), 'member can read campaign-scoped option rows');
select pg_temp.assert_true(exists (
  select 1 from public.relationship_types
  where campaign_id = (select campaign_id from created_campaign)
    and key = 'campaign_custom'
), 'member can read campaign-scoped relationship rows');
update public.status_definitions set label = 'Mutated' where subject_key = 'campaign' and key = 'planned';
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', false);
select pg_temp.assert_true(not exists (
  select 1 from public.status_definitions
  where campaign_id = (select campaign_id from created_campaign)
), 'removed member cannot read campaign-scoped status rows');
select pg_temp.assert_true(not exists (
  select 1 from public.entity_option_definitions
  where campaign_id = (select campaign_id from created_campaign)
), 'removed member cannot read campaign-scoped option rows');
select pg_temp.assert_true(not exists (
  select 1 from public.relationship_types
  where campaign_id = (select campaign_id from created_campaign)
), 'removed member cannot read campaign-scoped relationship rows');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', false);
select pg_temp.assert_true(not exists (
  select 1 from public.status_definitions
  where campaign_id = (select campaign_id from created_campaign)
), 'non-member cannot read campaign-scoped status rows');
select pg_temp.assert_true(not exists (
  select 1 from public.entity_option_definitions
  where campaign_id = (select campaign_id from created_campaign)
), 'non-member cannot read campaign-scoped option rows');
select pg_temp.assert_true(not exists (
  select 1 from public.relationship_types
  where campaign_id = (select campaign_id from created_campaign)
), 'non-member cannot read campaign-scoped relationship rows');
reset role;

select pg_temp.assert_true(label = 'Planned', 'system default rows are not mutable by normal app users')
from public.status_definitions
where subject_key = 'campaign'
  and key = 'planned'
  and campaign_id is null;

create temporary table media_asset as
with inserted as (
  insert into public.media_assets (
    campaign_id,
    asset_scope,
    status,
    title,
    alt_text,
    created_by,
    updated_by
  )
  select campaign_id, 'campaign', 'uploading', 'Hidden raw title', 'Visible campaign image', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
  from created_campaign
  returning id
)
select id from inserted;

select pg_temp.expect_error(
  $$update public.media_assets
    set status = 'ready'
    where id = (select id from media_asset)$$,
  'ready media assets require variants'
);

select pg_temp.expect_error(
  $$insert into public.media_asset_variants (
      media_asset_id,
      variant,
      storage_bucket,
      storage_path,
      width,
      height,
      format,
      mime_type,
      byte_size,
      version_key
    )
    select id, 'original_1600', 'yife-images', 'campaigns/test/original_blocked.webp', 1600, 1200, 'webp', 'image/webp', 8192, 'v1'
    from media_asset$$,
  'original_1600 variants require retained originals'
);

update public.media_assets
set retain_original = true
where id = (select id from media_asset);

insert into public.media_asset_variants (
  media_asset_id,
  variant,
  storage_bucket,
  storage_path,
  width,
  height,
  format,
  mime_type,
  byte_size,
  version_key
)
select id, 'original_1600', 'yife-images', 'campaigns/test/original_1600.webp', 1600, 1200, 'webp', 'image/webp', 8192, 'v1'
from media_asset;

select pg_temp.expect_error(
  $$update public.media_assets
    set retain_original = false
    where id = (select id from media_asset)$$,
  'assets with original_1600 variants must retain originals'
);

insert into public.media_asset_variants (
  media_asset_id,
  variant,
  storage_bucket,
  storage_path,
  width,
  height,
  format,
  mime_type,
  byte_size,
  version_key
)
select id, 'thumb_160', 'yife-images', 'campaigns/test/thumb_160.webp', 160, 160, 'webp', 'image/webp', 1024, 'v1'
from media_asset;

insert into public.media_asset_variants (
  media_asset_id,
  variant,
  storage_bucket,
  storage_path,
  width,
  height,
  format,
  mime_type,
  byte_size,
  version_key
)
select id, 'grid_480', 'yife-images', 'campaigns/test/grid_480.webp', 480, 480, 'webp', 'image/webp', 4096, 'v1'
from media_asset;

update public.media_assets
set status = 'ready'
where id = (select id from media_asset);

update public.campaigns
set image_asset_id = (select id from media_asset)
where id = (select campaign_id from created_campaign);

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(not exists (
  select 1 from public.media_assets
  where title = 'Hidden raw title'
), 'player cannot directly read raw campaign media metadata');
select pg_temp.assert_true(exists (
  select 1 from public.get_my_campaigns()
  where campaign_id = (select campaign_id from created_campaign)
    and primary_image_thumb_path = 'campaigns/test/thumb_160.webp'
), 'safe campaign list exposes visible primary image metadata');
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select pg_temp.assert_true(exists (
  select 1 from public.get_my_campaigns()
  where campaign_id = (select campaign_id from created_campaign)
    and 'owner' = any(role_keys)
), 'owner campaign list includes role and status fields');
reset role;

create temporary table created_m04_entities (
  entity_type_key text primary key,
  entity_id uuid not null
);
grant all on created_m04_entities to authenticated;

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'character',
  jsonb_build_object(
    'name', 'Aria Vale',
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'character' and sd.key = 'active' and sd.campaign_id is null
    ),
    'controlling_user_id', '33333333-3333-3333-3333-333333333333'
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'npc',
  jsonb_build_object(
    'name', 'Mira the Broker',
    'real_status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'npc' and sd.key = 'alive' and sd.campaign_id is null
    )
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'party',
  jsonb_build_object('name', 'The Lantern Company')
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'faction',
  jsonb_build_object(
    'name', 'Harbor Guild',
    'status_id', null
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'location',
  jsonb_build_object(
    'name', 'Saltwind Docks',
    'location_type_option_id', (
      select eod.id from public.entity_option_definitions eod
      join public.entity_types et on et.id = eod.entity_type_id
      where et.key = 'location' and eod.group_key = 'location_type' and eod.key = 'district'
    )
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'quest',
  jsonb_build_object(
    'title', 'Find the Ember Map',
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'quest' and sd.key = 'open' and sd.campaign_id is null
    ),
    'priority_option_id', (
      select eod.id from public.entity_option_definitions eod
      join public.entity_types et on et.id = eod.entity_type_id
      where et.key = 'quest' and eod.group_key = 'quest_priority' and eod.key = 'high'
    ),
    'is_major', true
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'session',
  jsonb_build_object(
    'title', 'Session 1',
    'session_date', current_date,
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'session' and sd.key = 'planned' and sd.campaign_id is null
    )
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'plot_arc',
  jsonb_build_object(
    'title', 'The Ash Crown',
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'plot_arc' and sd.key = 'planned' and sd.campaign_id is null
    )
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'encounter',
  jsonb_build_object(
    'title', 'Dockside Ambush',
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'encounter' and sd.key = 'planned' and sd.campaign_id is null
    ),
    'encounter_type_option_id', (
      select eod.id from public.entity_option_definitions eod
      join public.entity_types et on et.id = eod.entity_type_id
      where et.key = 'encounter' and eod.group_key = 'encounter_type' and eod.key = 'combat'
    ),
    'related_session_entity_id', (
      select entity_id from created_m04_entities where entity_type_key = 'session'
    ),
    'related_plot_arc_entity_id', (
      select entity_id from created_m04_entities where entity_type_key = 'plot_arc'
    )
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'timeline_event',
  jsonb_build_object(
    'title', 'The Beacon Falls',
    'date_expression', 'Three winters ago',
    'sort_key', '0003-winter',
    'event_type_option_id', (
      select eod.id from public.entity_option_definitions eod
      join public.entity_types et on et.id = eod.entity_type_id
      where et.key = 'timeline_event' and eod.group_key = 'timeline_event_type' and eod.key = 'campaign_event'
    ),
    'related_session_entity_id', (
      select entity_id from created_m04_entities where entity_type_key = 'session'
    )
  )
);

select pg_temp.assert_true(count(*) = 10, 'owner can create all M04 entity types')
from created_m04_entities;

select pg_temp.assert_true(not exists (
  select 1
  from created_m04_entities cme
  where not exists (
    select 1 from public.entity_sections es where es.entity_id = cme.entity_id
  )
), 'typed creation creates default section rows');

select pg_temp.assert_true(default_visibility = 'gm_only', 'plot arcs default GM-only')
from public.campaign_entities
where id = (select entity_id from created_m04_entities where entity_type_key = 'plot_arc');

select pg_temp.assert_true(n.apparent_status_id = n.real_status_id, 'NPC apparent status defaults to real status')
from public.npcs n
where n.entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc');

select pg_temp.assert_true(exists (
  select 1
  from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'quest')
    and quest_priority_label = 'High'
    and is_major
), 'safe summaries include dense type-specific metadata');

select entity_id
into temporary table hidden_reference_faction
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'faction',
  jsonb_build_object(
    'name', 'Hidden Faction',
    'default_visibility', 'gm_only'
  )
);

select entity_id
into temporary table npc_with_hidden_reference
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'npc',
  jsonb_build_object(
    'name', 'Public Contact',
    'real_status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'npc' and sd.key = 'alive' and sd.campaign_id is null
    ),
    'faction_entity_id', (select entity_id from hidden_reference_faction)
  )
);

reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'party',
      jsonb_build_object('name', 'Player Party')
    );
    reset role;$$,
  'players cannot create typed campaign entities'
);
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'party',
      jsonb_build_object('name', 'Stranger Party')
    );
    reset role;$$,
  'non-members cannot create typed campaign entities'
);
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'character',
      jsonb_build_object(
        'name', 'Removed Controller',
        'status_id', (
          select sd.id from public.status_definitions sd
          join public.entity_types et on et.id = sd.entity_type_id
          where et.key = 'character' and sd.key = 'active' and sd.campaign_id is null
        ),
        'controlling_user_id', '44444444-4444-4444-4444-444444444444'
      )
    );
    reset role;$$,
  'character controlling users must be active members'
);
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'quest',
      jsonb_build_object(
        'title', 'Bad Status',
        'status_id', (
          select sd.id from public.status_definitions sd
          join public.entity_types et on et.id = sd.entity_type_id
          where et.key = 'character' and sd.key = 'active' and sd.campaign_id is null
        )
      )
    );
    reset role;$$,
  'wrong-entity-type statuses are rejected'
);
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'location',
      jsonb_build_object(
        'name', 'Bad Option',
        'location_type_option_id', (
          select eod.id from public.entity_option_definitions eod
          join public.entity_types et on et.id = eod.entity_type_id
          where et.key = 'encounter' and eod.group_key = 'encounter_type' and eod.key = 'combat'
        )
      )
    );
    reset role;$$,
  'wrong-group options are rejected'
);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
update public.campaign_entity_type_settings cets
set is_enabled = false
from public.entity_types et
where cets.entity_type_id = et.id
  and cets.campaign_id = (select campaign_id from created_campaign)
  and et.key = 'party';
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'party',
      jsonb_build_object('name', 'Disabled Party')
    );
    reset role;$$,
  'disabled campaign entity types cannot be created'
);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select *
into temporary table other_campaign
from public.create_campaign('Other Campaign', current_date, null);

select entity_id
into temporary table other_location
from public.create_campaign_entity(
  (select campaign_id from other_campaign),
  'location',
  jsonb_build_object(
    'name', 'Other Docks',
    'location_type_option_id', (
      select eod.id from public.entity_option_definitions eod
      join public.entity_types et on et.id = eod.entity_type_id
      where et.key = 'location' and eod.group_key = 'location_type' and eod.key = 'district'
    )
  )
);
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'location',
      jsonb_build_object(
        'name', 'Cross Campaign Child',
        'location_type_option_id', (
          select eod.id from public.entity_option_definitions eod
          join public.entity_types et on et.id = eod.entity_type_id
          where et.key = 'location' and eod.group_key = 'location_type' and eod.key = 'district'
        ),
        'parent_location_entity_id', (select entity_id from other_location)
      )
    );
    reset role;$$,
  'cross-campaign structural references are rejected'
);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(exists (
  select 1
  from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
), 'player summary reads include shared created records');
select pg_temp.assert_true(not exists (
  select 1
  from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'encounter')
), 'player summary reads omit GM-only records');
select pg_temp.assert_true(not exists (
  select 1
  from public.npcs
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
), 'players cannot read raw NPC detail rows');
select pg_temp.assert_true(npc_real_status_label is null, 'player-safe NPC detail omits real status')
from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'npc'));
select pg_temp.assert_true(
  parent_entity_id is null and parent_entity_label is null,
  'player summaries hide inaccessible structural reference ids and labels'
)
from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
where entity_id = (select entity_id from npc_with_hidden_reference);
select pg_temp.assert_true(not exists (
  select 1
  from public.entity_sections
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
    and section_key = 'gm_details'
), 'section RLS hides GM-only sections from players');
reset role;

select 'M04 RLS smoke tests passed' as result;
