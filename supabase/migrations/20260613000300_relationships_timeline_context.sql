create table public.entity_relationships (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  source_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  target_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  relationship_type_id uuid not null references public.relationship_types(id) on delete restrict,
  visibility text not null check (visibility in ('shared', 'gm_only')),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index entity_relationships_campaign_idx
  on public.entity_relationships (campaign_id, deleted_at, updated_at desc);
create index entity_relationships_source_idx
  on public.entity_relationships (source_entity_id, deleted_at, updated_at desc);
create index entity_relationships_target_idx
  on public.entity_relationships (target_entity_id, deleted_at, updated_at desc);

create trigger entity_relationships_set_updated_at
  before update on public.entity_relationships
  for each row execute function public.set_updated_at();

create or replace function public.can_manage_entity_relationships(p_campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can_view_gm_content(p_campaign_id)
$$;

create or replace function public.validate_entity_relationship()
returns trigger
language plpgsql
as $$
#variable_conflict use_column
declare
  v_source public.campaign_entities%rowtype;
  v_target public.campaign_entities%rowtype;
  v_type public.relationship_types%rowtype;
begin
  select *
  into v_source
  from public.campaign_entities
  where id = new.source_entity_id;

  if v_source.id is null or v_source.deleted_at is not null then
    raise exception 'Relationship source entity must exist and not be deleted';
  end if;

  select *
  into v_target
  from public.campaign_entities
  where id = new.target_entity_id;

  if v_target.id is null or v_target.deleted_at is not null then
    raise exception 'Relationship target entity must exist and not be deleted';
  end if;

  if v_source.campaign_id <> v_target.campaign_id then
    raise exception 'Relationships must stay within one campaign';
  end if;

  if new.campaign_id <> v_source.campaign_id then
    raise exception 'Relationship campaign must match both endpoint entities';
  end if;

  select *
  into v_type
  from public.relationship_types
  where id = new.relationship_type_id;

  if v_type.id is null or not v_type.is_active then
    raise exception 'Relationship type must be active';
  end if;

  if v_type.campaign_id is not null and v_type.campaign_id <> new.campaign_id then
    raise exception 'Campaign-scoped relationship types must belong to the same campaign';
  end if;

  if v_type.default_directionality = 'undirected'
    and new.source_entity_id::text > new.target_entity_id::text then
    new.source_entity_id := v_target.id;
    new.target_entity_id := v_source.id;
  end if;

  return new;
end;
$$;

create trigger entity_relationships_validate
  before insert or update of campaign_id, source_entity_id, target_entity_id, relationship_type_id
  on public.entity_relationships
  for each row execute function public.validate_entity_relationship();

create unique index entity_relationships_active_unique
  on public.entity_relationships (
    campaign_id,
    source_entity_id,
    target_entity_id,
    relationship_type_id,
    visibility
  )
  where deleted_at is null;

create or replace function public.assert_entity_relationship_visibility(
  p_campaign_id uuid,
  p_source_entity_id uuid,
  p_target_entity_id uuid,
  p_visibility text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_source_visibility text;
  v_target_visibility text;
begin
  if p_visibility not in ('shared', 'gm_only') then
    raise exception 'Relationship visibility must be shared or gm_only';
  end if;

  if p_visibility = 'shared' then
    select ce.default_visibility
    into v_source_visibility
    from public.campaign_entities ce
    where ce.id = p_source_entity_id
      and ce.campaign_id = p_campaign_id
      and ce.deleted_at is null;

    select ce.default_visibility
    into v_target_visibility
    from public.campaign_entities ce
    where ce.id = p_target_entity_id
      and ce.campaign_id = p_campaign_id
      and ce.deleted_at is null;

    if v_source_visibility is distinct from 'shared' or v_target_visibility is distinct from 'shared' then
      raise exception 'Shared relationships require shared-visible endpoints';
    end if;
  end if;
end;
$$;

create or replace function public.create_entity_relationship(
  p_source_entity_id uuid,
  p_target_entity_id uuid,
  p_relationship_type_id uuid,
  p_visibility text
)
returns table (
  relationship_id uuid,
  campaign_id uuid,
  source_entity_id uuid,
  target_entity_id uuid
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_campaign_id uuid;
  v_relationship public.entity_relationships%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select ce.campaign_id
  into v_campaign_id
  from public.campaign_entities ce
  where ce.id = p_source_entity_id
    and ce.deleted_at is null;

  if v_campaign_id is null then
    raise exception 'Relationship source entity must exist';
  end if;

  if not public.can_manage_entity_relationships(v_campaign_id) then
    raise exception 'Only owners and game masters can manage explicit relationships';
  end if;

  if not public.can_view_campaign_entity(p_source_entity_id) or not public.can_view_campaign_entity(p_target_entity_id) then
    raise exception 'Relationship endpoints must be visible to the caller';
  end if;

  perform public.assert_entity_relationship_visibility(
    v_campaign_id,
    p_source_entity_id,
    p_target_entity_id,
    p_visibility
  );

  update public.entity_relationships er
  set updated_by = v_user_id,
      updated_at = now()
  where er.campaign_id = v_campaign_id
    and er.source_entity_id = p_source_entity_id
    and er.target_entity_id = p_target_entity_id
    and er.relationship_type_id = p_relationship_type_id
    and er.visibility = p_visibility
    and er.deleted_at is null
  returning *
  into v_relationship;

  if v_relationship.id is null then
    insert into public.entity_relationships (
      campaign_id,
      source_entity_id,
      target_entity_id,
      relationship_type_id,
      visibility,
      created_by,
      updated_by
    )
    values (
      v_campaign_id,
      p_source_entity_id,
      p_target_entity_id,
      p_relationship_type_id,
      p_visibility,
      v_user_id,
      v_user_id
    )
    returning *
    into v_relationship;
  end if;

  return query
  select
    v_relationship.id,
    v_relationship.campaign_id,
    v_relationship.source_entity_id,
    v_relationship.target_entity_id;
end;
$$;

create or replace function public.update_entity_relationship(
  p_relationship_id uuid,
  p_relationship_type_id uuid,
  p_visibility text
)
returns table (
  relationship_id uuid,
  campaign_id uuid,
  source_entity_id uuid,
  target_entity_id uuid
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_relationship public.entity_relationships%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into v_relationship
  from public.entity_relationships
  where id = p_relationship_id
    and deleted_at is null;

  if v_relationship.id is null then
    raise exception 'Relationship not found';
  end if;

  if not public.can_manage_entity_relationships(v_relationship.campaign_id) then
    raise exception 'Only owners and game masters can manage explicit relationships';
  end if;

  perform public.assert_entity_relationship_visibility(
    v_relationship.campaign_id,
    v_relationship.source_entity_id,
    v_relationship.target_entity_id,
    p_visibility
  );

  update public.entity_relationships
  set relationship_type_id = p_relationship_type_id,
      visibility = p_visibility,
      updated_by = v_user_id
  where id = p_relationship_id
  returning *
  into v_relationship;

  return query
  select
    v_relationship.id,
    v_relationship.campaign_id,
    v_relationship.source_entity_id,
    v_relationship.target_entity_id;
end;
$$;

create or replace function public.soft_delete_entity_relationship(p_relationship_id uuid)
returns table (
  relationship_id uuid,
  campaign_id uuid,
  source_entity_id uuid,
  target_entity_id uuid
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.current_user_id();
  v_relationship public.entity_relationships%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into v_relationship
  from public.entity_relationships
  where id = p_relationship_id
    and deleted_at is null;

  if v_relationship.id is null then
    raise exception 'Relationship not found';
  end if;

  if not public.can_manage_entity_relationships(v_relationship.campaign_id) then
    raise exception 'Only owners and game masters can manage explicit relationships';
  end if;

  update public.entity_relationships
  set deleted_at = now(),
      updated_by = v_user_id
  where id = p_relationship_id
  returning *
  into v_relationship;

  return query
  select
    v_relationship.id,
    v_relationship.campaign_id,
    v_relationship.source_entity_id,
    v_relationship.target_entity_id;
end;
$$;

drop function if exists public.get_entity_relationships(uuid);

drop function if exists public.get_entity_relationships(uuid);

create function public.get_entity_relationships(
  p_entity_id uuid,
  p_role_view text default null
)
returns table (
  relationship_id uuid,
  campaign_id uuid,
  source_entity_id uuid,
  target_entity_id uuid,
  related_entity_id uuid,
  relationship_type_id uuid,
  relationship_type_key text,
  relation_direction text,
  label text,
  inverse_label text,
  visibility text,
  related_entity_label text,
  related_entity_type_key text,
  related_resolution_state text,
  can_edit boolean,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with anchor as (
    select ce.*
    from public.campaign_entities ce
    where ce.id = p_entity_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
  ),
  relationships as (
    select
      er.id as relationship_id,
      er.campaign_id,
      er.source_entity_id,
      er.target_entity_id,
      case
        when er.source_entity_id = p_entity_id then er.target_entity_id
        else er.source_entity_id
      end as related_entity_id,
      er.relationship_type_id,
      rt.key as relationship_type_key,
      rt.label,
      rt.inverse_label,
      rt.default_directionality,
      er.visibility,
      er.updated_at
    from anchor a
    join public.entity_relationships er
      on er.campaign_id = a.campaign_id
     and er.deleted_at is null
     and (er.source_entity_id = a.id or er.target_entity_id = a.id)
    join public.relationship_types rt on rt.id = er.relationship_type_id
    where (
      er.visibility = 'shared'
      or (
        er.visibility = 'gm_only'
        and not public.is_player_preview_role(p_role_view)
        and public.can_view_gm_content(er.campaign_id)
      )
    )
  )
  select
    r.relationship_id,
    r.campaign_id,
    r.source_entity_id,
    r.target_entity_id,
    case when public.can_view_campaign_entity_for_role(r.related_entity_id, p_role_view) then r.related_entity_id else null end,
    r.relationship_type_id,
    r.relationship_type_key,
    case
      when r.source_entity_id = p_entity_id then 'outgoing'
      else 'incoming'
    end as relation_direction,
    case
      when r.source_entity_id = p_entity_id then r.label
      when r.default_directionality = 'undirected' then r.label
      else coalesce(r.inverse_label, r.label)
    end as label,
    r.inverse_label,
    r.visibility,
    case
      when related_ce.id is null or related_ce.deleted_at is not null then 'Deleted record'
      when public.can_view_campaign_entity_for_role(related_ce.id, p_role_view) then related_ce.list_caption
      else 'Unavailable record'
    end as related_entity_label,
    case
      when public.can_view_campaign_entity_for_role(related_ce.id, p_role_view) then related_et.key
      when related_ce.deleted_at is not null and not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(r.campaign_id) then related_et.key
      else null
    end as related_entity_type_key,
    case
      when related_ce.id is null then 'hard_deleted'
      when public.can_view_campaign_entity_for_role(related_ce.id, p_role_view) then 'visible'
      when related_ce.deleted_at is not null and not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(r.campaign_id) then 'deleted'
      when related_ce.deleted_at is not null then 'hard_deleted'
      else 'inaccessible'
    end as related_resolution_state,
    case when public.is_player_preview_role(p_role_view) then false else public.can_manage_entity_relationships(r.campaign_id) end as can_edit,
    r.updated_at
  from relationships r
  left join public.campaign_entities related_ce on related_ce.id = r.related_entity_id
  left join public.entity_types related_et on related_et.id = related_ce.entity_type_id
  order by r.updated_at desc, lower(r.relationship_type_key), lower(coalesce(related_ce.list_caption, ''));
$$;

drop function if exists public.get_entity_related_records(uuid);

drop function if exists public.get_entity_related_records(uuid);

create function public.get_entity_related_records(
  p_entity_id uuid,
  p_role_view text default null
)
returns table (
  campaign_id uuid,
  source_entity_id uuid,
  target_entity_id uuid,
  related_entity_id uuid,
  relation_source text,
  relationship_type_key text,
  label text,
  visibility text,
  source_type text,
  source_note_id uuid,
  source_section_id uuid,
  source_contribution_id uuid,
  source_summary text,
  mention_count integer,
  related_entity_label text,
  related_entity_type_key text,
  related_resolution_state text,
  can_edit boolean,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with anchor as (
    select ce.*
    from public.campaign_entities ce
    where ce.id = p_entity_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
  ),
  explicit_rows as (
    select
      er.campaign_id,
      er.source_entity_id,
      er.target_entity_id,
      case
        when er.source_entity_id = p_entity_id then er.target_entity_id
        else er.source_entity_id
      end as related_entity_id,
      'explicit'::text as relation_source,
      rt.key as relationship_type_key,
      case
        when er.source_entity_id = p_entity_id then rt.label
        when rt.default_directionality = 'undirected' then rt.label
        else coalesce(rt.inverse_label, rt.label)
      end as label,
      er.visibility,
      'entity_relationship'::text as source_type,
      null::uuid as source_note_id,
      null::uuid as source_section_id,
      null::uuid as source_contribution_id,
      'Explicit relationship'::text as source_summary,
      null::integer as mention_count,
      case when public.is_player_preview_role(p_role_view) then false else public.can_manage_entity_relationships(er.campaign_id) end as can_edit,
      er.updated_at
    from anchor a
    join public.entity_relationships er
      on er.campaign_id = a.campaign_id
     and er.deleted_at is null
     and (er.source_entity_id = a.id or er.target_entity_id = a.id)
    join public.relationship_types rt on rt.id = er.relationship_type_id
    where (
      er.visibility = 'shared'
      or (
        er.visibility = 'gm_only'
        and not public.is_player_preview_role(p_role_view)
        and public.can_view_gm_content(er.campaign_id)
      )
    )
  ),
  structural_rows as (
    select
      ce.campaign_id,
      ce.id as source_entity_id,
      ce.parent_entity_id as target_entity_id,
      ce.parent_entity_id as related_entity_id,
      'structural'::text as relation_source,
      'parent_of'::text as relationship_type_key,
      'Parent'::text as label,
      ce.default_visibility as visibility,
      'campaign_entity'::text as source_type,
      null::uuid as source_note_id,
      null::uuid as source_section_id,
      null::uuid as source_contribution_id,
      'Parent link'::text as source_summary,
      null::integer as mention_count,
      false as can_edit,
      ce.updated_at
    from anchor a
    join public.campaign_entities ce on ce.id = a.id
    where ce.parent_entity_id is not null

    union all

    select
      child.campaign_id,
      child.id as source_entity_id,
      child.parent_entity_id as target_entity_id,
      child.id as related_entity_id,
      'structural'::text,
      'child_of'::text,
      'Child'::text,
      child.default_visibility,
      'campaign_entity'::text,
      null::uuid,
      null::uuid,
      null::uuid,
      'Child link'::text,
      null::integer,
      false,
      child.updated_at
    from anchor a
    join public.campaign_entities child
      on child.parent_entity_id = a.id
     and child.deleted_at is null
     and public.can_view_campaign_entity_for_role(child.id, p_role_view)

    union all

    select
      ce.campaign_id,
      ce.id,
      ce.related_session_entity_id,
      ce.related_session_entity_id,
      'structural'::text,
      'related_session'::text,
      'Related session'::text,
      ce.default_visibility,
      'campaign_entity'::text,
      null::uuid,
      null::uuid,
      null::uuid,
      'Session link'::text,
      null::integer,
      false,
      ce.updated_at
    from anchor a
    join public.campaign_entities ce on ce.id = a.id
    where ce.related_session_entity_id is not null

    union all

    select
      child.campaign_id,
      child.id,
      child.related_session_entity_id,
      child.id,
      'structural'::text,
      'session_related_record'::text,
      'Related record'::text,
      child.default_visibility,
      'campaign_entity'::text,
      null::uuid,
      null::uuid,
      null::uuid,
      'Session link'::text,
      null::integer,
      false,
      child.updated_at
    from anchor a
    join public.campaign_entities child
      on child.related_session_entity_id = a.id
     and child.deleted_at is null
     and public.can_view_campaign_entity_for_role(child.id, p_role_view)

    union all

    select
      ce.campaign_id,
      ce.id,
      e.related_storyline_entity_id,
      e.related_storyline_entity_id,
      'structural'::text,
      'related_storyline'::text,
      'Related storyline'::text,
      ce.default_visibility,
      'encounter'::text,
      null::uuid,
      null::uuid,
      null::uuid,
      'Storyline link'::text,
      null::integer,
      false,
      ce.updated_at
    from anchor a
    join public.campaign_entities ce on ce.id = a.id
    join public.encounters e on e.entity_id = ce.id
    where e.related_storyline_entity_id is not null

    union all

    select
      ce.campaign_id,
      ce.id,
      e.related_storyline_entity_id,
      ce.id,
      'structural'::text,
      'storyline_related_encounter'::text,
      'Related encounter'::text,
      ce.default_visibility,
      'encounter'::text,
      null::uuid,
      null::uuid,
      null::uuid,
      'Storyline link'::text,
      null::integer,
      false,
      ce.updated_at
    from anchor a
    join public.encounters e on e.related_storyline_entity_id = a.id
    join public.campaign_entities ce on ce.id = e.entity_id
    where ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
  ),
  note_mentions as (
    select
      source_entity.id as source_entity_id,
      m.mentioned_entity_id as target_entity_id,
      case
        when source_entity.id = p_entity_id then m.mentioned_entity_id
        else source_entity.id
      end as related_entity_id,
      note.visibility,
      'note'::text as source_type,
      note.id as source_note_id,
      null::uuid as source_section_id,
      null::uuid as source_contribution_id,
      coalesce(note.body_preview, left(note.body_text, 120), 'Mentioned in note') as source_summary,
      count(*)::integer as mention_count,
      max(note.updated_at) as updated_at
    from anchor a
    join public.rich_text_entity_mentions m
      on m.mentioned_entity_id = a.id
      or (
        exists (
          select 1
          from public.note_attachments na2
          where na2.note_id = m.source_note_id
            and na2.target_type = 'entity'
            and na2.entity_id = a.id
        )
      )
    join public.notes note
      on note.id = m.source_note_id
     and note.deleted_at is null
     and public.can_view_entity_visibility_for_role(
       note.campaign_id,
       note.visibility,
       note.author_user_id,
       p_entity_id,
       p_role_view
     )
    join public.note_attachments na
      on na.note_id = note.id
     and na.target_type = 'entity'
    join public.campaign_entities source_entity
      on source_entity.id = na.entity_id
     and source_entity.deleted_at is null
     and public.can_view_campaign_entity_for_role(source_entity.id, p_role_view)
    where source_entity.id <> m.mentioned_entity_id
      and (
        (m.mentioned_entity_id = a.id and source_entity.id <> a.id)
        or (source_entity.id = a.id and m.mentioned_entity_id <> a.id)
      )
    group by
      source_entity.id,
      m.mentioned_entity_id,
      note.visibility,
      note.id,
      note.body_preview,
      note.body_text
  ),
  section_mentions as (
    select
      source_entity.id as source_entity_id,
      m.mentioned_entity_id as target_entity_id,
      case
        when source_entity.id = p_entity_id then m.mentioned_entity_id
        else source_entity.id
      end as related_entity_id,
      section.visibility,
      'entity_section'::text as source_type,
      null::uuid as source_note_id,
      section.id as source_section_id,
      null::uuid as source_contribution_id,
      coalesce(section.body_preview, left(section.body_text, 120), section.label) as source_summary,
      count(*)::integer as mention_count,
      max(section.updated_at) as updated_at
    from anchor a
    join public.rich_text_entity_mentions m
      on m.mentioned_entity_id = a.id
      or exists (
        select 1
        from public.entity_sections es2
        where es2.id = m.source_section_id
          and es2.entity_id = a.id
      )
    join public.entity_sections section
      on section.id = m.source_section_id
     and public.can_view_entity_visibility_for_role(
       a.campaign_id,
       section.visibility,
       section.created_by,
       section.entity_id,
       p_role_view
     )
    join public.campaign_entities source_entity
      on source_entity.id = section.entity_id
     and source_entity.deleted_at is null
     and public.can_view_campaign_entity_for_role(source_entity.id, p_role_view)
    where source_entity.id <> m.mentioned_entity_id
      and (
        (m.mentioned_entity_id = a.id and source_entity.id <> a.id)
        or (source_entity.id = a.id and m.mentioned_entity_id <> a.id)
      )
    group by
      source_entity.id,
      m.mentioned_entity_id,
      section.visibility,
      section.id,
      section.body_preview,
      section.body_text,
      section.label
  ),
  contribution_mentions as (
    select
      source_entity.id as source_entity_id,
      m.mentioned_entity_id as target_entity_id,
      case
        when source_entity.id = p_entity_id then m.mentioned_entity_id
        else source_entity.id
      end as related_entity_id,
      contribution.visibility,
      'entity_section_contribution'::text as source_type,
      null::uuid as source_note_id,
      section.id as source_section_id,
      contribution.id as source_contribution_id,
      coalesce(contribution.body_preview, left(contribution.body_text, 120), section.label) as source_summary,
      count(*)::integer as mention_count,
      max(contribution.updated_at) as updated_at
    from anchor a
    join public.rich_text_entity_mentions m
      on m.mentioned_entity_id = a.id
      or exists (
        select 1
        from public.entity_section_contributions esc2
        join public.entity_sections es2 on es2.id = esc2.section_id
        where esc2.id = m.source_contribution_id
          and es2.entity_id = a.id
      )
    join public.entity_section_contributions contribution
      on contribution.id = m.source_contribution_id
     and contribution.deleted_at is null
     and public.can_view_entity_visibility_for_role(
       contribution.campaign_id,
       contribution.visibility,
       contribution.author_user_id,
       p_entity_id,
       p_role_view
     )
    join public.entity_sections section
      on section.id = contribution.section_id
     and public.can_view_entity_visibility_for_role(
       a.campaign_id,
       section.visibility,
       section.created_by,
       section.entity_id,
       p_role_view
     )
    join public.campaign_entities source_entity
      on source_entity.id = section.entity_id
     and source_entity.deleted_at is null
     and public.can_view_campaign_entity_for_role(source_entity.id, p_role_view)
    where source_entity.id <> m.mentioned_entity_id
      and (
        (m.mentioned_entity_id = a.id and source_entity.id <> a.id)
        or (source_entity.id = a.id and m.mentioned_entity_id <> a.id)
      )
    group by
      source_entity.id,
      m.mentioned_entity_id,
      contribution.visibility,
      contribution.id,
      section.id,
      contribution.body_preview,
      contribution.body_text,
      section.label
  ),
  mention_rows as (
    select
      a.campaign_id,
      m.source_entity_id,
      m.target_entity_id,
      m.related_entity_id,
      'mention'::text as relation_source,
      'mention'::text as relationship_type_key,
      case
        when m.source_entity_id = p_entity_id then 'Mentions'
        else 'Mentioned by'
      end as label,
      m.visibility,
      m.source_type,
      m.source_note_id,
      m.source_section_id,
      m.source_contribution_id,
      m.source_summary,
      m.mention_count,
      false as can_edit,
      m.updated_at
    from anchor a
    join (
      select * from note_mentions
      union all
      select * from section_mentions
      union all
      select * from contribution_mentions
    ) m on true
  ),
  combined as (
    select * from explicit_rows
    union all
    select * from structural_rows
    union all
    select * from mention_rows
  )
  select
    c.campaign_id,
    c.source_entity_id,
    c.target_entity_id,
    case when public.can_view_campaign_entity_for_role(c.related_entity_id, p_role_view) then c.related_entity_id else null end,
    c.relation_source,
    c.relationship_type_key,
    c.label,
    c.visibility,
    c.source_type,
    c.source_note_id,
    c.source_section_id,
    c.source_contribution_id,
    c.source_summary,
    c.mention_count,
    case
      when related_ce.id is null or related_ce.deleted_at is not null then 'Deleted record'
      when public.can_view_campaign_entity_for_role(related_ce.id, p_role_view) then related_ce.list_caption
      else 'Unavailable record'
    end as related_entity_label,
    case
      when public.can_view_campaign_entity_for_role(related_ce.id, p_role_view) then related_et.key
      when related_ce.deleted_at is not null and not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(c.campaign_id) then related_et.key
      else null
    end as related_entity_type_key,
    case
      when related_ce.id is null then 'hard_deleted'
      when public.can_view_campaign_entity_for_role(related_ce.id, p_role_view) then 'visible'
      when related_ce.deleted_at is not null and not public.is_player_preview_role(p_role_view) and public.can_view_gm_content(c.campaign_id) then 'deleted'
      when related_ce.deleted_at is not null then 'hard_deleted'
      else 'inaccessible'
    end as related_resolution_state,
    c.can_edit,
    c.updated_at
  from combined c
  left join public.campaign_entities related_ce on related_ce.id = c.related_entity_id
  left join public.entity_types related_et on related_et.id = related_ce.entity_type_id
  where (
    not public.is_player_preview_role(p_role_view)
    or related_ce.id is null
    or related_ce.deleted_at is not null
    or public.can_view_campaign_entity_for_role(c.related_entity_id, p_role_view)
  )
  order by
    case c.relation_source
      when 'explicit' then 1
      when 'structural' then 2
      else 3
    end,
    c.updated_at desc,
    lower(c.source_summary),
    lower(c.label);
$$;

drop function if exists public.get_timeline_events(uuid, text, uuid, uuid, text);

create function public.get_timeline_events(
  p_campaign_id uuid,
  p_event_type_key text default null,
  p_related_session_entity_id uuid default null,
  p_related_entity_id uuid default null,
  p_visibility text default null,
  p_role_view text default null
)
returns table (
  campaign_id uuid,
  entity_id uuid,
  list_caption text,
  default_visibility text,
  updated_at timestamptz,
  date_expression text,
  sort_key text,
  event_type_key text,
  event_type_label text,
  related_session_entity_id uuid,
  related_session_label text,
  primary_location_entity_id uuid,
  primary_location_label text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with visible_events as (
    select
      ce.campaign_id,
      ce.id as entity_id,
      ce.list_caption,
      ce.default_visibility,
      ce.updated_at,
      te.date_expression,
      te.sort_key,
      timeline_type.key as event_type_key,
      timeline_type.label as event_type_label,
      case when public.can_view_campaign_entity_for_role(te.related_session_entity_id, p_role_view) then te.related_session_entity_id else null end as related_session_entity_id,
      public.entity_ref_label_for_role(te.related_session_entity_id, p_role_view) as related_session_label,
      case when public.can_view_campaign_entity_for_role(te.primary_location_entity_id, p_role_view) then te.primary_location_entity_id else null end as primary_location_entity_id,
      public.entity_ref_label_for_role(te.primary_location_entity_id, p_role_view) as primary_location_label
    from public.campaign_entities ce
    join public.timeline_events te on te.entity_id = ce.id
    left join public.campaign_options timeline_type on timeline_type.id = te.event_type_option_id
    where ce.campaign_id = p_campaign_id
      and ce.deleted_at is null
      and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
      and (p_event_type_key is null or timeline_type.key = p_event_type_key)
      and (p_related_session_entity_id is null or te.related_session_entity_id = p_related_session_entity_id)
      and (
        p_visibility is null
        or ce.default_visibility = p_visibility
      )
  )
  select ve.*
  from visible_events ve
  where (
    p_related_entity_id is null
    or ve.related_session_entity_id = p_related_entity_id
    or ve.primary_location_entity_id = p_related_entity_id
    or exists (
      select 1
      from public.entity_relationships er
      join public.relationship_types rt on rt.id = er.relationship_type_id
      where er.deleted_at is null
        and (
          (er.source_entity_id = ve.entity_id and er.target_entity_id = p_related_entity_id)
          or (er.target_entity_id = ve.entity_id and er.source_entity_id = p_related_entity_id)
        )
        and (
          er.visibility = 'shared'
          or (
            er.visibility = 'gm_only'
            and not public.is_player_preview_role(p_role_view)
            and public.can_view_gm_content(ve.campaign_id)
          )
        )
    )
  )
  order by
    case when ve.sort_key is null or trim(ve.sort_key) = '' then 1 else 0 end,
    ve.sort_key nulls last,
    lower(ve.date_expression),
    lower(ve.list_caption);
$$;

alter table public.entity_relationships enable row level security;

revoke all on table public.entity_relationships from public, anon, authenticated;
revoke all on function public.validate_entity_relationship() from public, anon, authenticated;
revoke all on function public.can_manage_entity_relationships(uuid) from public, anon;
revoke all on function public.assert_entity_relationship_visibility(uuid, uuid, uuid, text) from public, anon;
revoke all on function public.create_entity_relationship(uuid, uuid, uuid, text) from public, anon;
revoke all on function public.update_entity_relationship(uuid, uuid, text) from public, anon;
revoke all on function public.soft_delete_entity_relationship(uuid) from public, anon;
revoke all on function public.get_entity_relationships(uuid, text) from public, anon;
revoke all on function public.get_entity_related_records(uuid, text) from public, anon;
revoke all on function public.get_timeline_events(uuid, text, uuid, uuid, text, text) from public, anon;

grant execute on function public.can_manage_entity_relationships(uuid) to authenticated, service_role;
grant execute on function public.assert_entity_relationship_visibility(uuid, uuid, uuid, text) to authenticated, service_role;
grant execute on function public.create_entity_relationship(uuid, uuid, uuid, text) to authenticated, service_role;
grant execute on function public.update_entity_relationship(uuid, uuid, text) to authenticated, service_role;
grant execute on function public.soft_delete_entity_relationship(uuid) to authenticated, service_role;
grant execute on function public.get_entity_relationships(uuid, text) to authenticated, service_role;
grant execute on function public.get_entity_related_records(uuid, text) to authenticated, service_role;
grant execute on function public.get_timeline_events(uuid, text, uuid, uuid, text, text) to authenticated, service_role;
