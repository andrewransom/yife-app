create or replace function public.can_manage_entity_visibility(p_entity_id uuid)
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
      and public.can_view_gm_content(ce.campaign_id)
  )
$$;

create or replace function public.is_player_preview_role(p_role_view text default null)
returns boolean
language sql
immutable
as $$
  select coalesce(p_role_view, '') = 'player'
$$;

create or replace function public.can_view_entity_visibility_for_role(
  p_campaign_id uuid,
  p_visibility text,
  p_created_by uuid,
  p_entity_id uuid default null,
  p_role_view text default null
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when public.is_player_preview_role(p_role_view) then
      p_visibility = 'shared' and public.is_campaign_member(p_campaign_id)
    else public.can_view_entity_visibility(p_campaign_id, p_visibility, p_created_by, p_entity_id)
  end
$$;

create or replace function public.can_view_campaign_entity_for_role(
  p_entity_id uuid,
  p_role_view text default null
)
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
      and public.can_view_entity_visibility_for_role(
        ce.campaign_id,
        ce.default_visibility,
        ce.created_by,
        ce.id,
        p_role_view
      )
  )
$$;

create or replace function public.entity_ref_label_for_role(
  p_entity_id uuid,
  p_role_view text default null
)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when public.can_view_campaign_entity_for_role(ce.id, p_role_view) then ce.list_caption
    else null
  end
  from public.campaign_entities ce
  where ce.id = p_entity_id
    and ce.deleted_at is null
$$;

