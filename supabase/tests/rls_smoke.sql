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

select pg_temp.assert_true(count(*) = 9, 'active system entity types seeded')
from public.entity_types
where key in ('character', 'npc', 'party', 'faction', 'location', 'storyline', 'session', 'encounter', 'timeline_event')
  and is_active;

select pg_temp.assert_true(not exists (
  select 1
  from public.entity_types
  where key in ('quest', 'plot_arc')
    and is_active
), 'quest and plot arc entity types are inactive');

select pg_temp.assert_true(count(*) >= 5, 'system statuses seeded')
from public.status_definitions
where subject_key = 'campaign';

select pg_temp.assert_true(count(*) >= 14, 'system relationship types seeded')
from public.relationship_types;

select pg_temp.assert_true(not exists (
  select 1
  from information_schema.tables
  where table_schema = 'public'
    and table_name = 'entity_option_definitions'
), 'legacy entity option definitions table is removed from active schema');

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

select pg_temp.assert_true(timezone = 'UTC', 'create_campaign defaults campaign timezone')
from public.campaigns
where id = (select campaign_id from created_campaign);

select pg_temp.assert_true(exists (
  select 1
  from public.entity_types
  where key = 'storyline'
    and is_active
), 'storyline entity type is seeded');

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['open', 'active', 'completed', 'resolved', 'failed', 'abandoned']::text[], 'storyline statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'storyline'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['active', 'retired', 'dead', 'missing', 'inactive']::text[], 'character statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'character'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['unused', 'seeded', 'active', 'resolved', 'retired']::text[], 'character hook statuses match 04.5')
from public.status_definitions sd
where sd.subject_key = 'character_hook'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['active', 'inactive', 'disbanded', 'former', 'temporary']::text[], 'party statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'party'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['alive', 'dead', 'missing', 'unknown', 'inactive']::text[], 'npc statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'npc'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['active', 'inactive', 'collapsed', 'unknown']::text[], 'faction statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'faction'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['active', 'ruined', 'abandoned', 'destroyed', 'unknown']::text[], 'location statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'location'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['planned', 'completed', 'cancelled']::text[], 'session statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'session'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['planned', 'ready', 'completed', 'skipped', 'archived']::text[], 'encounter statuses match 04.5')
from public.status_definitions sd
join public.entity_types et on et.id = sd.entity_type_id
where et.key = 'encounter'
  and sd.subject_key = 'entity'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(array_agg(sd.key order by sd.sort_order) = array['active', 'inactive', 'lost', 'consumed', 'archived']::text[], 'resource statuses match 04.5')
from public.status_definitions sd
where sd.subject_key = 'entity_resource'
  and sd.campaign_id is null
  and sd.is_active;

select pg_temp.assert_true(count(*) >= 15, 'preset import copies campaign option groups')
from public.campaign_option_groups
where campaign_id = (select campaign_id from created_campaign);

select pg_temp.assert_true(exists (
  select 1
  from public.get_campaign_options((select campaign_id from created_campaign), 'storyline_priority')
  where key = 'high'
    and default_palette_color_id is not null
), 'preset import maps option default palette references to campaign rows');

select pg_temp.assert_true(exists (
  select 1
  from public.get_campaign_options((select campaign_id from created_campaign), 'storyline_category')
  where key = 'main'
    and default_symbol_id is not null
    and default_symbol_icon_key = 'scroll-text'
), 'preset import maps option default symbol references to campaign rows');

select pg_temp.assert_true(count(*) = 2, 'preset import copies active quick stat templates')
from public.campaign_quick_stat_templates
where campaign_id = (select campaign_id from created_campaign)
  and is_active;

select pg_temp.expect_error(
  $$select public.require_campaign_option(
      (select campaign_id from created_campaign),
      'storyline_priority',
      (select co.id
       from public.campaign_options co
       join public.campaign_option_groups cog on cog.id = co.group_id
       where cog.campaign_id = (select campaign_id from created_campaign)
         and cog.key = 'location_type'
         and co.key = 'city'),
      true
    )$$,
  'campaign option validation rejects wrong option group'
);

select *
into temporary table second_campaign
from public.create_campaign('Second Smoke Campaign', current_date, null, null, 'planned');

select pg_temp.expect_error(
  $$select public.require_campaign_option(
      (select campaign_id from created_campaign),
      'storyline_priority',
      (select co.id
       from public.campaign_options co
       join public.campaign_option_groups cog on cog.id = co.group_id
       where cog.campaign_id = (select campaign_id from second_campaign)
         and cog.key = 'storyline_priority'
         and co.key = 'high'),
      true
    )$$,
  'campaign option validation rejects wrong campaign'
);

update public.campaign_options
set is_active = false
where id = (
  select co.id
  from public.campaign_options co
  join public.campaign_option_groups cog on cog.id = co.group_id
  where cog.campaign_id = (select campaign_id from created_campaign)
    and cog.key = 'storyline_priority'
    and co.key = 'urgent'
);

select pg_temp.expect_error(
  $$select public.require_campaign_option(
      (select campaign_id from created_campaign),
      'storyline_priority',
      (select co.id
       from public.campaign_options co
       join public.campaign_option_groups cog on cog.id = co.group_id
       where cog.campaign_id = (select campaign_id from created_campaign)
         and cog.key = 'storyline_priority'
         and co.key = 'urgent'),
      true
    )$$,
  'campaign option validation rejects inactive options'
);

update public.campaign_options
set is_active = true
where id = (
  select co.id
  from public.campaign_options co
  join public.campaign_option_groups cog on cog.id = co.group_id
  where cog.campaign_id = (select campaign_id from created_campaign)
    and cog.key = 'storyline_priority'
    and co.key = 'urgent'
);

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

insert into public.campaign_option_groups (
  campaign_id,
  key,
  label,
  description,
  sort_order,
  created_by,
  updated_by
)
select campaign_id, 'custom_test_group', 'Custom Test Group', null, 900, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
from created_campaign;

insert into public.campaign_options (
  campaign_id,
  group_id,
  key,
  label,
  sort_order,
  created_by,
  updated_by
)
select cc.campaign_id, cog.id, 'campaign_custom', 'Campaign Custom', 900, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
from created_campaign cc
join public.campaign_option_groups cog on cog.campaign_id = cc.campaign_id and cog.key = 'custom_test_group';

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

