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

select 'M02 RLS smoke tests passed' as result;
