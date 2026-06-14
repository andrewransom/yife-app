drop function if exists public.get_entity_quick_stats(uuid);

create function public.get_entity_quick_stats(
  p_entity_id uuid,
  p_role_view text default null
)
returns table (
  field_id uuid,
  field_key text,
  label text,
  compact_label text,
  value_type text,
  visibility text,
  sort_order integer,
  value_id uuid,
  value_number numeric,
  value_text text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with entity_context as (
    select ce.id as entity_id, ce.campaign_id, et.key as entity_type_key
    from public.campaign_entities ce
    join public.entity_types et on et.id = ce.entity_type_id
    where ce.id = p_entity_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
      and et.key in ('character', 'npc')
  ),
  active_fields as (
    select
      ec.entity_id,
      cqsf.id as field_id,
      cqsf.key as field_key,
      cqsf.label,
      cqsf.compact_label,
      cqsf.value_type,
      cqsf.default_visibility,
      cqsf.sort_order
    from entity_context ec
    join public.campaign_quick_stat_templates cqst
      on cqst.campaign_id = ec.campaign_id
     and cqst.template_kind = case
       when ec.entity_type_key = 'character' then 'character'
       else 'npc_statblock'
     end
     and cqst.is_active
    join public.campaign_quick_stat_fields cqsf
      on cqsf.template_id = cqst.id
     and cqsf.campaign_id = ec.campaign_id
     and cqsf.is_active
  ),
  legacy_fields as (
    select distinct
      ec.entity_id,
      cqsf.id as field_id,
      cqsf.key as field_key,
      cqsf.label,
      cqsf.compact_label,
      cqsf.value_type,
      cqsf.default_visibility,
      cqsf.sort_order
    from entity_context ec
    join public.entity_quick_stat_values eqsv
      on eqsv.entity_id = ec.entity_id
     and eqsv.campaign_id = ec.campaign_id
    join public.campaign_quick_stat_fields cqsf
      on cqsf.id = eqsv.field_id
     and cqsf.campaign_id = ec.campaign_id
    join public.campaign_quick_stat_templates cqst
      on cqst.id = cqsf.template_id
     and cqst.campaign_id = ec.campaign_id
     and cqst.template_kind = case
       when ec.entity_type_key = 'character' then 'character'
       else 'npc_statblock'
     end
    where not exists (
      select 1
      from active_fields af
      where af.field_id = cqsf.id
    )
  ),
  stat_fields as (
    select * from active_fields
    union all
    select * from legacy_fields
  )
  select
    sf.field_id,
    sf.field_key,
    sf.label,
    sf.compact_label,
    sf.value_type,
    coalesce(eqsv.visibility, sf.default_visibility),
    sf.sort_order,
    eqsv.id,
    eqsv.value_number,
    eqsv.value_text
  from entity_context ec
  join stat_fields sf
    on sf.entity_id = ec.entity_id
  left join public.entity_quick_stat_values eqsv
    on eqsv.entity_id = ec.entity_id
   and eqsv.field_id = sf.field_id
   and eqsv.campaign_id = ec.campaign_id
  where public.can_view_entity_visibility_for_role(
    ec.campaign_id,
    coalesce(eqsv.visibility, sf.default_visibility),
    eqsv.created_by,
    ec.entity_id,
    p_role_view
  )
  order by sf.sort_order, sf.label;
$$;

drop function if exists public.get_character_hooks(uuid);

create function public.get_character_hooks(
  p_character_entity_id uuid,
  p_role_view text default null
)
returns table (
  id uuid,
  description_text text,
  status_key text,
  status_label text,
  category_option_id uuid,
  category_label text,
  visibility text,
  gm_note_text text,
  promoted_storyline_entity_id uuid,
  promoted_storyline_label text,
  sort_order integer,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    ch.id,
    ch.description_text,
    sd.key,
    sd.label,
    ch.category_option_id,
    co.label,
    ch.visibility,
    case when not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(ch.campaign_id) then ch.gm_note_text else null end,
    case when public.can_view_campaign_entity_for_role(ch.promoted_storyline_entity_id, p_role_view) then ch.promoted_storyline_entity_id else null end,
    public.entity_ref_label_for_role(ch.promoted_storyline_entity_id, p_role_view),
    ch.sort_order,
    ch.updated_at
  from public.character_hooks ch
  join public.status_definitions sd on sd.id = ch.status_id
  left join public.campaign_options co on co.id = ch.category_option_id
  where ch.character_entity_id = p_character_entity_id
    and ch.deleted_at is null
    and exists (
      select 1
      from public.campaign_entities ce
      join public.entity_types et on et.id = ce.entity_type_id
      where ce.id = ch.character_entity_id
        and et.key = 'character'
        and ce.campaign_id = ch.campaign_id
        and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
    )
    and public.can_view_entity_visibility_for_role(
      ch.campaign_id,
      ch.visibility,
      ch.created_by,
      ch.character_entity_id,
      p_role_view
    )
  order by ch.sort_order, ch.created_at;
$$;

drop function if exists public.get_encounter_statblocks(uuid);

create function public.get_encounter_statblocks(
  p_encounter_entity_id uuid,
  p_role_view text default null
)
returns table (
  id uuid,
  label text,
  linked_npc_entity_id uuid,
  linked_npc_label text,
  quantity integer,
  sort_order integer,
  "values" jsonb,
  instances jsonb
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    es.id,
    es.label,
    case when public.can_view_campaign_entity_for_role(es.linked_npc_entity_id, p_role_view) then es.linked_npc_entity_id else null end,
    public.entity_ref_label_for_role(es.linked_npc_entity_id, p_role_view),
    es.quantity,
    es.sort_order,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'field_id', field_data.field_id,
          'field_key', field_data.field_key,
          'label', field_data.label,
          'compact_label', field_data.compact_label,
          'value_type', field_data.value_type,
          'value_id', field_data.value_id,
          'value_number', field_data.value_number,
          'value_text', field_data.value_text
        )
        order by field_data.sort_order, field_data.label
      )
      from (
        with active_fields as (
          select
            cqsf.id as field_id,
            cqsf.key as field_key,
            cqsf.label,
            cqsf.compact_label,
            cqsf.value_type,
            cqsf.sort_order,
            esv.id as value_id,
            esv.value_number,
            esv.value_text
          from public.campaign_quick_stat_fields cqsf
          join public.campaign_quick_stat_templates cqst on cqst.id = cqsf.template_id
          left join public.encounter_statblock_values esv
            on esv.field_id = cqsf.id
           and esv.encounter_statblock_id = es.id
           and esv.campaign_id = es.campaign_id
          where cqsf.campaign_id = es.campaign_id
            and cqsf.is_active
            and cqst.campaign_id = es.campaign_id
            and cqst.template_kind = 'npc_statblock'
            and cqst.is_active
        )
        select * from active_fields
        union all
        select distinct
          cqsf.id as field_id,
          cqsf.key as field_key,
          cqsf.label,
          cqsf.compact_label,
          cqsf.value_type,
          cqsf.sort_order,
          esv.id as value_id,
          esv.value_number,
          esv.value_text
        from public.encounter_statblock_values esv
        join public.campaign_quick_stat_fields cqsf
          on cqsf.id = esv.field_id
         and cqsf.campaign_id = es.campaign_id
        join public.campaign_quick_stat_templates cqst
          on cqst.id = cqsf.template_id
         and cqst.campaign_id = es.campaign_id
         and cqst.template_kind = 'npc_statblock'
        where esv.encounter_statblock_id = es.id
          and esv.campaign_id = es.campaign_id
          and not exists (
            select 1
            from active_fields af
            where af.field_id = cqsf.id
          )
      ) as field_data
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', esi.id,
          'label', esi.label,
          'current_hp', esi.current_hp,
          'max_hp_override', esi.max_hp_override,
          'is_defeated', esi.is_defeated,
          'sort_order', esi.sort_order
        )
        order by esi.sort_order, esi.created_at
      )
      from public.encounter_statblock_instances esi
      where esi.encounter_statblock_id = es.id
        and esi.campaign_id = es.campaign_id
        and esi.deleted_at is null
    ), '[]'::jsonb)
  from public.encounter_statblocks es
  where es.encounter_entity_id = p_encounter_entity_id
    and es.deleted_at is null
    and exists (
      select 1
      from public.campaign_entities ce
      join public.entity_types et on et.id = ce.entity_type_id
      where ce.id = es.encounter_entity_id
        and et.key = 'encounter'
        and ce.campaign_id = es.campaign_id
        and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
        and not public.is_player_preview_role(p_role_view)
        and public.can_view_gm_content(ce.campaign_id)
    )
  order by es.sort_order, es.label;
$$;

revoke all on function public.get_entity_quick_stats(uuid, text) from anon, public;
revoke all on function public.get_character_hooks(uuid, text) from anon, public;
revoke all on function public.get_encounter_statblocks(uuid, text) from anon, public;

grant execute on function public.get_entity_quick_stats(uuid, text) to authenticated, service_role;
grant execute on function public.get_character_hooks(uuid, text) to authenticated, service_role;
grant execute on function public.get_encounter_statblocks(uuid, text) to authenticated, service_role;