grant all on shared_entity to authenticated;
grant all on gm_entity to authenticated;
grant all on player_private_entity to authenticated;

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
  select 1
  from public.campaign_options co
  join public.campaign_option_groups cog on cog.id = co.group_id
  where co.campaign_id = (select campaign_id from created_campaign)
    and cog.key = 'custom_test_group'
    and co.key = 'campaign_custom'
), 'member can read campaign-scoped campaign option rows');
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
  select 1 from public.campaign_options
  where campaign_id = (select campaign_id from created_campaign)
), 'removed member cannot read campaign-scoped campaign option rows');
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
  select 1 from public.campaign_options
  where campaign_id = (select campaign_id from created_campaign)
), 'non-member cannot read campaign-scoped campaign option rows');
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
select id, 'original_1600', 'yife-images', 'campaigns/test/' || id::text || '/original_1600.webp', 1600, 1200, 'webp', 'image/webp', 8192, 'v1'
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
select id, 'thumb_160', 'yife-images', 'campaigns/test/' || id::text || '/thumb_160.webp', 160, 160, 'webp', 'image/webp', 1024, 'v1'
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
select id, 'grid_480', 'yife-images', 'campaigns/test/' || id::text || '/grid_480.webp', 480, 480, 'webp', 'image/webp', 4096, 'v1'
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
    and primary_image_thumb_path like 'campaigns/test/%/thumb_160.webp'
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

create temporary table ordinary_player_membership as
with inserted as (
  insert into public.campaign_memberships (campaign_id, user_id, status)
  select campaign_id, '55555555-5555-5555-5555-555555555555', 'active'
  from created_campaign
  returning id
)
select id from inserted;

insert into public.campaign_membership_roles (membership_id, role_id)
select ordinary_player_membership.id, rd.id
from ordinary_player_membership
join public.role_definitions rd on rd.key = 'player';

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
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from created_campaign)
        and cog.key = 'location_type'
        and co.key = 'district'
    )
  )
);

insert into created_m04_entities
select entity_type_key, entity_id
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'storyline',
  jsonb_build_object(
    'title', 'Find the Ember Map',
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'storyline' and sd.key = 'open' and sd.campaign_id is null
    ),
    'storyline_type', 'quest',
    'priority_option_id', (
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from created_campaign)
        and cog.key = 'storyline_priority'
        and co.key = 'high'
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
  'encounter',
  jsonb_build_object(
    'title', 'Dockside Ambush',
    'status_id', (
      select sd.id from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'encounter' and sd.key = 'planned' and sd.campaign_id is null
    ),
    'encounter_type_option_id', (
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from created_campaign)
        and cog.key = 'encounter_type'
        and co.key = 'combat'
    ),
    'related_session_entity_id', (
      select entity_id from created_m04_entities where entity_type_key = 'session'
    ),
    'related_storyline_entity_id', (
      select entity_id from created_m04_entities where entity_type_key = 'storyline'
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
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from created_campaign)
        and cog.key = 'timeline_event_type'
        and co.key = 'campaign_event'
    ),
    'related_session_entity_id', (
      select entity_id from created_m04_entities where entity_type_key = 'session'
    )
  )
);

select pg_temp.assert_true(count(*) = 9, 'owner can create active M04 entity types')
from created_m04_entities;

select pg_temp.assert_true(not exists (
  select 1
  from created_m04_entities cme
  where not exists (
    select 1 from public.entity_sections es where es.entity_id = cme.entity_id
  )
), 'typed creation creates default section rows');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['backstory', 'details', 'gm_notes', 'journal']::text[], 'character default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['details', 'gm_details']::text[], 'npc default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['details', 'gm_notes']::text[], 'party default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'party');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['details', 'gm_details']::text[], 'faction default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'faction');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['details', 'gm_details']::text[], 'location default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'location');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['details', 'gm_details']::text[], 'storyline default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'storyline');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['gm_prep', 'gm_private_notes', 'session_notes']::text[], 'session default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'session');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['gm_prep', 'outcomes']::text[], 'encounter default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'encounter');

select pg_temp.assert_true(array_agg(section_key order by section_key) = array['details', 'gm_details']::text[], 'timeline event default sections match 04.5')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'timeline_event');

select pg_temp.assert_true(visibility = 'gm_only', 'encounter outcomes default GM-only')
from public.entity_sections
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'encounter')
  and section_key = 'outcomes';

select pg_temp.assert_true(default_visibility = 'shared', 'storylines default shared')
from public.campaign_entities
where id = (select entity_id from created_m04_entities where entity_type_key = 'storyline');

select pg_temp.assert_true(n.apparent_status_id = n.real_status_id, 'NPC apparent status defaults to real status')
from public.npcs n
where n.entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc');

reset role;

insert into public.character_class_progressions (
  campaign_id,
  character_entity_id,
  class_name,
  level_number,
  created_by,
  updated_by
)
select (select campaign_id from created_campaign), entity_id, 'Ranger', 3, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
from created_m04_entities
where entity_type_key = 'character';

insert into public.character_hooks (
  campaign_id,
  character_entity_id,
  description_text,
  status_id,
  visibility,
  promoted_storyline_entity_id,
  created_by,
  updated_by
)
select
  (select campaign_id from created_campaign),
  (select entity_id from created_m04_entities where entity_type_key = 'character'),
  'Dreams of the Ember Map',
  (
    select sd.id
    from public.status_definitions sd
    where sd.subject_key = 'character_hook'
      and sd.key = 'seeded'
      and sd.campaign_id is null
  ),
  'character_owner_gm',
  (select entity_id from created_m04_entities where entity_type_key = 'storyline'),
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111';

create temporary table created_hook as
with inserted as (
  insert into public.character_hooks (
    campaign_id,
    character_entity_id,
    description_text,
    status_id,
    visibility,
    created_by,
    updated_by
  )
  select
    (select campaign_id from created_campaign),
    (select entity_id from created_m04_entities where entity_type_key = 'character'),
    'Recover the missing chart',
    (
      select sd.id
      from public.status_definitions sd
      where sd.subject_key = 'character_hook'
        and sd.key = 'active'
        and sd.campaign_id is null
    ),
    'character_owner_gm',
    '11111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111'
  returning id
)
select id from inserted;
grant all on created_hook to authenticated;

insert into public.party_members (
  party_entity_id,
  character_entity_id,
  role_label,
  created_by,
  updated_by
)
values (
  (select entity_id from created_m04_entities where entity_type_key = 'party'),
  (select entity_id from created_m04_entities where entity_type_key = 'character'),
  'Scout',
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111'
);

