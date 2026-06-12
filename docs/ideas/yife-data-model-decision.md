# Yife Data Model Decision

## Context

Yife will use Supabase and PostgreSQL as hard platform constraints.

The requirements describe many campaign-scoped record types with similar product behavior:

- Shared list/display behavior through `ListCaption`.
- Shared notes.
- Shared relationships.
- Rich text `@` references and backlinks.
- Shared visibility concepts.
- Command palette search and quick open.
- Saved layout tabs and pinned entities.
- Reusable list/detail/widget UI.

At the same time, several record types have meaningful type-specific behavior:

- NPCs have apparent status, real Game Master-only status, faction association, player observations, and optional stat blocks.
- Quests have status, priority, major/minor classification, parent quests, and player-facing/private details.
- Sessions have dates, attendance, summaries, and current-session layout behavior.
- Timeline events have date expressions, sort keys, event types, visibility, and optional related sessions.
- Locations have type, parent location hierarchy, status, and optional maps/images.
- Plot arcs and encounters are Game Master-facing by default.
- Parties have members, funds, and resources.

The core question is whether campaign child records should use:

1. Separate typed tables for each entity type.
2. One generic table with `entity_type` and flexible `jsonb`.
3. A hybrid model.

## Decision

Use a hybrid data model:

- A shared `campaign_entities` registry table provides one stable identity for records that participate in generic app behavior.
- Type-specific tables store structured fields for each major entity type.
- Generic systems such as notes, relationships, rich text mentions, backlinks, command palette results, widgets, saved tabs, and pinned entities reference `campaign_entities.id`.
- Use `jsonb` selectively for flexible or low-query details, not for core filterable record shape.

This keeps the UI and relationship layer generic while preserving PostgreSQL's strengths for validation, constraints, indexing, row-level security, and Supabase-generated types.

## Recommended Shape

Initial shared entity registry:

```text
campaign_entities
- id
- campaign_id
- entity_type
- list_caption
- default_visibility
- created_by
- created_at
- updated_at
- archived_at
- deleted_at
```

Initial typed detail tables:

```text
characters
- entity_id pk/fk -> campaign_entities.id
- name
- status
- controlling_user_id
- backstory
- image_asset_id

npcs
- entity_id pk/fk -> campaign_entities.id
- name
- description
- apparent_status
- real_status
- relationship_summary
- faction_entity_id
- image_asset_id
- stat_block_jsonb

parties
- entity_id pk/fk -> campaign_entities.id
- name
- notes/description fields as needed

factions
- entity_id pk/fk -> campaign_entities.id
- name
- description
- relationship_to_party
- parent_faction_entity_id
- status

locations
- entity_id pk/fk -> campaign_entities.id
- name
- location_type
- description
- parent_location_entity_id
- status
- image_asset_id

quests
- entity_id pk/fk -> campaign_entities.id
- title
- description
- status
- priority
- is_major
- parent_quest_entity_id

sessions
- entity_id pk/fk -> campaign_entities.id
- title
- session_date
- status
- summary

plot_arcs
- entity_id pk/fk -> campaign_entities.id
- title
- description
- status

encounters
- entity_id pk/fk -> campaign_entities.id
- title
- encounter_type
- description
- status
- related_session_entity_id
- related_plot_arc_entity_id

timeline_events
- entity_id pk/fk -> campaign_entities.id
- title
- date_expression
- sort_key
- event_type
- description
- related_session_entity_id
```

Shared systems should point at the registry:

```text
notes
note_attachments
entity_relationships
rich_text_entity_mentions
media_assets
media_asset_links
layout_open_tabs
layout_pinned_entities
search/index views
```

## Pros And Cons

| Approach | Pros | Cons |
|---|---|---|
| Distinct typed tables only | Clear schema. Strong constraints. Easy indexes. Straightforward type-specific queries. Good Supabase types. | Shared systems need polymorphic references. More repeated columns/patterns. Generic UI features need union views or duplicated logic. |
| Single generic entity table | Very flexible. Easy to add new entity types. Shared notes/relationships/tabs/search can target one table. | Weak constraints. Harder RLS. Messier filtering. JSON conventions drift. Supabase types become less useful. Type-specific behavior moves into app code. |
| Hybrid registry plus typed tables | Stable shared entity identity. Strong typed data where it matters. Good fit for notes, relationships, references, tabs, pins, widgets, and command palette. Preserves Postgres/Supabase strengths. | More tables. Requires joins. Needs disciplined conventions around `campaign_entities.id` and entity type handling. |

## JSONB Guidance

Use `jsonb` for data that is flexible, optional, low-query, or likely to vary by game system:

- NPC stat blocks.
- Party resource details if they remain lightweight.
- Future rules-system-specific fields.
- Flexible rich text document metadata.
- Miscellaneous per-type display/configuration metadata.

Avoid `jsonb` for fields that are core to filtering, ordering, permissions, or relationships:

- Campaign id.
- Entity type.
- List caption.
- Status.
- Visibility.
- Dates and timeline sort keys.
- Parent entity ids.
- Ownership/control fields.
- Faction/location/session/quest relationships.

## Rationale

The requirements say Yife should provide reusable entity patterns, but also that it should keep records structured. The hybrid model follows that split.

The app needs one common way to attach notes, create backlinks, open tabs, pin entities, show command palette results, and resolve rich text references. A shared entity registry solves that cleanly.

The app also needs durable and queryable type-specific behavior. NPCs, quests, sessions, timeline events, locations, parties, plot arcs, and encounters are not just differently labeled versions of the same object. Typed tables keep those differences explicit and enforceable.

This approach is also friendlier to AI-assisted development. Clear tables and constraints reduce ambiguity for future code generation, migrations, RLS policies, and feature work.

## Open Implementation Notes

- Decide whether notes are themselves entries in `campaign_entities` or remain a separate table with attachments. The current recommendation is to keep notes as their own first-class table, while still allowing notes to be relationship targets if needed through an attachment/reference bridge.
- Decide whether section-level visibility is stored as common structured columns, a related `entity_sections` table, or typed columns per table. MVP should avoid arbitrary field-level permissions.
- Consider database views for common entity search/list needs, such as `campaign_entity_search`.
- Prefer real foreign keys where possible. For cross-type relationships, reference `campaign_entities.id`.
- Ensure RLS policies are designed around campaign membership first, then role/visibility.