create or replace function public.can_delete_campaign_entity(p_entity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can_manage_entity_visibility(p_entity_id)
$$;

create or replace function public.can_add_entity_note(p_entity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can_view_campaign_entity(p_entity_id)
$$;

create or replace function public.can_add_entity_contribution(p_entity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.entity_sections es
    join public.campaign_entities ce on ce.id = es.entity_id
    where es.entity_id = p_entity_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity(ce.id)
      and public.can_view_entity_visibility(ce.campaign_id, es.visibility, es.created_by, es.entity_id)
      and (es.content_mode = 'contribution_feed' or es.edit_policy = 'append_contributions')
  )
$$;

create or replace function public.resolve_entity_references(p_entity_ids uuid[])
returns table (
  requested_entity_id uuid,
  resolution_state text,
  display_label text,
  entity_type_key text,
  can_restore boolean,
  can_request_access boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with requested_ids as (
    select unnest(coalesce(p_entity_ids, array[]::uuid[])) as requested_entity_id
  )
  select
    requested.requested_entity_id,
    case
      when ce.id is null then 'hard_deleted'
      when public.can_view_campaign_entity(ce.id) then 'visible'
      when ce.deleted_at is not null and public.can_view_gm_content(ce.campaign_id) then 'deleted'
      when ce.deleted_at is not null then 'hard_deleted'
      else 'inaccessible'
    end as resolution_state,
    case
      when public.can_view_campaign_entity(ce.id) then ce.list_caption
      when ce.deleted_at is not null and public.can_view_gm_content(ce.campaign_id) then 'Deleted record'
      when ce.id is null or ce.deleted_at is not null then 'Deleted record'
      else 'Unavailable record'
    end as display_label,
    case
      when public.can_view_campaign_entity(ce.id) then et.key
      when ce.deleted_at is not null and public.can_view_gm_content(ce.campaign_id) then et.key
      else null
    end as entity_type_key,
    case
      when ce.deleted_at is not null and public.can_view_gm_content(ce.campaign_id) then true
      else false
    end as can_restore,
    false as can_request_access
  from requested_ids requested
  left join public.campaign_entities ce on ce.id = requested.requested_entity_id
  left join public.entity_types et on et.id = ce.entity_type_id;
$$;

drop function if exists public.get_entity_detail(uuid);

create function public.get_entity_detail(
  p_entity_id uuid,
  p_role_view text default null
)
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
  can_edit_core boolean,
  can_manage_visibility boolean,
  can_delete boolean,
  can_add_note boolean,
  can_add_contribution boolean,
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
    case when public.can_view_campaign_entity_for_role(ce.parent_entity_id, p_role_view) then ce.parent_entity_id else null end,
    public.entity_ref_label_for_role(ce.parent_entity_id, p_role_view),
    case when public.can_view_campaign_entity_for_role(ce.related_session_entity_id, p_role_view) then ce.related_session_entity_id else null end,
    public.entity_ref_label_for_role(ce.related_session_entity_id, p_role_view),
    case when public.can_view_campaign_entity_for_role(e.related_storyline_entity_id, p_role_view) then e.related_storyline_entity_id else null end,
    public.entity_ref_label_for_role(e.related_storyline_entity_id, p_role_view),
    case
      when not public.is_player_preview_role(p_role_view)
        and public.can_view_entity_visibility(ce.campaign_id, 'character_owner_gm', public.current_user_id(), ce.id)
        then ch.controlling_user_id
      else null
    end,
    case
      when not public.is_player_preview_role(p_role_view)
        and public.can_view_entity_visibility(ce.campaign_id, 'character_owner_gm', public.current_user_id(), ce.id)
        then coalesce(cm.display_name_override, up.display_name)
      else null
    end,
    location_type.label,
    st.storyline_type,
    storyline_priority.label,
    storyline_category.label,
    st.is_major,
    encounter_type.label,
    te.date_expression,
    timeline_type.label,
    npc_apparent.label,
    case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then npc_real.label else null end,
    case when public.is_player_preview_role(p_role_view) then false else public.can_edit_entity_core(ce.id) end,
    case when public.is_player_preview_role(p_role_view) then false else public.can_manage_entity_visibility(ce.id) end,
    case when public.is_player_preview_role(p_role_view) then false else public.can_delete_campaign_entity(ce.id) end,
    public.can_add_entity_note(ce.id),
    case when public.is_player_preview_role(p_role_view) then false else public.can_add_entity_contribution(ce.id) end,
    case et.key
      when 'character' then jsonb_build_object(
        'species_ancestry_text', ch.species_ancestry_text,
        'pronouns', ch.pronouns,
        'public_summary', ch.public_summary,
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then ch.gm_summary else null end,
        'character_sheet_url', ch.character_sheet_url
      )
      when 'npc' then jsonb_build_object(
        'faction', case
          when public.can_view_campaign_entity_for_role(n.faction_entity_id, p_role_view)
            then jsonb_build_object('id', n.faction_entity_id, 'label', public.entity_ref_label_for_role(n.faction_entity_id, p_role_view))
          else null
        end,
        'role_option_id', n.role_option_id,
        'role_label', coalesce(
          (select co.label from public.campaign_options co where co.id = n.role_option_id),
          n.role_label
        ),
        'speech_text', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then n.speech_text else null end,
        'party_disposition_option_id', n.party_disposition_option_id,
        'party_disposition_label', (select co.label from public.campaign_options co where co.id = n.party_disposition_option_id),
        'relationship_to_party_text', n.relationship_to_party_text,
        'public_summary', n.public_summary,
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then n.gm_summary else null end,
        'public_current_location', case
          when public.can_view_campaign_entity_for_role(n.public_current_location_entity_id, p_role_view)
            then jsonb_build_object('id', n.public_current_location_entity_id, 'label', public.entity_ref_label_for_role(n.public_current_location_entity_id, p_role_view))
          else null
        end,
        'gm_current_location', case
          when not public.is_player_preview_role(p_role_view)
            and public.can_view_gm_content(ce.campaign_id)
            and public.can_view_campaign_entity_for_role(n.gm_current_location_entity_id, p_role_view)
            then jsonb_build_object('id', n.gm_current_location_entity_id, 'label', public.entity_ref_label_for_role(n.gm_current_location_entity_id, p_role_view))
          else null
        end,
        'public_home_location', case
          when public.can_view_campaign_entity_for_role(n.public_home_location_entity_id, p_role_view)
            then jsonb_build_object('id', n.public_home_location_entity_id, 'label', public.entity_ref_label_for_role(n.public_home_location_entity_id, p_role_view))
          else null
        end,
        'gm_home_location', case
          when not public.is_player_preview_role(p_role_view)
            and public.can_view_gm_content(ce.campaign_id)
            and public.can_view_campaign_entity_for_role(n.gm_home_location_entity_id, p_role_view)
            then jsonb_build_object('id', n.gm_home_location_entity_id, 'label', public.entity_ref_label_for_role(n.gm_home_location_entity_id, p_role_view))
          else null
        end,
        'reports_to', case
          when public.can_view_campaign_entity_for_role(n.reports_to_entity_id, p_role_view)
            then jsonb_build_object('id', n.reports_to_entity_id, 'label', public.entity_ref_label_for_role(n.reports_to_entity_id, p_role_view))
          else null
        end,
        'has_stat_block', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then (n.stat_block_jsonb is not null) else null end
      )
      when 'party' then jsonb_build_object(
        'public_summary', p.public_summary,
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then p.gm_summary else null end,
        'home_location', case
          when public.can_view_campaign_entity_for_role(p.home_location_entity_id, p_role_view)
            then jsonb_build_object('id', p.home_location_entity_id, 'label', public.entity_ref_label_for_role(p.home_location_entity_id, p_role_view))
          else null
        end,
        'current_location', case
          when public.can_view_campaign_entity_for_role(p.current_location_entity_id, p_role_view)
            then jsonb_build_object('id', p.current_location_entity_id, 'label', public.entity_ref_label_for_role(p.current_location_entity_id, p_role_view))
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
          when public.can_view_campaign_entity_for_role(f.parent_faction_entity_id, p_role_view)
            then jsonb_build_object('id', f.parent_faction_entity_id, 'label', public.entity_ref_label_for_role(f.parent_faction_entity_id, p_role_view))
          else null
        end,
        'faction_type_option_id', f.faction_type_option_id,
        'faction_type_label', (select co.label from public.campaign_options co where co.id = f.faction_type_option_id),
        'scope_option_id', case when f.scope_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)) then f.scope_option_id else null end,
        'scope_label', case
          when f.scope_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id))
            then (select co.label from public.campaign_options co where co.id = f.scope_option_id)
          else null
        end,
        'numbers_text', case when f.numbers_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)) then f.numbers_text else null end,
        'public_summary', f.public_summary,
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then f.gm_summary else null end,
        'party_disposition_option_id', f.party_disposition_option_id,
        'party_disposition_label', (select co.label from public.campaign_options co where co.id = f.party_disposition_option_id),
        'relationship_to_party_text', f.relationship_to_party_text,
        'headquarters_location', case
          when (f.headquarters_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)))
            and public.can_view_campaign_entity_for_role(f.headquarters_location_entity_id, p_role_view)
            then jsonb_build_object('id', f.headquarters_location_entity_id, 'label', public.entity_ref_label_for_role(f.headquarters_location_entity_id, p_role_view))
          else null
        end,
        'territory_location', case
          when (f.territory_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)))
            and public.can_view_campaign_entity_for_role(f.territory_location_entity_id, p_role_view)
            then jsonb_build_object('id', f.territory_location_entity_id, 'label', public.entity_ref_label_for_role(f.territory_location_entity_id, p_role_view))
          else null
        end,
        'leader', case
          when (f.leader_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)))
            and public.can_view_campaign_entity_for_role(f.leader_entity_id, p_role_view)
            then jsonb_build_object('id', f.leader_entity_id, 'label', public.entity_ref_label_for_role(f.leader_entity_id, p_role_view))
          else null
        end,
        'public_goal_text', f.public_goal_text,
        'gm_true_goal_text', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then f.gm_true_goal_text else null end,
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
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then l.gm_summary else null end,
        'known_to_party', l.known_to_party,
        'visited_by_party', l.visited_by_party,
        'relationship_to_party_text', l.relationship_to_party_text,
        'party_disposition_option_id', l.party_disposition_option_id,
        'party_disposition_label', (select co.label from public.campaign_options co where co.id = l.party_disposition_option_id),
        'controlling_faction', case
          when (l.controlling_faction_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)))
            and public.can_view_campaign_entity_for_role(l.controlling_faction_entity_id, p_role_view)
            then jsonb_build_object('id', l.controlling_faction_entity_id, 'label', public.entity_ref_label_for_role(l.controlling_faction_entity_id, p_role_view))
          else null
        end,
        'owner_or_steward', case
          when (l.owner_or_steward_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)))
            and public.can_view_campaign_entity_for_role(l.owner_or_steward_entity_id, p_role_view)
            then jsonb_build_object('id', l.owner_or_steward_entity_id, 'label', public.entity_ref_label_for_role(l.owner_or_steward_entity_id, p_role_view))
          else null
        end,
        'ruler_or_authority', case
          when (l.ruler_or_authority_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)))
            and public.can_view_campaign_entity_for_role(l.ruler_or_authority_entity_id, p_role_view)
            then jsonb_build_object('id', l.ruler_or_authority_entity_id, 'label', public.entity_ref_label_for_role(l.ruler_or_authority_entity_id, p_role_view))
          else null
        end,
        'population_text', case when l.population_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)) then l.population_text else null end,
        'size_or_scale_text', case when l.size_or_scale_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)) then l.size_or_scale_text else null end,
        'terrain_option_id', l.terrain_option_id,
        'terrain_label', (select co.label from public.campaign_options co where co.id = l.terrain_option_id),
        'danger_level_option_id', case when l.danger_level_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)) then l.danger_level_option_id else null end,
        'danger_level_label', case
          when l.danger_level_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id))
            then (select co.label from public.campaign_options co where co.id = l.danger_level_option_id)
          else null
        end,
        'accessibility_option_id', case when l.accessibility_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id)) then l.accessibility_option_id else null end,
        'accessibility_label', case
          when l.accessibility_visibility = 'shared' or (not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id))
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
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then st.gm_summary else null end,
        'primary_location', case
          when public.can_view_campaign_entity_for_role(st.primary_location_entity_id, p_role_view)
            then jsonb_build_object('id', st.primary_location_entity_id, 'label', public.entity_ref_label_for_role(st.primary_location_entity_id, p_role_view))
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
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then s.gm_summary else null end,
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
        'gm_summary', case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ce.campaign_id) then te.gm_summary else null end,
        'primary_location', case
          when public.can_view_campaign_entity_for_role(te.primary_location_entity_id, p_role_view)
            then jsonb_build_object('id', te.primary_location_entity_id, 'label', public.entity_ref_label_for_role(te.primary_location_entity_id, p_role_view))
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
        and public.can_view_entity_visibility_for_role(ce.campaign_id, es.visibility, es.created_by, es.entity_id, p_role_view)
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
    and public.can_view_campaign_entity_for_role(ce.id, p_role_view);