create temporary table encounter_statblock as
with inserted as (
  insert into public.encounter_statblocks (
    campaign_id,
    encounter_entity_id,
    linked_npc_entity_id,
    label,
    created_by,
    updated_by
  )
  values (
    (select campaign_id from created_campaign),
    (select entity_id from created_m04_entities where entity_type_key = 'encounter'),
    (select entity_id from created_m04_entities where entity_type_key = 'npc'),
    'Dock Thug',
    '11111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111'
  )
  returning id
)
select id from inserted;

insert into public.encounter_statblock_values (
  campaign_id,
  encounter_statblock_id,
  field_id,
  value_number,
  created_by,
  updated_by
)
select
  (select campaign_id from created_campaign),
  (select id from encounter_statblock),
  cqsf.id,
  12,
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111'
from public.campaign_quick_stat_fields cqsf
join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
where cqsf.campaign_id = (select campaign_id from created_campaign)
  and cqst.template_kind = 'npc_statblock'
  and cqsf.key = 'max_hp';

insert into public.encounter_statblock_instances (
  campaign_id,
  encounter_statblock_id,
  label,
  current_hp,
  created_by,
  updated_by
)
values (
  (select campaign_id from created_campaign),
  (select id from encounter_statblock),
  'Dock Thug 1',
  12,
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111'
);

select pg_temp.assert_true(count(*) = 1, 'character class progression child table accepts valid character ref')
from public.character_class_progressions
where character_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character');

select pg_temp.assert_true(count(*) = 1, 'character hook child table accepts valid character and storyline refs')
from public.character_hooks
where promoted_storyline_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'storyline');

select pg_temp.assert_true(count(*) = 1, 'party member child table accepts valid party and character refs')
from public.party_members
where party_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'party');

select pg_temp.assert_true(count(*) = 1, 'encounter statblock child tables accept valid rows')
from public.encounter_statblock_instances
where encounter_statblock_id = (select id from encounter_statblock);

select pg_temp.expect_error(
  $$insert into public.party_members (
      party_entity_id,
      character_entity_id,
      created_by,
      updated_by
    )
    values (
      (select entity_id from created_m04_entities where entity_type_key = 'npc'),
      (select entity_id from created_m04_entities where entity_type_key = 'character'),
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    )$$,
  'party member validation rejects wrong parent entity type'
);

select pg_temp.expect_error(
  $$insert into public.encounter_statblocks (
      campaign_id,
      encounter_entity_id,
      linked_npc_entity_id,
      label,
      created_by,
      updated_by
    )
    values (
      (select campaign_id from created_campaign),
      (select entity_id from created_m04_entities where entity_type_key = 'encounter'),
      (select entity_id from created_m04_entities where entity_type_key = 'location'),
      'Bad Linked NPC',
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    )$$,
  'encounter statblock validation rejects wrong linked NPC type'
);

select pg_temp.expect_error(
  $$update public.npcs
    set role_option_id = (
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from created_campaign)
        and cog.key = 'faction_type'
        and co.key = 'guild'
    )
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')$$,
  'NPC role option validation rejects wrong option group'
);

select pg_temp.expect_error(
  $$update public.locations
    set terrain_option_id = (
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from created_campaign)
        and cog.key = 'location_type'
        and co.key = 'city'
    )
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'location')$$,
  'Location terrain option validation rejects wrong option group'
);

select pg_temp.expect_error(
  $$insert into public.encounter_statblock_values (
      campaign_id,
      encounter_statblock_id,
      field_id,
      value_text,
      created_by,
      updated_by
    )
    select
      (select campaign_id from created_campaign),
      (select id from encounter_statblock),
      cqsf.id,
      'twelve',
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    from public.campaign_quick_stat_fields cqsf
    join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
    where cqsf.campaign_id = (select campaign_id from created_campaign)
      and cqst.template_kind = 'npc_statblock'
      and cqsf.key = 'current_hp'$$,
  'encounter statblock values reject text in number fields'
);

select pg_temp.expect_error(
  $$update public.campaign_quick_stat_fields
    set default_visibility = 'shared'
    where id = (
      select cqsf.id
      from public.campaign_quick_stat_fields cqsf
      join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
      where cqsf.campaign_id = (select campaign_id from created_campaign)
        and cqst.template_kind = 'npc_statblock'
      order by cqsf.sort_order
      limit 1
    )$$,
  'npc statblock fields enforce gm_only visibility'
);

select pg_temp.expect_error(
  $$update public.factions
    set numbers_visibility = 'character_owner_gm'
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'faction')$$,
  'faction allowlisted field visibility rejects unsupported visibility'
);

select pg_temp.expect_error(
  $$update public.locations
    set controlling_faction_visibility = 'private'
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'location')$$,
  'location allowlisted field visibility rejects unsupported visibility'
);

update public.campaign_options
set is_active = false
where id = (
  select co.id
  from public.campaign_options co
  join public.campaign_option_groups cog on cog.id = co.group_id
  where cog.campaign_id = (select campaign_id from created_campaign)
    and cog.key = 'hook_category'
    and co.key = 'secret'
);

select pg_temp.expect_error(
  $$insert into public.character_hooks (
      campaign_id,
      character_entity_id,
      description_text,
      status_id,
      category_option_id,
      visibility,
      created_by,
      updated_by
    )
    values (
      (select campaign_id from created_campaign),
      (select entity_id from created_m04_entities where entity_type_key = 'character'),
      'Inactive hook category',
      (
        select sd.id
        from public.status_definitions sd
        where sd.subject_key = 'character_hook'
          and sd.key = 'seeded'
          and sd.campaign_id is null
      ),
      (
        select co.id
        from public.campaign_options co
        join public.campaign_option_groups cog on cog.id = co.group_id
        where cog.campaign_id = (select campaign_id from created_campaign)
          and cog.key = 'hook_category'
          and co.key = 'secret'
      ),
      'shared',
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    )$$,
  'character hook category validation rejects inactive options'
);

update public.campaign_options
set is_active = true
where id = (
  select co.id
  from public.campaign_options co
  join public.campaign_option_groups cog on cog.id = co.group_id
  where cog.campaign_id = (select campaign_id from created_campaign)
    and cog.key = 'hook_category'
    and co.key = 'secret'
);

select pg_temp.expect_error(
  $$insert into public.character_hooks (
      campaign_id,
      character_entity_id,
      description_text,
      status_id,
      category_option_id,
      visibility,
      created_by,
      updated_by
    )
    values (
      (select campaign_id from created_campaign),
      (select entity_id from created_m04_entities where entity_type_key = 'character'),
      'Wrong hook category group',
      (
        select sd.id
        from public.status_definitions sd
        where sd.subject_key = 'character_hook'
          and sd.key = 'seeded'
          and sd.campaign_id is null
      ),
      (
        select co.id
        from public.campaign_options co
        join public.campaign_option_groups cog on cog.id = co.group_id
        where cog.campaign_id = (select campaign_id from created_campaign)
          and cog.key = 'storyline_priority'
          and co.key = 'high'
      ),
      'shared',
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    )$$,
  'character hook category validation rejects wrong option group'
);

