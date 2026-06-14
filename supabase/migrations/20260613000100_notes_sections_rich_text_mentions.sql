create table public.notes (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  author_user_id uuid not null references auth.users(id) on delete restrict,
  visibility text not null check (visibility in ('shared', 'gm_only', 'private', 'character_owner_gm')),
  body_json jsonb not null default '{"type":"doc","content":[{"type":"paragraph"}]}'::jsonb,
  body_text text not null default '',
  body_preview text,
  version_number integer not null default 1 check (version_number > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.note_attachments (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.notes(id) on delete cascade,
  target_type text not null check (target_type in ('campaign', 'entity')),
  entity_id uuid references public.campaign_entities(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint note_attachments_target_check check (
    (target_type = 'campaign' and entity_id is null)
    or (target_type = 'entity' and entity_id is not null)
  ),
  constraint note_attachments_unique unique (note_id, target_type, entity_id)
);

create table public.entity_section_contributions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  section_id uuid not null references public.entity_sections(id) on delete cascade,
  author_user_id uuid not null references auth.users(id) on delete restrict,
  visibility text not null check (visibility in ('shared', 'gm_only', 'private', 'character_owner_gm')),
  body_json jsonb not null default '{"type":"doc","content":[{"type":"paragraph"}]}'::jsonb,
  body_text text not null default '',
  body_preview text,
  version_number integer not null default 1 check (version_number > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.rich_text_entity_mentions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  source_type text not null check (source_type in ('note', 'entity_section', 'entity_section_contribution')),
  source_note_id uuid references public.notes(id) on delete cascade,
  source_section_id uuid references public.entity_sections(id) on delete cascade,
  source_contribution_id uuid references public.entity_section_contributions(id) on delete cascade,
  mentioned_entity_id uuid not null references public.campaign_entities(id) on delete cascade,
  mention_text text not null,
  created_at timestamptz not null default now(),
  constraint rich_text_entity_mentions_source_check check (
    (source_type = 'note' and source_note_id is not null and source_section_id is null and source_contribution_id is null)
    or (source_type = 'entity_section' and source_note_id is null and source_section_id is not null and source_contribution_id is null)
    or (source_type = 'entity_section_contribution' and source_note_id is null and source_section_id is null and source_contribution_id is not null)
  )
);

create index notes_campaign_idx on public.notes (campaign_id, deleted_at, updated_at desc);
create index note_attachments_note_idx on public.note_attachments (note_id);
create index note_attachments_entity_idx on public.note_attachments (entity_id) where entity_id is not null;
create index entity_section_contributions_section_idx
  on public.entity_section_contributions (section_id, deleted_at, updated_at desc);
create index rich_text_entity_mentions_mentioned_idx
  on public.rich_text_entity_mentions (mentioned_entity_id, created_at desc);
create index rich_text_entity_mentions_note_idx
  on public.rich_text_entity_mentions (source_note_id)
  where source_note_id is not null;
create index rich_text_entity_mentions_section_idx
  on public.rich_text_entity_mentions (source_section_id)
  where source_section_id is not null;
create index rich_text_entity_mentions_contribution_idx
  on public.rich_text_entity_mentions (source_contribution_id)
  where source_contribution_id is not null;

create trigger notes_set_updated_at
  before update on public.notes
  for each row execute function public.set_updated_at();

create trigger entity_section_contributions_set_updated_at
  before update on public.entity_section_contributions
  for each row execute function public.set_updated_at();

create or replace function public.validate_note_attachment_campaign()
returns trigger
language plpgsql
as $$
declare
  v_note_campaign_id uuid;
  v_entity_campaign_id uuid;
begin
  select n.campaign_id
  into v_note_campaign_id
  from public.notes n
  where n.id = new.note_id;

  if v_note_campaign_id is null then
    raise exception 'Note attachment must reference an existing note';
  end if;

  if new.target_type = 'entity' then
    select ce.campaign_id
    into v_entity_campaign_id
    from public.campaign_entities ce
    where ce.id = new.entity_id
      and ce.deleted_at is null;

    if v_entity_campaign_id is distinct from v_note_campaign_id then
      raise exception 'Note attachment entity must belong to the same campaign';
    end if;
  end if;

  return new;
end;
$$;

create trigger note_attachments_validate_campaign
  before insert or update of note_id, target_type, entity_id
  on public.note_attachments
  for each row execute function public.validate_note_attachment_campaign();

create or replace function public.validate_entity_section_contribution()
returns trigger
language plpgsql
as $$
declare
  v_section public.entity_sections%rowtype;
  v_entity_campaign_id uuid;
begin
  select es.*
  into v_section
  from public.entity_sections es
  where es.id = new.section_id;

  if v_section.id is null then
    raise exception 'Contribution must reference an existing section';
  end if;

  select ce.campaign_id
  into v_entity_campaign_id
  from public.campaign_entities ce
  where ce.id = v_section.entity_id
    and ce.deleted_at is null;

  if v_entity_campaign_id is null or new.campaign_id <> v_entity_campaign_id then
    raise exception 'Contribution campaign must match the parent section campaign';
  end if;

  if v_section.content_mode <> 'contribution_feed' and v_section.edit_policy <> 'append_contributions' then
    raise exception 'Contributions require a contribution-enabled section';
  end if;

  return new;
end;
$$;

create trigger entity_section_contributions_validate
  before insert or update of campaign_id, section_id
  on public.entity_section_contributions
  for each row execute function public.validate_entity_section_contribution();

create or replace function public.validate_rich_text_document(p_body_json jsonb)
returns boolean
language plpgsql
immutable
as $$
begin
  return jsonb_typeof(p_body_json) = 'object'
    and p_body_json ? 'type'
    and p_body_json->>'type' = 'doc';
exception
  when others then
    return false;
end;
$$;

create or replace function public.validate_rich_text_mark(p_mark jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  v_type text;
  v_href text;
begin
  if jsonb_typeof(p_mark) <> 'object' then
    return false;
  end if;

  v_type := p_mark->>'type';

  if v_type not in ('bold', 'italic', 'code', 'link') then
    return false;
  end if;

  if v_type = 'link' then
    v_href := p_mark->'attrs'->>'href';

    if v_href is null or v_href !~* '^https?://' then
      return false;
    end if;
  end if;

  return true;
end;
$$;

create or replace function public.validate_rich_text_node(p_node jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  v_type text;
  v_child jsonb;
  v_mark jsonb;
begin
  if jsonb_typeof(p_node) <> 'object' then
    return false;
  end if;

  v_type := p_node->>'type';

  if v_type not in (
    'doc',
    'paragraph',
    'text',
    'heading',
    'bulletList',
    'orderedList',
    'listItem',
    'blockquote',
    'horizontalRule',
    'mention',
    'hardBreak'
  ) then
    return false;
  end if;

  if p_node ? 'marks' then
    if jsonb_typeof(p_node->'marks') <> 'array' then
      return false;
    end if;

    for v_mark in select value from jsonb_array_elements(p_node->'marks')
    loop
      if not public.validate_rich_text_mark(v_mark) then
        return false;
      end if;
    end loop;
  end if;

  if v_type = 'text' and jsonb_typeof(p_node->'text') <> 'string' then
    return false;
  end if;

  if v_type = 'heading' then
    if jsonb_typeof(p_node->'attrs') <> 'object' then
      return false;
    end if;

    if coalesce((p_node->'attrs'->>'level')::integer, 0) not between 1 and 3 then
      return false;
    end if;
  end if;

  if v_type = 'mention' then
    if jsonb_typeof(p_node->'attrs') <> 'object' then
      return false;
    end if;

    if nullif(p_node->'attrs'->>'entityId', '') is null then
      return false;
    end if;

    if nullif(trim(coalesce(p_node->'attrs'->>'label', '')), '') is null then
      return false;
    end if;
  end if;

  if p_node ? 'content' then
    if jsonb_typeof(p_node->'content') <> 'array' then
      return false;
    end if;

    for v_child in select value from jsonb_array_elements(p_node->'content')
    loop
      if not public.validate_rich_text_node(v_child) then
        return false;
      end if;
    end loop;
  end if;

  return true;
end;
$$;

create or replace function public.derive_rich_text_text_from_node(p_node jsonb)
returns text
language plpgsql
immutable
as $$
declare
  v_type text;
  v_child jsonb;
  v_text text := '';
begin
  v_type := p_node->>'type';

  if v_type = 'text' then
    return coalesce(p_node->>'text', '');
  end if;

  if v_type = 'mention' then
    return '@' || coalesce(p_node->'attrs'->>'label', '');
  end if;

  if v_type = 'horizontalRule' then
    return '---';
  end if;

  if v_type = 'hardBreak' then
    return E'\n';
  end if;

  if p_node ? 'content' then
    for v_child in select value from jsonb_array_elements(p_node->'content')
    loop
      v_text := v_text || public.derive_rich_text_text_from_node(v_child);
    end loop;
  end if;

  if v_type in ('paragraph', 'heading', 'blockquote', 'listItem') and v_text <> '' then
    return v_text || E'\n';
  end if;

  return v_text;
end;
$$;

create or replace function public.extract_rich_text_mentions_from_node(p_node jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_type text;
  v_child jsonb;
  v_mentions jsonb := '[]'::jsonb;
begin
  v_type := p_node->>'type';

  if v_type = 'mention' then
    return jsonb_build_array(
      jsonb_build_object(
        'entity_id', p_node->'attrs'->>'entityId',
        'label', trim(p_node->'attrs'->>'label')
      )
    );
  end if;

  if p_node ? 'content' then
    for v_child in select value from jsonb_array_elements(p_node->'content')
    loop
      v_mentions := v_mentions || public.extract_rich_text_mentions_from_node(v_child);
    end loop;
  end if;

  return v_mentions;
end;
$$;

create or replace function public.derive_rich_text_payload(p_body_json jsonb)
returns table (
  body_text text,
  body_preview text,
  mentions jsonb
)
language plpgsql
immutable
as $$
declare
  v_body_text text;
begin
  if not public.validate_rich_text_document(p_body_json) or not public.validate_rich_text_node(p_body_json) then
    raise exception 'Invalid rich text document';
  end if;

  v_body_text := btrim(
    regexp_replace(public.derive_rich_text_text_from_node(p_body_json), E'\\n{3,}', E'\\n\\n', 'g'),
    E' \n\r\t'
  );

  return query
  select
    v_body_text,
    nullif(left(v_body_text, 280), ''),
    public.extract_rich_text_mentions_from_node(p_body_json);
end;
$$;

create or replace function public.assert_rich_text_payload_matches(
  p_body_json jsonb,
  p_body_text text,
  p_body_preview text,
  p_mentions jsonb
)
returns void
language plpgsql
immutable
as $$
declare
  v_payload record;
begin
  select *
  into v_payload
  from public.derive_rich_text_payload(p_body_json);

  if coalesce(p_body_text, '') <> coalesce(v_payload.body_text, '') then
    raise exception 'Rich text body_text mismatch';
  end if;

  if coalesce(p_body_preview, '') <> coalesce(v_payload.body_preview, '') then
    raise exception 'Rich text body_preview mismatch';
  end if;

  if coalesce(p_mentions, '[]'::jsonb) <> coalesce(v_payload.mentions, '[]'::jsonb) then
    raise exception 'Rich text mentions mismatch';
  end if;
end;
$$;

create or replace function public.resolve_note_visibility_entity_from_inputs(
  p_visibility text,
  p_attach_to_campaign boolean,
  p_entity_ids uuid[]
)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_visibility <> 'character_owner_gm' then
    return null;
  end if;

  if coalesce(p_attach_to_campaign, false) or coalesce(array_length(p_entity_ids, 1), 0) <> 1 then
    raise exception 'character_owner_gm notes require exactly one entity attachment';
  end if;

  return p_entity_ids[1];
end;
$$;

create or replace function public.resolve_note_visibility_entity(p_note_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when n.visibility <> 'character_owner_gm' then null
    when exists (
      select 1
      from public.note_attachments na
      where na.note_id = n.id
        and na.target_type = 'campaign'
    ) then null
    when (
      select count(*)
      from public.note_attachments na
      where na.note_id = n.id
        and na.target_type = 'entity'
    ) = 1 then (
      select na.entity_id
      from public.note_attachments na
      where na.note_id = n.id
        and na.target_type = 'entity'
      limit 1
    )
    else null
  end
  from public.notes n
  where n.id = p_note_id;
$$;

create or replace function public.note_has_visible_attachment(p_note_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.note_attachments na
    join public.notes n on n.id = na.note_id
    where na.note_id = p_note_id
      and (
        na.target_type = 'campaign'
        or (na.target_type = 'entity' and public.can_view_campaign_entity(na.entity_id))
      )
      and public.is_campaign_member(n.campaign_id)
  );
$$;

create or replace function public.can_view_note(p_note_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.notes n
    where n.id = p_note_id
      and n.deleted_at is null
      and public.is_campaign_member(n.campaign_id)
      and public.can_view_entity_visibility(
        n.campaign_id,
        n.visibility,
        n.author_user_id,
        public.resolve_note_visibility_entity(n.id)
      )
      and public.note_has_visible_attachment(n.id)
  );
$$;

create or replace function public.can_edit_note(p_note_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.notes n
    where n.id = p_note_id
      and n.deleted_at is null
      and public.can_view_note(n.id)
      and (
        n.author_user_id = public.current_user_id()
        or (n.visibility <> 'private' and public.can_view_gm_content(n.campaign_id))
      )
  );
$$;

create or replace function public.can_edit_entity_section(p_section_id uuid)
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
    join public.entity_types et on et.id = ce.entity_type_id
    left join public.characters ch on ch.entity_id = ce.id
    where es.id = p_section_id
      and public.can_view_campaign_entity(ce.id)
      and public.can_view_entity_visibility(ce.campaign_id, es.visibility, es.created_by, es.entity_id)
      and es.content_mode <> 'contribution_feed'
      and (
        public.can_view_gm_content(ce.campaign_id)
        or (es.edit_policy = 'player_edit' and public.is_campaign_member(ce.campaign_id))
        or (
          es.edit_policy = 'owner_edit'
          and (
            (et.key = 'character' and ch.controlling_user_id = public.current_user_id())
            or es.created_by = public.current_user_id()
          )
        )
      )
  );
$$;

create or replace function public.can_view_entity_section_contribution(p_contribution_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.entity_section_contributions esc
    join public.entity_sections es on es.id = esc.section_id
    join public.campaign_entities ce on ce.id = es.entity_id
    where esc.id = p_contribution_id
      and esc.deleted_at is null
      and public.can_view_campaign_entity(ce.id)
      and public.can_view_entity_visibility(ce.campaign_id, es.visibility, es.created_by, es.entity_id)
      and public.can_view_entity_visibility(esc.campaign_id, esc.visibility, esc.author_user_id, es.entity_id)
  );
$$;

create or replace function public.can_edit_entity_section_contribution(p_contribution_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.entity_section_contributions esc
    where esc.id = p_contribution_id
      and esc.deleted_at is null
      and public.can_view_entity_section_contribution(esc.id)
      and (
        esc.author_user_id = public.current_user_id()
        or (esc.visibility <> 'private' and public.can_view_gm_content(esc.campaign_id))
      )
  );
$$;

create or replace function public.validate_mentions_payload(
  p_campaign_id uuid,
  p_mentions jsonb
)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_item jsonb;
  v_entity_id uuid;
  v_mention_text text;
begin
  if p_mentions is null then
    return;
  end if;

  if jsonb_typeof(p_mentions) <> 'array' then
    raise exception 'Mention payload must be an array';
  end if;

  for v_item in select value from jsonb_array_elements(p_mentions)
  loop
    v_entity_id := nullif(v_item->>'entity_id', '')::uuid;
    v_mention_text := nullif(trim(coalesce(v_item->>'label', '')), '');

    if v_entity_id is null or v_mention_text is null then
      raise exception 'Mention payload is missing entity id or label';
    end if;

    if not exists (
      select 1
      from public.campaign_entities ce
      where ce.id = v_entity_id
        and ce.campaign_id = p_campaign_id
        and ce.deleted_at is null
    ) then
      raise exception 'Mention target must belong to the same campaign';
    end if;
  end loop;
end;
$$;

create or replace function public.replace_rich_text_mentions(
  p_campaign_id uuid,
  p_source_type text,
  p_source_note_id uuid default null,
  p_source_section_id uuid default null,
  p_source_contribution_id uuid default null,
  p_mentions jsonb default '[]'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_item jsonb;
begin
  perform public.validate_mentions_payload(p_campaign_id, p_mentions);

  delete from public.rich_text_entity_mentions rtem
  where (
    p_source_type = 'note'
    and rtem.source_type = 'note'
    and rtem.source_note_id = p_source_note_id
  ) or (
    p_source_type = 'entity_section'
    and rtem.source_type = 'entity_section'
    and rtem.source_section_id = p_source_section_id
  ) or (
    p_source_type = 'entity_section_contribution'
    and rtem.source_type = 'entity_section_contribution'
    and rtem.source_contribution_id = p_source_contribution_id
  );

  if p_mentions is null or jsonb_array_length(p_mentions) = 0 then
    return;
  end if;

  for v_item in select value from jsonb_array_elements(p_mentions)
  loop
    insert into public.rich_text_entity_mentions (
      campaign_id,
      source_type,
      source_note_id,
      source_section_id,
      source_contribution_id,
      mentioned_entity_id,
      mention_text
    )
    values (
      p_campaign_id,
      p_source_type,
      p_source_note_id,
      p_source_section_id,
      p_source_contribution_id,
      (v_item->>'entity_id')::uuid,
      trim(v_item->>'label')
    );
  end loop;
end;
$$;

create or replace function public.create_note(
  p_campaign_id uuid,
  p_visibility text,
  p_body_json jsonb,
  p_body_text text,
  p_body_preview text,
  p_mentions jsonb default '[]'::jsonb,
  p_attach_to_campaign boolean default false,
  p_entity_ids uuid[] default null
)
returns table (
  note_id uuid,
  campaign_id uuid,
  visibility text,
  version_number integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_note_id uuid;
  v_entity_id uuid;
  v_visibility_entity_id uuid;
begin
  if public.current_user_id() is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_campaign_member(p_campaign_id) then
    raise exception 'Campaign membership required';
  end if;

  perform public.assert_rich_text_payload_matches(p_body_json, p_body_text, p_body_preview, p_mentions);

  if coalesce(p_attach_to_campaign, false) = false and coalesce(array_length(p_entity_ids, 1), 0) = 0 then
    raise exception 'Notes require at least one attachment';
  end if;

  v_visibility_entity_id := public.resolve_note_visibility_entity_from_inputs(
    p_visibility,
    p_attach_to_campaign,
    p_entity_ids
  );

  if not public.can_view_entity_visibility(
    p_campaign_id,
    p_visibility,
    public.current_user_id(),
    v_visibility_entity_id
  ) then
    raise exception 'Invalid note visibility for current user';
  end if;

  insert into public.notes (
    campaign_id,
    author_user_id,
    visibility,
    body_json,
    body_text,
    body_preview,
    created_by,
    updated_by
  )
  values (
    p_campaign_id,
    public.current_user_id(),
    p_visibility,
    p_body_json,
    coalesce(p_body_text, ''),
    p_body_preview,
    public.current_user_id(),
    public.current_user_id()
  )
  returning id into v_note_id;

  if coalesce(p_attach_to_campaign, false) then
    insert into public.note_attachments (note_id, target_type, created_by)
    values (v_note_id, 'campaign', public.current_user_id());
  end if;

  foreach v_entity_id in array coalesce(p_entity_ids, array[]::uuid[])
  loop
    if not public.can_view_campaign_entity(v_entity_id) then
      raise exception 'Cannot attach note to an inaccessible entity';
    end if;

    insert into public.note_attachments (note_id, target_type, entity_id, created_by)
    values (v_note_id, 'entity', v_entity_id, public.current_user_id());
  end loop;

  perform public.replace_rich_text_mentions(
    p_campaign_id,
    'note',
    v_note_id,
    null,
    null,
    p_mentions
  );

  return query
  select n.id, n.campaign_id, n.visibility, n.version_number
  from public.notes n
  where n.id = v_note_id;
end;
$$;

create or replace function public.update_note_body(
  p_note_id uuid,
  p_visibility text,
  p_body_json jsonb,
  p_body_text text,
  p_body_preview text,
  p_mentions jsonb,
  p_expected_version integer
)
returns table (
  note_id uuid,
  campaign_id uuid,
  visibility text,
  version_number integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_note public.notes%rowtype;
  v_visibility_entity_id uuid;
begin
  if not public.can_edit_note(p_note_id) then
    raise exception 'Note edit not permitted';
  end if;

  perform public.assert_rich_text_payload_matches(p_body_json, p_body_text, p_body_preview, p_mentions);

  select *
  into v_note
  from public.notes n
  where n.id = p_note_id
    and n.deleted_at is null;

  if v_note.id is null then
    raise exception 'Note not found';
  end if;

  if v_note.version_number <> p_expected_version then
    raise exception 'stale_conflict';
  end if;

  v_visibility_entity_id := public.resolve_note_visibility_entity(p_note_id);

  if not public.can_view_entity_visibility(
    v_note.campaign_id,
    p_visibility,
    v_note.author_user_id,
    v_visibility_entity_id
  ) then
    raise exception 'Invalid note visibility for current user';
  end if;

  update public.notes
  set visibility = p_visibility,
      body_json = p_body_json,
      body_text = coalesce(p_body_text, ''),
      body_preview = p_body_preview,
      version_number = public.notes.version_number + 1,
      updated_by = public.current_user_id()
  where id = p_note_id;

  perform public.replace_rich_text_mentions(
    v_note.campaign_id,
    'note',
    p_note_id,
    null,
    null,
    p_mentions
  );

  return query
  select n.id, n.campaign_id, n.visibility, n.version_number
  from public.notes n
  where n.id = p_note_id;
end;
$$;

create or replace function public.attach_note_target(
  p_note_id uuid,
  p_target_type text,
  p_entity_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_campaign_id uuid;
begin
  if not public.can_edit_note(p_note_id) then
    raise exception 'Note edit not permitted';
  end if;

  select campaign_id
  into v_campaign_id
  from public.notes
  where id = p_note_id
    and deleted_at is null;

  if v_campaign_id is null then
    raise exception 'Note not found';
  end if;

  if p_target_type = 'campaign' then
    insert into public.note_attachments (note_id, target_type, created_by)
    values (p_note_id, 'campaign', public.current_user_id())
    on conflict do nothing;
    return;
  end if;

  if p_target_type <> 'entity' or p_entity_id is null then
    raise exception 'Entity attachment requires an entity id';
  end if;

  if not public.can_view_campaign_entity(p_entity_id) then
    raise exception 'Cannot attach note to an inaccessible entity';
  end if;

  insert into public.note_attachments (note_id, target_type, entity_id, created_by)
  values (p_note_id, 'entity', p_entity_id, public.current_user_id())
  on conflict do nothing;

  if exists (
    select 1
    from public.notes n
    where n.id = p_note_id
      and n.visibility = 'character_owner_gm'
      and public.resolve_note_visibility_entity(p_note_id) is null
  ) then
    raise exception 'character_owner_gm notes require exactly one entity attachment';
  end if;
end;
$$;

create or replace function public.detach_note_target(
  p_note_id uuid,
  p_target_type text,
  p_entity_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_remaining_count integer;
begin
  if not public.can_edit_note(p_note_id) then
    raise exception 'Note edit not permitted';
  end if;

  delete from public.note_attachments
  where note_id = p_note_id
    and target_type = p_target_type
    and (
      (p_target_type = 'campaign' and entity_id is null)
      or (p_target_type = 'entity' and entity_id = p_entity_id)
    );

  select count(*)
  into v_remaining_count
  from public.note_attachments
  where note_id = p_note_id;

  if v_remaining_count = 0 then
    raise exception 'Notes require at least one attachment';
  end if;

  if exists (
    select 1
    from public.notes n
    where n.id = p_note_id
      and n.visibility = 'character_owner_gm'
      and public.resolve_note_visibility_entity(p_note_id) is null
  ) then
    raise exception 'character_owner_gm notes require exactly one entity attachment';
  end if;
end;
$$;

create or replace function public.soft_delete_note(p_note_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.can_edit_note(p_note_id) then
    raise exception 'Note delete not permitted';
  end if;

  update public.notes
  set deleted_at = now(),
      updated_by = public.current_user_id()
  where id = p_note_id
    and deleted_at is null;
end;
$$;

create or replace function public.save_entity_section_body(
  p_section_id uuid,
  p_body_json jsonb,
  p_body_text text,
  p_body_preview text,
  p_mentions jsonb,
  p_expected_version integer
)
returns table (
  section_id uuid,
  entity_id uuid,
  version_number integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_section public.entity_sections%rowtype;
  v_campaign_id uuid;
begin
  if not public.can_edit_entity_section(p_section_id) then
    raise exception 'Section edit not permitted';
  end if;

  perform public.assert_rich_text_payload_matches(p_body_json, p_body_text, p_body_preview, p_mentions);

  select es.*
  into v_section
  from public.entity_sections es
  join public.campaign_entities ce on ce.id = es.entity_id
  where es.id = p_section_id;

  if v_section.id is null then
    raise exception 'Section not found';
  end if;

  select ce.campaign_id
  into v_campaign_id
  from public.campaign_entities ce
  where ce.id = v_section.entity_id;

  if v_section.version_number <> p_expected_version then
    raise exception 'stale_conflict';
  end if;

  update public.entity_sections
  set body_json = p_body_json,
      body_text = coalesce(p_body_text, ''),
      body_preview = p_body_preview,
      version_number = public.entity_sections.version_number + 1,
      updated_by = public.current_user_id()
  where id = p_section_id;

  perform public.replace_rich_text_mentions(
    v_campaign_id,
    'entity_section',
    null,
    p_section_id,
    null,
    p_mentions
  );

  return query
  select es.id, es.entity_id, es.version_number
  from public.entity_sections es
  where es.id = p_section_id;
end;
$$;

create or replace function public.create_entity_section_contribution(
  p_section_id uuid,
  p_visibility text,
  p_body_json jsonb,
  p_body_text text,
  p_body_preview text,
  p_mentions jsonb default '[]'::jsonb
)
returns table (
  contribution_id uuid,
  section_id uuid,
  campaign_id uuid,
  visibility text,
  version_number integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_section public.entity_sections%rowtype;
  v_campaign_id uuid;
  v_contribution_id uuid;
begin
  if public.current_user_id() is null then
    raise exception 'Authentication required';
  end if;

  perform public.assert_rich_text_payload_matches(p_body_json, p_body_text, p_body_preview, p_mentions);

  select es.*
  into v_section
  from public.entity_sections es
  join public.campaign_entities ce on ce.id = es.entity_id
  where es.id = p_section_id
    and ce.deleted_at is null;

  if v_section.id is null then
    raise exception 'Section not found';
  end if;

  select ce.campaign_id
  into v_campaign_id
  from public.campaign_entities ce
  where ce.id = v_section.entity_id
    and ce.deleted_at is null;

  if not public.can_view_campaign_entity(v_section.entity_id) then
    raise exception 'Section unavailable';
  end if;

  if v_section.content_mode <> 'contribution_feed' and v_section.edit_policy <> 'append_contributions' then
    raise exception 'Section does not accept contributions';
  end if;

  if not public.can_view_entity_visibility(v_campaign_id, p_visibility, public.current_user_id(), v_section.entity_id) then
    raise exception 'Invalid contribution visibility';
  end if;

  insert into public.entity_section_contributions (
    campaign_id,
    section_id,
    author_user_id,
    visibility,
    body_json,
    body_text,
    body_preview,
    created_by,
    updated_by
  )
  values (
    v_campaign_id,
    p_section_id,
    public.current_user_id(),
    p_visibility,
    p_body_json,
    coalesce(p_body_text, ''),
    p_body_preview,
    public.current_user_id(),
    public.current_user_id()
  )
  returning id into v_contribution_id;

  perform public.replace_rich_text_mentions(
    v_campaign_id,
    'entity_section_contribution',
    null,
    null,
    v_contribution_id,
    p_mentions
  );

  return query
  select esc.id, esc.section_id, esc.campaign_id, esc.visibility, esc.version_number
  from public.entity_section_contributions esc
  where esc.id = v_contribution_id;
end;
$$;

create or replace function public.update_entity_section_contribution(
  p_contribution_id uuid,
  p_visibility text,
  p_body_json jsonb,
  p_body_text text,
  p_body_preview text,
  p_mentions jsonb,
  p_expected_version integer
)
returns table (
  contribution_id uuid,
  section_id uuid,
  campaign_id uuid,
  visibility text,
  version_number integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_contribution public.entity_section_contributions%rowtype;
begin
  if not public.can_edit_entity_section_contribution(p_contribution_id) then
    raise exception 'Contribution edit not permitted';
  end if;

  perform public.assert_rich_text_payload_matches(p_body_json, p_body_text, p_body_preview, p_mentions);

  select *
  into v_contribution
  from public.entity_section_contributions esc
  where esc.id = p_contribution_id
    and esc.deleted_at is null;

  if v_contribution.id is null then
    raise exception 'Contribution not found';
  end if;

  if v_contribution.version_number <> p_expected_version then
    raise exception 'stale_conflict';
  end if;

  if not public.can_view_entity_visibility(
    v_contribution.campaign_id,
    p_visibility,
    v_contribution.author_user_id,
    (
      select es.entity_id
      from public.entity_sections es
      where es.id = v_contribution.section_id
    )
  ) then
    raise exception 'Invalid contribution visibility';
  end if;

  update public.entity_section_contributions
  set visibility = p_visibility,
      body_json = p_body_json,
      body_text = coalesce(p_body_text, ''),
      body_preview = p_body_preview,
      version_number = public.entity_section_contributions.version_number + 1,
      updated_by = public.current_user_id()
  where id = p_contribution_id;

  perform public.replace_rich_text_mentions(
    v_contribution.campaign_id,
    'entity_section_contribution',
    null,
    null,
    p_contribution_id,
    p_mentions
  );

  return query
  select esc.id, esc.section_id, esc.campaign_id, esc.visibility, esc.version_number
  from public.entity_section_contributions esc
  where esc.id = p_contribution_id;
end;
$$;

create or replace function public.soft_delete_entity_section_contribution(p_contribution_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.can_edit_entity_section_contribution(p_contribution_id) then
    raise exception 'Contribution delete not permitted';
  end if;

  update public.entity_section_contributions
  set deleted_at = now(),
      updated_by = public.current_user_id()
  where id = p_contribution_id
    and deleted_at is null;
end;
$$;

create or replace function public.rebuild_rich_text_mentions_for_source(
  p_source_type text,
  p_source_id uuid,
  p_mentions jsonb default '[]'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_campaign_id uuid;
begin
  if p_source_type = 'note' then
    select campaign_id into v_campaign_id from public.notes where id = p_source_id;
    perform public.replace_rich_text_mentions(v_campaign_id, 'note', p_source_id, null, null, p_mentions);
    return;
  end if;

  if p_source_type = 'entity_section' then
    select ce.campaign_id
    into v_campaign_id
    from public.entity_sections es
    join public.campaign_entities ce on ce.id = es.entity_id
    where es.id = p_source_id;
    perform public.replace_rich_text_mentions(v_campaign_id, 'entity_section', null, p_source_id, null, p_mentions);
    return;
  end if;

  if p_source_type = 'entity_section_contribution' then
    select campaign_id into v_campaign_id from public.entity_section_contributions where id = p_source_id;
    perform public.replace_rich_text_mentions(v_campaign_id, 'entity_section_contribution', null, null, p_source_id, p_mentions);
    return;
  end if;

  raise exception 'Unsupported source type';
end;
$$;

drop function if exists public.get_entity_sections(uuid);

create function public.get_entity_sections(
  p_entity_id uuid,
  p_role_view text default null
)
returns table (
  id uuid,
  entity_id uuid,
  section_key text,
  label text,
  visibility text,
  edit_policy text,
  content_mode text,
  body_json jsonb,
  body_text text,
  body_preview text,
  version_number integer,
  updated_at timestamptz,
  can_edit boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    es.id,
    es.entity_id,
    es.section_key,
    es.label,
    es.visibility,
    es.edit_policy,
    es.content_mode,
    es.body_json,
    es.body_text,
    es.body_preview,
    es.version_number,
    es.updated_at,
    case when public.is_player_preview_role(p_role_view) then false else public.can_edit_entity_section(es.id) end
  from public.entity_sections es
  join public.campaign_entities ce on ce.id = es.entity_id
  join public.entity_section_definitions esd on esd.id = es.section_definition_id
  where es.entity_id = p_entity_id
    and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
    and public.can_view_entity_visibility_for_role(ce.campaign_id, es.visibility, es.created_by, es.entity_id, p_role_view)
  order by esd.sort_order, es.label;
$$;

drop function if exists public.get_section_contributions(uuid);

create function public.get_section_contributions(
  p_section_id uuid,
  p_role_view text default null
)
returns table (
  id uuid,
  section_id uuid,
  visibility text,
  body_json jsonb,
  body_text text,
  body_preview text,
  version_number integer,
  author_user_id uuid,
  author_display_label text,
  created_at timestamptz,
  updated_at timestamptz,
  can_edit boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    esc.id,
    esc.section_id,
    esc.visibility,
    esc.body_json,
    esc.body_text,
    esc.body_preview,
    esc.version_number,
    esc.author_user_id,
    coalesce(cm.display_name_override, up.display_name),
    esc.created_at,
    esc.updated_at,
    case when public.is_player_preview_role(p_role_view) then false else public.can_edit_entity_section_contribution(esc.id) end
  from public.entity_section_contributions esc
  join public.entity_sections es on es.id = esc.section_id
  join public.campaign_entities ce on ce.id = es.entity_id
  left join public.user_profiles up on up.user_id = esc.author_user_id
  left join public.campaign_memberships cm
    on cm.campaign_id = esc.campaign_id
   and cm.user_id = esc.author_user_id
   and cm.status = 'active'
  where esc.section_id = p_section_id
    and esc.deleted_at is null
    and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
    and public.can_view_entity_visibility_for_role(ce.campaign_id, es.visibility, es.created_by, es.entity_id, p_role_view)
    and public.can_view_entity_visibility_for_role(esc.campaign_id, esc.visibility, esc.author_user_id, es.entity_id, p_role_view)
  order by esc.created_at;
$$;

drop function if exists public.get_entity_notes(uuid);

create function public.get_entity_notes(
  p_entity_id uuid,
  p_role_view text default null
)
returns table (
  id uuid,
  campaign_id uuid,
  visibility text,
  body_json jsonb,
  body_text text,
  body_preview text,
  version_number integer,
  author_user_id uuid,
  author_display_label text,
  created_at timestamptz,
  updated_at timestamptz,
  attachments jsonb,
  can_edit boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    n.id,
    n.campaign_id,
    n.visibility,
    n.body_json,
    n.body_text,
    n.body_preview,
    n.version_number,
    n.author_user_id,
    coalesce(cm.display_name_override, up.display_name),
    n.created_at,
    n.updated_at,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'target_type', na.target_type,
          'entity_id', case when na.target_type = 'entity' then na.entity_id else null end,
          'label', case
            when na.target_type = 'campaign' then 'Campaign'
            else coalesce(public.entity_ref_label_for_role(na.entity_id, p_role_view), 'Unavailable record')
          end
        )
        order by na.created_at
      )
      from public.note_attachments na
      where na.note_id = n.id
        and (
          na.target_type = 'campaign'
          or (na.target_type = 'entity' and public.can_view_campaign_entity_for_role(na.entity_id, p_role_view))
        )
    ), '[]'::jsonb),
    case when public.is_player_preview_role(p_role_view) then false else public.can_edit_note(n.id) end
  from public.notes n
  join public.note_attachments na_filter
    on na_filter.note_id = n.id
   and na_filter.target_type = 'entity'
   and na_filter.entity_id = p_entity_id
  left join public.user_profiles up on up.user_id = n.author_user_id
  left join public.campaign_memberships cm
    on cm.campaign_id = n.campaign_id
   and cm.user_id = n.author_user_id
   and cm.status = 'active'
  where n.deleted_at is null
    and public.can_view_entity_visibility_for_role(n.campaign_id, n.visibility, n.author_user_id, p_entity_id, p_role_view)
  order by n.updated_at desc;
$$;

create or replace function public.get_campaign_notes(p_campaign_id uuid)
returns table (
  id uuid,
  campaign_id uuid,
  visibility text,
  body_json jsonb,
  body_text text,
  body_preview text,
  version_number integer,
  author_user_id uuid,
  author_display_label text,
  created_at timestamptz,
  updated_at timestamptz,
  attachments jsonb,
  can_edit boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    n.id,
    n.campaign_id,
    n.visibility,
    n.body_json,
    n.body_text,
    n.body_preview,
    n.version_number,
    n.author_user_id,
    coalesce(cm.display_name_override, up.display_name),
    n.created_at,
    n.updated_at,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'target_type', na.target_type,
          'entity_id', case when na.target_type = 'entity' then na.entity_id else null end,
          'label', case
            when na.target_type = 'campaign' then 'Campaign'
            else public.entity_ref_label(na.entity_id)
          end
        )
        order by na.created_at
      )
      from public.note_attachments na
      where na.note_id = n.id
        and (
          na.target_type = 'campaign'
          or (na.target_type = 'entity' and public.can_view_campaign_entity(na.entity_id))
        )
    ), '[]'::jsonb),
    public.can_edit_note(n.id)
  from public.notes n
  left join public.user_profiles up on up.user_id = n.author_user_id
  left join public.campaign_memberships cm
    on cm.campaign_id = n.campaign_id
   and cm.user_id = n.author_user_id
   and cm.status = 'active'
  where n.campaign_id = p_campaign_id
    and n.deleted_at is null
    and public.can_view_note(n.id)
  order by n.updated_at desc;
$$;

drop function if exists public.get_entity_backlinks(uuid);

create function public.get_entity_backlinks(
  p_entity_id uuid,
  p_role_view text default null
)
returns table (
  source_type text,
  source_id uuid,
  source_entity_id uuid,
  source_label text,
  source_preview text,
  author_display_label text,
  visibility text,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with visible_sources as (
    select distinct
      rtem.source_type,
      rtem.source_note_id,
      rtem.source_section_id,
      rtem.source_contribution_id
    from public.rich_text_entity_mentions rtem
    where rtem.mentioned_entity_id = p_entity_id
  )
  select
    'note'::text,
    n.id,
    null::uuid,
    coalesce((
      select public.entity_ref_label_for_role(na.entity_id, p_role_view)
      from public.note_attachments na
      where na.note_id = n.id
        and na.target_type = 'entity'
        and public.can_view_campaign_entity_for_role(na.entity_id, p_role_view)
      order by na.created_at
      limit 1
    ), 'Note'),
    n.body_preview,
    coalesce(cm.display_name_override, up.display_name),
    n.visibility,
    n.updated_at
  from visible_sources vm
  join public.notes n on n.id = vm.source_note_id
  left join public.user_profiles up on up.user_id = n.author_user_id
  left join public.campaign_memberships cm
    on cm.campaign_id = n.campaign_id
   and cm.user_id = n.author_user_id
   and cm.status = 'active'
  where vm.source_type = 'note'
    and public.can_view_entity_visibility_for_role(n.campaign_id, n.visibility, n.author_user_id, p_entity_id, p_role_view)

  union all

  select
    'entity_section'::text,
    es.id,
    es.entity_id,
    ce.list_caption || ' / ' || es.label,
    es.body_preview,
    null::text,
    es.visibility,
    es.updated_at
  from visible_sources vm
  join public.entity_sections es on es.id = vm.source_section_id
  join public.campaign_entities ce on ce.id = es.entity_id
  where vm.source_type = 'entity_section'
    and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
    and public.can_view_entity_visibility_for_role(ce.campaign_id, es.visibility, es.created_by, es.entity_id, p_role_view)

  union all

  select
    'entity_section_contribution'::text,
    esc.id,
    es.entity_id,
    ce.list_caption || ' / ' || es.label,
    esc.body_preview,
    coalesce(cm.display_name_override, up.display_name),
    esc.visibility,
    esc.updated_at
  from visible_sources vm
  join public.entity_section_contributions esc on esc.id = vm.source_contribution_id
  join public.entity_sections es on es.id = esc.section_id
  join public.campaign_entities ce on ce.id = es.entity_id
  left join public.user_profiles up on up.user_id = esc.author_user_id
  left join public.campaign_memberships cm
    on cm.campaign_id = esc.campaign_id
   and cm.user_id = esc.author_user_id
   and cm.status = 'active'
  where vm.source_type = 'entity_section_contribution'
    and public.can_view_campaign_entity_for_role(ce.id, p_role_view)
    and public.can_view_entity_visibility_for_role(ce.campaign_id, es.visibility, es.created_by, es.entity_id, p_role_view)
    and public.can_view_entity_visibility_for_role(esc.campaign_id, esc.visibility, esc.author_user_id, es.entity_id, p_role_view)

  order by updated_at desc;
$$;

alter table public.notes enable row level security;
alter table public.note_attachments enable row level security;
alter table public.entity_section_contributions enable row level security;
alter table public.rich_text_entity_mentions enable row level security;

revoke all on public.notes from anon, public;
revoke all on public.note_attachments from anon, public;
revoke all on public.entity_section_contributions from anon, public;
revoke all on public.rich_text_entity_mentions from anon, public;

revoke all on function public.validate_rich_text_document(jsonb) from public, anon;
revoke all on function public.validate_rich_text_mark(jsonb) from public, anon;
revoke all on function public.validate_rich_text_node(jsonb) from public, anon;
revoke all on function public.derive_rich_text_text_from_node(jsonb) from public, anon;
revoke all on function public.extract_rich_text_mentions_from_node(jsonb) from public, anon;
revoke all on function public.derive_rich_text_payload(jsonb) from public, anon;
revoke all on function public.assert_rich_text_payload_matches(jsonb, text, text, jsonb) from public, anon;
revoke all on function public.validate_note_attachment_campaign() from public, anon;
revoke all on function public.validate_entity_section_contribution() from public, anon;
revoke all on function public.note_has_visible_attachment(uuid) from public, anon;
revoke all on function public.resolve_note_visibility_entity_from_inputs(text, boolean, uuid[]) from public, anon;
revoke all on function public.resolve_note_visibility_entity(uuid) from public, anon;
revoke all on function public.can_view_note(uuid) from public, anon;
revoke all on function public.can_edit_note(uuid) from public, anon;
revoke all on function public.can_edit_entity_section(uuid) from public, anon;
revoke all on function public.can_view_entity_section_contribution(uuid) from public, anon;
revoke all on function public.can_edit_entity_section_contribution(uuid) from public, anon;
revoke all on function public.validate_mentions_payload(uuid, jsonb) from public, anon;
revoke all on function public.replace_rich_text_mentions(uuid, text, uuid, uuid, uuid, jsonb) from public, anon;
revoke all on function public.create_note(uuid, text, jsonb, text, text, jsonb, boolean, uuid[]) from public, anon;
revoke all on function public.update_note_body(uuid, text, jsonb, text, text, jsonb, integer) from public, anon;
revoke all on function public.attach_note_target(uuid, text, uuid) from public, anon;
revoke all on function public.detach_note_target(uuid, text, uuid) from public, anon;
revoke all on function public.soft_delete_note(uuid) from public, anon;
revoke all on function public.save_entity_section_body(uuid, jsonb, text, text, jsonb, integer) from public, anon;
revoke all on function public.create_entity_section_contribution(uuid, text, jsonb, text, text, jsonb) from public, anon;
revoke all on function public.update_entity_section_contribution(uuid, text, jsonb, text, text, jsonb, integer) from public, anon;
revoke all on function public.soft_delete_entity_section_contribution(uuid) from public, anon;
revoke all on function public.rebuild_rich_text_mentions_for_source(text, uuid, jsonb) from public, anon;
revoke all on function public.get_entity_sections(uuid, text) from public, anon;
revoke all on function public.get_section_contributions(uuid, text) from public, anon;
revoke all on function public.get_entity_notes(uuid, text) from public, anon;
revoke all on function public.get_campaign_notes(uuid) from public, anon;
revoke all on function public.get_entity_backlinks(uuid, text) from public, anon;

create policy "Visible notes can be read"
  on public.notes for select to authenticated
  using (public.can_view_note(id));

create policy "Visible note attachments can be read"
  on public.note_attachments for select to authenticated
  using (public.can_view_note(note_id));

create policy "Visible contributions can be read"
  on public.entity_section_contributions for select to authenticated
  using (public.can_view_entity_section_contribution(id));

grant execute on function public.validate_rich_text_document(jsonb) to authenticated, service_role;
grant execute on function public.validate_rich_text_mark(jsonb) to authenticated, service_role;
grant execute on function public.validate_rich_text_node(jsonb) to authenticated, service_role;
grant execute on function public.derive_rich_text_text_from_node(jsonb) to authenticated, service_role;
grant execute on function public.extract_rich_text_mentions_from_node(jsonb) to authenticated, service_role;
grant execute on function public.derive_rich_text_payload(jsonb) to authenticated, service_role;
grant execute on function public.assert_rich_text_payload_matches(jsonb, text, text, jsonb) to authenticated, service_role;
grant execute on function public.note_has_visible_attachment(uuid) to authenticated, service_role;
grant execute on function public.resolve_note_visibility_entity_from_inputs(text, boolean, uuid[]) to authenticated, service_role;
grant execute on function public.resolve_note_visibility_entity(uuid) to authenticated, service_role;
grant execute on function public.can_view_note(uuid) to authenticated, service_role;
grant execute on function public.can_edit_note(uuid) to authenticated, service_role;
grant execute on function public.can_edit_entity_section(uuid) to authenticated, service_role;
grant execute on function public.can_view_entity_section_contribution(uuid) to authenticated, service_role;
grant execute on function public.can_edit_entity_section_contribution(uuid) to authenticated, service_role;
grant execute on function public.validate_mentions_payload(uuid, jsonb) to authenticated, service_role;
grant execute on function public.replace_rich_text_mentions(uuid, text, uuid, uuid, uuid, jsonb) to authenticated, service_role;
grant execute on function public.create_note(uuid, text, jsonb, text, text, jsonb, boolean, uuid[]) to authenticated, service_role;
grant execute on function public.update_note_body(uuid, text, jsonb, text, text, jsonb, integer) to authenticated, service_role;
grant execute on function public.attach_note_target(uuid, text, uuid) to authenticated, service_role;
grant execute on function public.detach_note_target(uuid, text, uuid) to authenticated, service_role;
grant execute on function public.soft_delete_note(uuid) to authenticated, service_role;
grant execute on function public.save_entity_section_body(uuid, jsonb, text, text, jsonb, integer) to authenticated, service_role;
grant execute on function public.create_entity_section_contribution(uuid, text, jsonb, text, text, jsonb) to authenticated, service_role;
grant execute on function public.update_entity_section_contribution(uuid, text, jsonb, text, text, jsonb, integer) to authenticated, service_role;
grant execute on function public.soft_delete_entity_section_contribution(uuid) to authenticated, service_role;
grant execute on function public.rebuild_rich_text_mentions_for_source(text, uuid, jsonb) to authenticated, service_role;
grant execute on function public.get_entity_sections(uuid, text) to authenticated, service_role;
grant execute on function public.get_section_contributions(uuid, text) to authenticated, service_role;
grant execute on function public.get_entity_notes(uuid, text) to authenticated, service_role;
grant execute on function public.get_campaign_notes(uuid) to authenticated, service_role;
grant execute on function public.get_entity_backlinks(uuid, text) to authenticated, service_role;