$$;

drop function if exists public.get_party_members(uuid);

create function public.get_party_members(
  p_party_entity_id uuid,
  p_role_view text default null
)
returns table (
  character_entity_id uuid,
  role_label text,
  is_active boolean,
  sort_order integer,
  character_label text,
  character_visibility text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    pm.character_entity_id,
    pm.role_label,
    pm.is_active,
    pm.sort_order,
    ce_character.list_caption,
    ce_character.default_visibility
  from public.party_members pm
  join public.campaign_entities ce_party on ce_party.id = pm.party_entity_id
  join public.campaign_entities ce_character on ce_character.id = pm.character_entity_id
  where pm.party_entity_id = p_party_entity_id
    and ce_party.deleted_at is null
    and ce_character.deleted_at is null
    and public.can_view_campaign_entity_for_role(ce_party.id, p_role_view)
    and public.can_view_campaign_entity_for_role(ce_character.id, p_role_view)
  order by pm.sort_order, ce_character.list_caption;
$$;

revoke all on function public.can_manage_entity_visibility(uuid) from public, anon;
revoke all on function public.can_delete_campaign_entity(uuid) from public, anon;
revoke all on function public.can_add_entity_note(uuid) from public, anon;
revoke all on function public.can_add_entity_contribution(uuid) from public, anon;
revoke all on function public.is_player_preview_role(text) from public, anon;
revoke all on function public.can_view_entity_visibility_for_role(uuid, text, uuid, uuid, text) from public, anon;
revoke all on function public.can_view_campaign_entity_for_role(uuid, text) from public, anon;
revoke all on function public.entity_ref_label_for_role(uuid, text) from public, anon;
revoke all on function public.resolve_entity_references(uuid[]) from public, anon;
revoke all on function public.get_entity_detail(uuid, text) from public, anon;
revoke all on function public.get_party_members(uuid, text) from public, anon;

grant execute on function public.can_manage_entity_visibility(uuid) to authenticated, service_role;
grant execute on function public.can_delete_campaign_entity(uuid) to authenticated, service_role;
grant execute on function public.can_add_entity_note(uuid) to authenticated, service_role;
grant execute on function public.can_add_entity_contribution(uuid) to authenticated, service_role;
grant execute on function public.is_player_preview_role(text) to authenticated, service_role;
grant execute on function public.can_view_entity_visibility_for_role(uuid, text, uuid, uuid, text) to authenticated, service_role;
grant execute on function public.can_view_campaign_entity_for_role(uuid, text) to authenticated, service_role;
grant execute on function public.entity_ref_label_for_role(uuid, text) to authenticated, service_role;
grant execute on function public.resolve_entity_references(uuid[]) to authenticated, service_role;
grant execute on function public.get_entity_detail(uuid, text) to authenticated, service_role;
grant execute on function public.get_party_members(uuid, text) to authenticated, service_role;