update public.campaign_palette_colors
set is_active = false
where campaign_id = (select campaign_id from created_campaign)
  and key = 'blue';

select pg_temp.expect_error(
  $$update public.parties
    set palette_color_id = (
      select id
      from public.campaign_palette_colors
      where campaign_id = (select campaign_id from created_campaign)
        and key = 'blue'
    )
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'party')$$,
  'typed palette validation rejects inactive colors'
);

update public.campaign_palette_colors
set is_active = true
where campaign_id = (select campaign_id from created_campaign)
  and key = 'blue';

update public.campaign_symbols
set is_active = false
where campaign_id = (select campaign_id from created_campaign)
  and key = 'storyline';

select pg_temp.expect_error(
  $$update public.storylines
    set symbol_id = (
      select id
      from public.campaign_symbols
      where campaign_id = (select campaign_id from created_campaign)
        and key = 'storyline'
    )
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'storyline')$$,
  'typed symbol validation rejects inactive symbols'
);

update public.campaign_symbols
set is_active = true
where campaign_id = (select campaign_id from created_campaign)
  and key = 'storyline';

reset role;
update public.campaign_entities
set core_edit_policy = 'owner_edit',
    default_visibility = 'character_owner_gm'
where id = (select entity_id from created_m04_entities where entity_type_key = 'character');
update public.npcs
set public_summary = 'Known smuggler contact',
    gm_summary = 'Actually reporting to the hidden faction'
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc');
update public.campaign_entities
set core_edit_policy = 'owner_edit'
where id = (select id from player_private_entity);
update public.entity_sections
set visibility = 'character_owner_gm'
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
  and section_key = 'backstory';
insert into public.entity_quick_stat_values (
  campaign_id,
  entity_id,
  field_id,
  value_number,
  visibility,
  created_by,
  updated_by
)
select
  (select campaign_id from created_campaign),
  (select entity_id from created_m04_entities where entity_type_key = 'character'),
  cqsf.id,
  5,
  'character_owner_gm',
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111'
from public.campaign_quick_stat_fields cqsf
join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
where cqsf.campaign_id = (select campaign_id from created_campaign)
  and cqst.template_kind = 'character'
  and cqsf.key = 'level';
insert into public.entity_quick_stat_values (
  campaign_id,
  entity_id,
  field_id,
  value_number,
  visibility,
  created_by,
  updated_by
)
select
  (select campaign_id from created_campaign),
  (select id from player_private_entity),
  cqsf.id,
  9,
  'shared',
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111'
from public.campaign_quick_stat_fields cqsf
join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
where cqsf.campaign_id = (select campaign_id from created_campaign)
  and cqst.template_kind = 'character'
  and cqsf.key = 'level';

reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select pg_temp.assert_true(public.can_view_campaign_entity((select entity_id from created_m04_entities where entity_type_key = 'character')), 'Character controller can view character_owner_gm entity data');
select pg_temp.assert_true(exists (
  select 1 from public.get_entity_type_options((select campaign_id from created_campaign))
  where entity_type_key = 'storyline'
    and can_create
), 'active players can create Storylines');
select pg_temp.assert_true(exists (
  select 1 from public.get_entity_type_options((select campaign_id from created_campaign))
  where entity_type_key = 'party'
    and not can_create
), 'active players cannot create GM-owned entity types');
select pg_temp.assert_true(exists (
  select 1 from public.entity_sections
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
    and visibility = 'character_owner_gm'
), 'Character controller can read character_owner_gm sections');
select pg_temp.assert_true(exists (
  select 1 from public.entity_quick_stat_values
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
    and visibility = 'character_owner_gm'
), 'Character controller can read character_owner_gm quick stats');
select pg_temp.assert_true(not exists (
  select 1 from public.character_hooks
  where character_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
), 'Character controller cannot read raw hook rows with GM-only fields');
select pg_temp.assert_true(exists (
  select 1 from public.party_members
  where party_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'party')
), 'Character controller can read visible party membership for their character');
select pg_temp.assert_true(public.can_edit_entity_core((select entity_id from created_m04_entities where entity_type_key = 'character')), 'Character controller can edit owner-edit core fields');
select pg_temp.assert_true(public.can_edit_entity_core((select id from player_private_entity)), 'private entity creator can edit owner-edit core fields');
select pg_temp.assert_true(not public.can_edit_entity_core((select entity_id from created_m04_entities where entity_type_key = 'npc')), 'ordinary player cannot edit GM-edit core fields');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select pg_temp.assert_true(public.can_view_campaign_entity((select entity_id from created_m04_entities where entity_type_key = 'character')), 'GM can view character_owner_gm entity data');
select pg_temp.assert_true(exists (
  select 1 from public.entity_sections
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
    and visibility = 'character_owner_gm'
), 'GM can read character_owner_gm sections');
select pg_temp.assert_true(exists (
  select 1 from public.entity_quick_stat_values
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
    and visibility = 'character_owner_gm'
), 'GM can read character_owner_gm quick stats');
select pg_temp.assert_true(public.can_edit_entity_core((select entity_id from created_m04_entities where entity_type_key = 'character')), 'GM can edit core fields regardless of owner policy');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', false);
select pg_temp.assert_true(not public.can_view_campaign_entity((select entity_id from created_m04_entities where entity_type_key = 'character')), 'active ordinary non-controller cannot view character_owner_gm entity data');
select pg_temp.assert_true(not exists (
  select 1 from public.entity_sections
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
    and visibility = 'character_owner_gm'
), 'active ordinary non-controller cannot read character_owner_gm sections');
select pg_temp.assert_true(not exists (
  select 1 from public.entity_quick_stat_values
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
    and visibility = 'character_owner_gm'
), 'active ordinary non-controller cannot read character_owner_gm quick stats');
select pg_temp.expect_error(
  $$insert into public.entity_quick_stat_values (
      campaign_id,
      entity_id,
      field_id,
      value_number,
      visibility,
      created_by,
      updated_by
    )
    select
      (select campaign_id from created_campaign),
      (select entity_id from created_m04_entities where entity_type_key = 'npc'),
      cqsf.id,
      7,
      'shared',
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    from public.campaign_quick_stat_fields cqsf
    join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
    where cqsf.campaign_id = (select campaign_id from created_campaign)
      and cqst.template_kind = 'npc_statblock'
      and cqsf.key = 'max_hp'$$,
  'npc quick stat values enforce gm_only visibility'
);
select pg_temp.assert_true(not exists (
  select 1 from public.entity_quick_stat_values
  where entity_id = (select id from player_private_entity)
    and visibility = 'shared'
), 'active ordinary player cannot read shared quick stats on hidden parent entities');
select pg_temp.assert_true(not exists (
  select 1 from public.party_members
  where party_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'party')
), 'active ordinary player cannot read party membership for hidden character');
select pg_temp.assert_true(not public.can_edit_entity_core((select entity_id from created_m04_entities where entity_type_key = 'character')), 'active ordinary non-controller cannot edit owner-edit Character core fields');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', false);
select pg_temp.assert_true(not public.can_view_campaign_entity((select entity_id from created_m04_entities where entity_type_key = 'character')), 'removed non-controller cannot view character_owner_gm entity data');
select pg_temp.assert_true(not exists (
  select 1 from public.entity_sections
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
), 'removed member cannot read character_owner_gm sections');
select pg_temp.assert_true(not exists (
  select 1 from public.entity_quick_stat_values
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character')
), 'removed member cannot read character_owner_gm quick stats');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select pg_temp.assert_true(public.can_edit_entity_core((select entity_id from created_m04_entities where entity_type_key = 'character')), 'campaign owner can edit core fields regardless of owner policy');

select pg_temp.assert_true(exists (
  select 1
  from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'storyline')
    and storyline_type = 'quest'
    and storyline_priority_label = 'High'
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
      'storyline',
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
      'quest',
      jsonb_build_object('title', 'Legacy Quest')
    );
    reset role;$$,
  'legacy quest entity type cannot be created'
);
reset role;

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'plot_arc',
      jsonb_build_object('title', 'Legacy Plot Arc')
    );
    reset role;$$,
  'legacy plot arc entity type cannot be created'
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
          select co.id
          from public.campaign_options co
          join public.campaign_option_groups cog on cog.id = co.group_id
          where cog.campaign_id = (select campaign_id from created_campaign)
            and cog.key = 'encounter_type'
            and co.key = 'combat'
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
      select co.id
      from public.campaign_options co
      join public.campaign_option_groups cog on cog.id = co.group_id
      where cog.campaign_id = (select campaign_id from other_campaign)
        and cog.key = 'location_type'
        and co.key = 'district'
    )
  )
);
reset role;

select pg_temp.expect_error(
  $$update public.npcs
    set public_current_location_entity_id = (select entity_id from other_location)
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')$$,
  'direct structural validation rejects cross-campaign location refs'
);

select pg_temp.expect_error(
  $$insert into public.encounter_statblock_values (
      campaign_id,
      encounter_statblock_id,
      field_id,
      value_number,
      created_by,
      updated_by
    )
    select
      (select campaign_id from created_campaign),
      (select id from encounter_statblock),
      cqsf.id,
      10,
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    from public.campaign_quick_stat_fields cqsf
    join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
    where cqsf.campaign_id = (select campaign_id from other_campaign)
      and cqst.template_kind = 'npc_statblock'
      and cqsf.key = 'max_hp'$$,
  'encounter statblock value validation rejects wrong-campaign fields'
);

select pg_temp.expect_error(
  $$insert into public.encounter_statblock_values (
      campaign_id,
      encounter_statblock_id,
      field_id,
      value_number,
      created_by,
      updated_by
    )
    select
      (select campaign_id from created_campaign),
      (select id from encounter_statblock),
      cqsf.id,
      2,
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    from public.campaign_quick_stat_fields cqsf
    join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
    where cqsf.campaign_id = (select campaign_id from created_campaign)
      and cqst.template_kind = 'character'
      and cqsf.key = 'level'$$,
  'encounter statblock value validation rejects character quick stat fields'
);

select pg_temp.expect_error(
  $$insert into public.encounter_statblock_instances (
      campaign_id,
      encounter_statblock_id,
      label,
      current_hp,
      created_by,
      updated_by
    )
    values (
      (select campaign_id from other_campaign),
      (select id from encounter_statblock),
      'Wrong Campaign Instance',
      1,
      '11111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111'
    )$$,
  'encounter statblock instance validation rejects wrong-campaign statblock refs'
);

select pg_temp.expect_error(
  $$update public.parties
    set palette_color_id = (
      select id
      from public.campaign_palette_colors
      where campaign_id = (select campaign_id from other_campaign)
        and key = 'green'
    )
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'party')$$,
  'typed palette validation rejects cross-campaign colors'
);

select pg_temp.expect_error(
  $$update public.storylines
    set symbol_id = (
      select id
      from public.campaign_symbols
      where campaign_id = (select campaign_id from other_campaign)
        and key = 'storyline'
    )
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'storyline')$$,
  'typed symbol validation rejects cross-campaign symbols'
);

select pg_temp.expect_error(
  $$set role authenticated;
    select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
    select * from public.create_campaign_entity(
      (select campaign_id from created_campaign),
      'location',
      jsonb_build_object(
        'name', 'Cross Campaign Child',
        'location_type_option_id', (
          select co.id
          from public.campaign_options co
          join public.campaign_option_groups cog on cog.id = co.group_id
          where cog.campaign_id = (select campaign_id from created_campaign)
            and cog.key = 'location_type'
            and co.key = 'district'
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
  (typed_data ->> 'gm_summary') is null
  and (typed_data ->> 'public_summary') is not null,
  'player-safe detail payload omits GM-only typed fields and keeps shared fields'
)
from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'npc'));
select pg_temp.assert_true(
  controlling_user_display_label = 'Player',
  'character controllers can read their own controller label in safe summaries'
)
from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'character');
select pg_temp.assert_true(
  controlling_user_display_label = 'Player'
  and controlling_user_id = '33333333-3333-3333-3333-333333333333',
  'character controllers can read their own controller identity in safe detail payloads'
)
from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'character'));
select pg_temp.assert_true(
  not can_manage_visibility
  and not can_delete
  and can_add_note
  and not can_add_contribution,
  'player detail capability flags stay constrained to safe actions'
)
from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'npc'));
select pg_temp.assert_true(
  parent_entity_id is null and parent_entity_label is null,
  'player summaries hide inaccessible structural reference ids and labels'
)
from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
where entity_id = (select entity_id from npc_with_hidden_reference);
select pg_temp.assert_true(
  exists (
    select 1
    from public.resolve_entity_references(array[(select entity_id from created_m04_entities where entity_type_key = 'encounter')])
    where requested_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'encounter')
      and resolution_state = 'inaccessible'
      and display_label = 'Unavailable record'
      and entity_type_key is null
      and not can_restore
      and not can_request_access
  ),
  'player reference resolution collapses hidden records to a coarse inaccessible placeholder'
);
select pg_temp.assert_true(not exists (
  select 1
  from public.entity_sections
  where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
    and section_key = 'gm_details'
), 'section RLS hides GM-only sections from players');

set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select pg_temp.assert_true(
  exists (
    select 1
    from public.get_character_hooks((select entity_id from created_m04_entities where entity_type_key = 'character'))
  ),
  'GM can read character hooks through safe character-hook RPC'
);

select pg_temp.assert_true(
  (select typed_data ->> 'gm_summary'
   from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'npc'))) is not null,
  'GM-safe detail payload includes GM-only typed fields'
);
select pg_temp.assert_true(
  can_edit_core
  and can_manage_visibility
  and can_delete
  and can_add_note
  and not can_add_contribution,
  'GM detail capability flags expose management actions'
)
from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'npc'));
select pg_temp.assert_true(
  (select typed_data ->> 'gm_summary'
   from public.get_entity_detail((select entity_id from created_m04_entities where entity_type_key = 'npc'), 'player')) is null,
  'GM player preview detail uses player-safe projection for typed fields'
);
select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_sections((select entity_id from created_m04_entities where entity_type_key = 'npc'), 'player')
    where section_key = 'details'
  )
  and not exists (
    select 1
    from public.get_entity_sections((select entity_id from created_m04_entities where entity_type_key = 'npc'), 'player')
    where section_key = 'gm_details'
  ),
  'GM player preview sections use player-safe projection'
);
select pg_temp.assert_true(
  exists (
    select 1
    from public.resolve_entity_references(array[(select entity_id from created_m04_entities where entity_type_key = 'encounter')])
    where requested_entity_id = (select entity_id from created_m04_entities where entity_type_key = 'encounter')
      and resolution_state = 'visible'
      and display_label is not null
      and entity_type_key = 'encounter'
  ),
  'GM reference resolution returns visible record metadata'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_encounter_statblocks((select entity_id from created_m04_entities where entity_type_key = 'encounter'))
  ),
  'GM can read encounter statblocks through safe statblock RPC'
);

update public.campaign_quick_stat_fields
set is_active = false
where id = (
  select cqsf.id
  from public.campaign_quick_stat_fields cqsf
  join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
  where cqsf.campaign_id = (select campaign_id from created_campaign)
    and cqst.template_kind = 'character'
    and cqsf.key = 'level'
);

update public.campaign_quick_stat_fields
set is_active = false
where id = (
  select cqsf.id
  from public.campaign_quick_stat_fields cqsf
  join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
  where cqsf.campaign_id = (select campaign_id from created_campaign)
    and cqst.template_kind = 'npc_statblock'
    and cqsf.key = 'max_hp'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_quick_stats((select entity_id from created_m04_entities where entity_type_key = 'character'))
    where field_key = 'level'
      and value_number = 5
  ),
  'safe quick stat RPC retains values for deactivated character fields'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_encounter_statblocks((select entity_id from created_m04_entities where entity_type_key = 'encounter')) es,
         jsonb_to_recordset(es.values) as field_value(
           field_key text,
           value_number numeric
         )
    where field_value.field_key = 'max_hp'
      and field_value.value_number = 12
  ),
  'safe encounter statblock RPC retains values for deactivated fields'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.promote_character_hook_to_storyline((select id from created_hook))
    where entity_type_key = 'storyline'
  ),
  'GM can promote a Character hook to a Storyline through RPC'
);

select pg_temp.assert_true(
  (
    select promoted_storyline_entity_id is not null
    from public.character_hooks
    where id = (select id from created_hook)
  ),
  'hook promotion stores the linked Storyline id'
);

select pg_temp.assert_true(
  (
    select count(*)
    from public.promote_character_hook_to_storyline((select id from created_hook))
  ) = 1,
  're-promoting a hook returns the existing Storyline instead of duplicating it'
);

select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', false);
select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_character_hooks((select entity_id from created_m04_entities where entity_type_key = 'character'))
  ),
  'non-GM player cannot read character hook rows'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_encounter_statblocks((select entity_id from created_m04_entities where entity_type_key = 'encounter'))
  ),
  'ordinary player cannot read encounter statblocks'
);
reset role;

update public.entity_sections
set content_mode = 'contribution_feed',
    edit_policy = 'append_contributions'
where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
  and section_key = 'details';

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

select *
into temporary table created_shared_note
from public.create_note(
  (select campaign_id from created_campaign),
  'shared',
  jsonb_build_object(
    'type', 'doc',
    'content', jsonb_build_array(
      jsonb_build_object(
        'type', 'paragraph',
        'content', jsonb_build_array(
          jsonb_build_object('type', 'text', 'text', 'Shared note for '),
          jsonb_build_object(
            'type', 'mention',
            'attrs', jsonb_build_object(
              'entityId', (select entity_id from created_m04_entities where entity_type_key = 'character'),
              'label', 'Ari Voss'
            )
          )
        )
      )
    )
  ),
  'Shared note for @Ari Voss',
  'Shared note for @Ari Voss',
  jsonb_build_array(
    jsonb_build_object(
      'entity_id', (select entity_id from created_m04_entities where entity_type_key = 'character'),
      'label', 'Ari Voss'
    )
  ),
  false,
  array[(select entity_id from created_m04_entities where entity_type_key = 'npc')]
);

select pg_temp.assert_true(count(*) = 1, 'create_note persists a shared note')
from created_shared_note;

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_backlinks((select entity_id from created_m04_entities where entity_type_key = 'character'))
    where source_type = 'note'
      and source_id = (select note_id from created_shared_note)
  ),
  'create_note rebuilds mention rows'
);

select public.attach_note_target(
  (select note_id from created_shared_note),
  'entity',
  (select entity_id from created_m04_entities where entity_type_key = 'encounter')
);

select pg_temp.expect_error(
  $$select * from public.update_note_body(
      (select note_id from created_shared_note),
      'shared',
      '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"stale"}]}]}'::jsonb,
      'stale',
      'stale',
      '[]'::jsonb,
      0
    )$$,
  'update_note_body rejects stale version numbers'
);

select pg_temp.expect_error(
  $$select * from public.create_note(
      (select campaign_id from created_campaign),
      'shared',
      '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Real body"}]}]}'::jsonb,
      'forged text',
      'forged preview',
      '[]'::jsonb,
      false,
      array[(select entity_id from created_m04_entities where entity_type_key = 'npc')]
    )$$,
  'create_note rejects forged derived payload fields'
);

select *
into temporary table saved_npc_section
from public.save_entity_section_body(
  (
    select id
    from public.entity_sections
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
      and section_key = 'gm_details'
  ),
  jsonb_build_object(
    'type', 'doc',
    'content', jsonb_build_array(
      jsonb_build_object(
        'type', 'paragraph',
        'content', jsonb_build_array(
          jsonb_build_object('type', 'text', 'text', 'Secret linked to '),
          jsonb_build_object(
            'type', 'mention',
            'attrs', jsonb_build_object(
              'entityId', (select entity_id from created_m04_entities where entity_type_key = 'character'),
              'label', 'Ari Voss'
            )
          )
        )
      )
    )
  ),
  'Secret linked to @Ari Voss',
  'Secret linked to @Ari Voss',
  jsonb_build_array(
    jsonb_build_object(
      'entity_id', (select entity_id from created_m04_entities where entity_type_key = 'character'),
      'label', 'Ari Voss'
    )
  ),
  1
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_backlinks((select entity_id from created_m04_entities where entity_type_key = 'character'))
    where source_type = 'entity_section'
      and source_id = (select section_id from saved_npc_section)
  ),
  'backlinks expose visible section mentions to GMs'
);

select *
into temporary table created_private_note
from public.create_note(
  (select campaign_id from created_campaign),
  'private',
  '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Private note"}]}]}'::jsonb,
  'Private note',
  'Private note',
  '[]'::jsonb,
  false,
  array[(select entity_id from created_m04_entities where entity_type_key = 'npc')]
);

select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_notes((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where id = (select note_id from created_shared_note)
  ),
  'players can read shared notes attached to visible entities'
);
select pg_temp.assert_true(
  (
    select jsonb_array_length(attachments)
    from public.get_entity_notes((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where id = (select note_id from created_shared_note)
  ) = 1,
  'player note reads omit hidden attached-record placeholders entirely'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_entity_notes((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where id = (select note_id from created_private_note)
  ),
  'players cannot read another user private notes'
);

select *
into temporary table created_character_owner_note
from public.create_note(
  (select campaign_id from created_campaign),
  'character_owner_gm',
  '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Controller note"}]}]}'::jsonb,
  'Controller note',
  'Controller note',
  '[]'::jsonb,
  false,
  array[(select entity_id from created_m04_entities where entity_type_key = 'character')]
);

select pg_temp.assert_true(count(*) = 1, 'character controller can create character_owner_gm note')
from created_character_owner_note;

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_notes((select entity_id from created_m04_entities where entity_type_key = 'character'))
    where id = (select note_id from created_character_owner_note)
  ),
  'character controller can read character_owner_gm note'
);

select *
into temporary table created_contribution
from public.create_entity_section_contribution(
  (
    select id
    from public.entity_sections
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
      and section_key = 'details'
  ),
  'shared',
  '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Player theory"}]}]}'::jsonb,
  'Player theory',
  'Player theory',
  '[]'::jsonb
);

select pg_temp.assert_true(count(*) = 1, 'players can create contributions in contribution-feed sections')
from created_contribution;

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_section_contributions((
      select id
      from public.entity_sections
      where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'npc')
        and section_key = 'details'
    ))
    where id = (select contribution_id from created_contribution)
  ),
  'section contribution safe read returns visible contributions'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_entity_notes((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where id = (select note_id from created_private_note)
  ),
  'other GMs cannot read private notes they did not author'
);

reset role;

update public.campaign_entities
set parent_entity_id = (
  select entity_id
  from created_m04_entities
  where entity_type_key = 'location'
)
where id = (
  select entity_id
  from created_m04_entities
  where entity_type_key = 'npc'
);

set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);

select *
into temporary table created_shared_relationship
from public.create_entity_relationship(
  (select entity_id from created_m04_entities where entity_type_key = 'npc'),
  (select entity_id from created_m04_entities where entity_type_key = 'party'),
  (
    select id
    from public.relationship_types
    where key = 'ally_of'
      and campaign_id is null
  ),
  'shared'
);

select pg_temp.assert_true(count(*) = 1, 'GMs can create shared explicit relationships')
from created_shared_relationship;

select *
into temporary table created_gm_only_relationship
from public.create_entity_relationship(
  (select entity_id from created_m04_entities where entity_type_key = 'npc'),
  (select entity_id from created_m04_entities where entity_type_key = 'character'),
  (
    select id
    from public.relationship_types
    where key = 'threatens'
      and campaign_id is null
  ),
  'gm_only'
);

select pg_temp.expect_error(
  $$select * from public.create_entity_relationship(
      (select entity_id from created_m04_entities where entity_type_key = 'npc'),
      (select entity_id from created_m04_entities where entity_type_key = 'encounter'),
      (select id from public.relationship_types where key = 'related_to' and campaign_id is null),
      'shared'
    )$$,
  'shared relationships reject hidden or non-shared endpoints'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_relationships((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relationship_id = (select relationship_id from created_shared_relationship)
      and relationship_type_key = 'ally_of'
      and related_entity_label = 'The Lantern Company'
  ),
  'relationship read surface returns explicit relationships to GMs'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_related_records((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relation_source = 'explicit'
      and relationship_type_key = 'ally_of'
  ),
  'related-records include explicit relationship rows'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_related_records((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relation_source = 'structural'
      and relationship_type_key = 'parent_of'
  ),
  'related-records include structural link rows'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_related_records((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relation_source = 'mention'
      and source_type = 'note'
  ),
  'related-records include mention-derived rows'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_timeline_events((select campaign_id from created_campaign), null, null, null, null)
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'timeline_event')
  ),
  'timeline read surface returns visible timeline events'
);

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_entity_relationships((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relationship_id = (select relationship_id from created_shared_relationship)
  ),
  'players can read shared explicit relationships'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_entity_relationships((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relationship_id = (select relationship_id from created_gm_only_relationship)
  ),
  'players cannot read GM-only explicit relationships'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_entity_related_records((select entity_id from created_m04_entities where entity_type_key = 'npc'))
    where relation_source = 'explicit'
      and relationship_type_key = 'threatens'
  ),
  'related-records hide GM-only relationship existence from players'
);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_entity_relationships((select entity_id from created_m04_entities where entity_type_key = 'npc'), 'player')
    where visibility = 'gm_only'
  ),
  'GM player preview relationships use player-safe projection'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_entity_related_records((select entity_id from created_m04_entities where entity_type_key = 'npc'), 'player')
    where relation_source = 'explicit'
      and visibility = 'gm_only'
  ),
  'GM player preview related-records hide GM-only explicit links'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_timeline_events((select campaign_id from created_campaign), null, null, null, null, 'player')
    where entity_id = (select entity_id from created_m04_entities where entity_type_key = 'timeline_event')
  )
  and not exists (
    select 1
    from public.get_timeline_events((select campaign_id from created_campaign), null, null, null, 'gm_only', 'player')
  ),
  'GM player preview timeline uses player-safe projection'
);

select pg_temp.expect_error(
  $$select * from public.create_entity_relationship(
      (select entity_id from created_m04_entities where entity_type_key = 'npc'),
      (select entity_id from created_m04_entities where entity_type_key = 'character'),
      (select id from public.relationship_types where key = 'ally_of' and campaign_id is null),
      'shared'
    )$$,
  'players cannot create explicit relationships'
);

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

create temporary table m08_secret_storyline as
select *
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'storyline',
  jsonb_build_object(
    'title', 'Secret Arc',
    'status_id', (
      select sd.id
      from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'storyline'
        and sd.key = 'open'
        and sd.campaign_id is null
      limit 1
    ),
    'storyline_type', 'quest',
    'default_visibility', 'gm_only'
  )
);

create temporary table m08_shared_future_session as
select *
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'session',
  jsonb_build_object(
    'title', 'Visible Future Session',
    'status_id', (
      select sd.id
      from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'session'
        and sd.key = 'planned'
        and sd.campaign_id is null
      limit 1
    ),
    'session_date', '2026-06-20'
  )
);

create temporary table m08_hidden_soon_session as
select *
from public.create_campaign_entity(
  (select campaign_id from created_campaign),
  'session',
  jsonb_build_object(
    'title', 'Hidden Soon Session',
    'status_id', (
      select sd.id
      from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'session'
        and sd.key = 'planned'
        and sd.campaign_id is null
      limit 1
    ),
    'session_date', '2026-06-14',
    'default_visibility', 'gm_only'
  )
);

create temporary table m08_secret_note as
select *
from public.create_note(
  (select campaign_id from created_campaign),
  'gm_only',
  '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Secret arc prep"}]}]}'::jsonb,
  'Secret arc prep',
  'Secret arc prep',
  '[]'::jsonb,
  false,
  array[(select entity_id from m08_secret_storyline)]
);

select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);

create temporary table m08_private_note as
select *
from public.create_note(
  (select campaign_id from created_campaign),
  'private',
  '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Player-only note"}]}]}'::jsonb,
  'Player-only note',
  'Player-only note',
  '[]'::jsonb,
  false,
  array[(select entity_id from created_m04_entities where entity_type_key = 'character')]
);

select pg_temp.assert_true(
  array_agg(section_key order by section_key) = array['session_notes']::text[],
  'players only read shared session sections'
)
from public.get_entity_sections(
  (select entity_id from created_m04_entities where entity_type_key = 'session'),
  'player'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
    where entity_id in (
      (select entity_id from created_m04_entities where entity_type_key = 'encounter'),
      (select entity_id from m08_secret_storyline)
    )
  ),
  'player summaries omit gm-only encounters and storylines'
);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_campaign_activity((select campaign_id from created_campaign), null, 50)
    where subject_id = (select note_id from m08_private_note)
      and activity_type = 'note_created'
  ),
  'private note activity is visible to the author'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_campaign_activity((select campaign_id from created_campaign), null, 50)
    where label ilike '%Secret Arc%'
  ),
  'player activity labels do not leak hidden storyline labels'
);

select pg_temp.assert_true(
  (select session_entity_id from public.get_current_session((select campaign_id from created_campaign), 'player'))
    <> (select entity_id from m08_hidden_soon_session),
  'player current session skips hidden earlier planned sessions'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);

select pg_temp.assert_true(
  exists (
    select 1
    from public.get_campaign_entity_summaries((select campaign_id from created_campaign))
    where entity_id = (select entity_id from m08_secret_storyline)
  ),
  'GM summaries include gm-only storylines'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from public.get_campaign_activity((select campaign_id from created_campaign), null, 50)
    where subject_id = (select note_id from m08_private_note)
  ),
  'private note activity stays author-only even for GMs'
);

select pg_temp.assert_true(
  (select session_entity_id from public.get_current_session((select campaign_id from created_campaign)))
    = (select entity_id from m08_hidden_soon_session),
  'GM current session picks the nearest upcoming planned session'
);

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

create temporary table m08_other_campaign as
select *
from public.create_campaign('Attendance Cross-Campaign', current_date, 'Second campaign');

create temporary table m08_other_character as
select *
from public.create_campaign_entity(
  (select campaign_id from m08_other_campaign),
  'character',
  jsonb_build_object(
    'name', 'Off-Campaign Hero',
    'status_id', (
      select sd.id
      from public.status_definitions sd
      join public.entity_types et on et.id = sd.entity_type_id
      where et.key = 'character'
        and sd.key = 'active'
        and sd.campaign_id is null
      limit 1
    ),
    'controlling_user_id', '11111111-1111-1111-1111-111111111111'
  )
);

select pg_temp.expect_error(
  $$select * from public.update_session_attendance(
      (select entity_id from created_m04_entities where entity_type_key = 'session'),
      array['44444444-4444-4444-4444-444444444444'::uuid],
      array[]::uuid[]
    )$$,
  'attendance rejects non-member users'
);

select pg_temp.expect_error(
  $$select * from public.update_session_attendance(
      (select entity_id from created_m04_entities where entity_type_key = 'session'),
      array['33333333-3333-3333-3333-333333333333'::uuid],
      array[(select entity_id from m08_other_character)]
    )$$,
  'attendance rejects cross-campaign characters'
);

select *
into temporary table m08_attendance_result
from public.update_session_attendance(
  (select entity_id from created_m04_entities where entity_type_key = 'session'),
  array['33333333-3333-3333-3333-333333333333'::uuid, '33333333-3333-3333-3333-333333333333'::uuid],
  array[
    (select entity_id from created_m04_entities where entity_type_key = 'character'),
    (select entity_id from created_m04_entities where entity_type_key = 'character')
  ]
);

select pg_temp.assert_true(user_count = 1 and character_count = 1, 'duplicate attendance rows are prevented')
from m08_attendance_result;
reset role;

select 'M04 + 04.5 + 05 + 06 + 07 + 08 RLS smoke tests passed' as result;
