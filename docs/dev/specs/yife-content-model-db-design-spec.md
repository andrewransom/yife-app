# Yife Content Model And Database Design Spec

## Purpose

This spec defines the initial content model and database design direction for Yife.app.

It is based on `docs/yife-requirements.md` and the follow-up data model decision work. The design assumes Supabase and PostgreSQL.

The goal is to support structured campaign knowledge management while keeping shared entity behavior reusable across the app.

## Core Decision

Use a hybrid data model:

- `campaign_entities` is the shared registry for campaign records that participate in generic app behavior.
- Type-specific tables store structured, queryable fields for each major record type.
- Shared systems reference `campaign_entities.id`.
- Long-form prose lives in reusable `entity_sections`.
- Notes are first-class records, but they are not `campaign_entities`.
- JSONB is allowed where useful, but not for core filterable or permission-critical fields.

This keeps the UI and relationship layer generic while preserving PostgreSQL constraints, indexes, RLS, and Supabase type generation.

## Shared Vocabulary

Use consistent string keys in schema comments, seed data, RPCs, and UI code.

Visibility values:

- `shared`: visible to campaign members who can view the parent/attached record.
- `gm_only`: visible to campaign owners and members with the Game Master role.
- `private`: visible only to the author/creator.

Edit policy values:

- `gm_edit`: editable by campaign owners and Game Masters.
- `owner_edit`: editable by the creating/owning user and campaign owners.
- `player_edit`: editable by campaign members with access to the parent record.
- `append_contributions`: users add attributed contribution entries rather than rewriting canonical text.

Lifecycle values such as active, completed, archived, deleted, and hidden are not substitutes for visibility. A hidden, archived, or completed GM-only record remains GM-only.

## Core Entity Registry

`campaign_entities` gives every major campaign record one stable cross-system identity.

```text
campaign_entities
- id
- campaign_id
- entity_type_id
- list_caption
- default_visibility
- created_by
- updated_by
- created_at
- updated_at
- archived_at
- deleted_at
```

Notes:

- `entity_type_id` references `entity_types`.
- `list_caption` is the primary label for lists, pickers, command palette results, tabs, pins, and inline references.
- `deleted_at` supports soft delete.
- Normal app views exclude deleted entities.
- Campaign-owner "empty trash" hard-deletes soft-deleted entities and cascades dependent data.
- `default_visibility` is the record-level default used by summaries, directories, and newly created sections unless a more specific section/note/relationship visibility applies.

## Entity Type Configuration

Entity types are database-driven, not hardcoded enums.

```text
entity_types
- id
- key
- label
- plural_label
- icon_key
- default_visibility
- sort_order
- is_system
- is_active
- created_at
- updated_at
```

Campaign-specific defaults use a separate settings table rather than mutating system entity type rows.

```text
campaign_entity_type_settings
- campaign_id
- entity_type_id fk -> entity_types.id
- default_visibility
- is_enabled
- created_by
- updated_by
- created_at
- updated_at
```

Rules:

- New campaigns seed settings from `entity_types.default_visibility`.
- Campaign owners and Game Masters can change default visibility per entity type in MVP.
- Section-level visibility remains controlled on each section; MVP does not require campaign-wide section default matrices.

Initial system entity types:

- character
- npc
- party
- faction
- location
- quest
- session
- plot_arc
- encounter
- timeline_event

## Typed Detail Tables

Typed tables store structured fields used for filtering, ordering, validation, relationships, or forms.

Substantial prose does not live in these tables. It belongs in `entity_sections`.

All typed `entity_id` values must point to a `campaign_entities` row with the matching entity type. Structural entity foreign keys must point to the same campaign and to the expected entity type. Enforce this first in create/update RPCs, then with database constraints or triggers where practical.

### Characters

```text
characters
- entity_id pk/fk -> campaign_entities.id
- name
- status_id
- controlling_user_id
- image_asset_id
```

Character backstory, public description, and private notes use `entity_sections`.

### NPCs

```text
npcs
- entity_id pk/fk -> campaign_entities.id
- name
- apparent_status_id
- real_status_id
- faction_entity_id nullable
- image_asset_id
- stat_block_jsonb nullable
```

Notes:

- `real_status_id` stays structured for GM workflow.
- Player-facing NPC reads must use safe views/RPCs that omit `real_status_id` when needed.
- `apparent_status_id` should default to `real_status_id` when the GM changes real status unless the GM explicitly overrides apparent status.
- NPC motivations, secrets, plans, player summaries, and player observations use `entity_sections`.

### Parties

```text
parties
- entity_id pk/fk -> campaign_entities.id
- name
```

Party description and notes use `entity_sections`.

Party membership is separate from campaign membership.

```text
party_members
- party_entity_id fk -> campaign_entities.id
- character_entity_id fk -> campaign_entities.id
- role_label nullable
- sort_order
- created_by
- updated_by
- created_at
- updated_at
```

Rules:

- A campaign may have multiple parties.
- A character may be in zero, one, or multiple parties unless a later campaign setting restricts it.
- Party resources and funds are owned by party or character entities, not by `party_members`.

### Factions

```text
factions
- entity_id pk/fk -> campaign_entities.id
- name
- status_id nullable
- parent_faction_entity_id nullable fk -> campaign_entities.id
```

Faction description, relationship summary, GM notes, and player-facing details use `entity_sections`.

### Locations

```text
locations
- entity_id pk/fk -> campaign_entities.id
- name
- location_type_option_id
- status_id nullable
- parent_location_entity_id nullable fk -> campaign_entities.id
- image_asset_id nullable
```

Location descriptions, maps notes, GM-only details, and player-facing summaries use `entity_sections`.

### Quests

```text
quests
- entity_id pk/fk -> campaign_entities.id
- title
- status_id
- priority_option_id nullable
- is_major
- parent_quest_entity_id nullable fk -> campaign_entities.id
```

Quest public summary, GM details, clues, private notes, and player-facing log content use `entity_sections`.

### Sessions

```text
sessions
- entity_id pk/fk -> campaign_entities.id
- title
- session_date
- status_id
```

Session summaries, prep notes, recap notes, and GM-private notes use `entity_sections` and `notes`.

Attendance is tracked separately.

### Plot Arcs

```text
plot_arcs
- entity_id pk/fk -> campaign_entities.id
- title
- status_id
```

Plot arcs are GM-facing by default. Arc descriptions, planning notes, and outcomes use `entity_sections`.

### Encounters

```text
encounters
- entity_id pk/fk -> campaign_entities.id
- title
- encounter_type_option_id
- status_id
- related_session_entity_id nullable fk -> campaign_entities.id
- related_plot_arc_entity_id nullable fk -> campaign_entities.id
```

Encounter descriptions, tactical notes, outcomes, and GM-only prep use `entity_sections`.

### Timeline Events

```text
timeline_events
- entity_id pk/fk -> campaign_entities.id
- title
- date_expression
- sort_key nullable
- event_type_option_id
- related_session_entity_id nullable fk -> campaign_entities.id
```

Timeline event descriptions and GM-private detail use `entity_sections`.

Timeline events may use `shared`, `gm_only`, or `private` record visibility. Private timeline events are visible only to their creator/author and should not leak through summaries, relationships, or timeline widgets.

## Entity Sections

All substantial prose goes in `entity_sections`.

This includes:

- player-facing summaries
- canonical descriptions
- GM-private details
- player contribution sections
- backstories
- session summaries
- quest details
- location descriptions
- encounter notes

```text
entity_sections
- id
- entity_id fk -> campaign_entities.id
- section_definition_id fk -> entity_section_definitions.id
- section_key
- label
- visibility
- edit_policy
- content_mode -- document | contribution_feed
- body_json jsonb
- body_text text
- body_preview text nullable
- version_number
- created_by
- updated_by
- created_at
- updated_at
```

Notes:

- `body_json` is the source of truth.
- `body_text` and `body_preview` are derived for search, summaries, and previews.
- Save operations for sections go through RPCs so version checks, derived text, and mention extraction happen transactionally.
- The caller sends the expected `version_number`; stale saves are rejected.
- `content_mode = document` stores canonical long-form content in `body_json`.
- `content_mode = contribution_feed` uses the section row as the container for attributed contribution entries.

## Player Contributions

Player-authored observations, theories, nicknames, reminders, and subjective details must remain attributed and visually distinct from GM-confirmed canon.

Use section contribution rows for attributed player-authored knowledge.

```text
entity_section_contributions
- id
- section_id fk -> entity_sections.id
- author_user_id
- visibility
- body_json jsonb
- body_text text
- body_preview text nullable
- version_number
- created_by
- updated_by
- created_at
- updated_at
- deleted_at nullable
```

Rules:

- Contribution rows attach to `entity_sections` whose `content_mode = contribution_feed` or `edit_policy = append_contributions`.
- Players can create contribution rows only where the section permits player contribution.
- Game Masters can edit, remove, moderate, or promote/copy useful contribution content into canonical player-visible sections.
- Contribution saves use the same rich text/concurrency/mention extraction pattern as notes and sections.
- Simple shared player-editable values can stay in structured fields only when they are not sensitive and do not need per-author attribution. Subjective or conflicting knowledge should use contribution rows.

## Entity Aliases

Nicknames and alternate labels are common across NPCs, factions, locations, parties, and other records.

```text
entity_aliases
- id
- entity_id fk -> campaign_entities.id
- alias_text
- alias_type -- nickname | alternate_name | title | other
- visibility
- is_preferred
- created_by
- updated_by
- created_at
- updated_at
- deleted_at nullable
```

Rules:

- Use aliases for simple shared/player-editable names such as NPC nicknames.
- `list_caption` remains the primary app label unless the UI intentionally shows a preferred player-visible alias as secondary context.
- Aliases must respect the same visibility rules as other entity-adjacent data.
- Subjective explanations for why players use an alias belong in contribution rows or notes.

## Section Definitions

Section definitions are database-driven.

```text
entity_section_definitions
- id
- entity_type_id fk -> entity_types.id
- section_key
- label
- default_visibility
- default_edit_policy
- default_content_mode
- sort_order
- is_system
- is_active
- created_at
- updated_at
```

Initial section sets should be seeded by migration.

Example NPC sections:

```text
player_summary
gm_details
player_observations
```

Example quest sections:

```text
player_summary
gm_details
player_observations
```

Example session sections:

```text
summary
gm_prep
gm_private_notes
```

Custom sections are post-MVP.

## Notes

Notes are not `campaign_entities`.

```text
notes
- id
- campaign_id
- author_user_id
- visibility
- body_json jsonb
- body_text text
- body_preview text nullable
- version_number
- created_by
- updated_by
- created_at
- updated_at
- deleted_at nullable
```

```text
note_attachments
- id
- note_id fk -> notes.id
- target_type -- campaign | entity
- entity_id nullable fk -> campaign_entities.id
- created_by
- created_at
```

Notes:

- Notes can attach to the campaign itself or to one or more entities.
- `target_type = campaign` uses `entity_id = null`.
- `target_type = entity` requires `entity_id` in the same campaign as the note.
- Notes are discoverable through attached entities and backlinks.
- Rich text `@` mentions do not target notes in MVP.
- Save operations for notes go through RPCs with optimistic concurrency.

## Rich Text And Mentions

Rich text is stored as editor JSON plus derived plain text.

The model should support a Tiptap/ProseMirror-style document format, though the editor choice can be finalized later.

Inline mentions target campaign entities only.

Mention source of truth:

- `notes.body_json`
- `entity_sections.body_json`
- `entity_section_contributions.body_json`

Derived mention index:

```text
rich_text_entity_mentions
- id
- campaign_id
- source_type -- note | entity_section | entity_section_contribution
- source_note_id nullable fk -> notes.id
- source_section_id nullable fk -> entity_sections.id
- source_contribution_id nullable fk -> entity_section_contributions.id
- mentioned_entity_id fk -> campaign_entities.id
- mention_text
- created_at
```

Notes:

- Mention rows are rebuildable derived data.
- On rich text save, old rows for that source are deleted and current rows are inserted.
- A repair/backfill script or RPC can rebuild mentions from JSON.

## Relationships

Explicit user-managed relationships use one generic table.

```text
entity_relationships
- id
- campaign_id
- source_entity_id fk -> campaign_entities.id
- target_entity_id fk -> campaign_entities.id
- relationship_type_id fk -> relationship_types.id
- visibility
- created_by
- updated_by
- created_at
- updated_at
- deleted_at nullable
```

Structural relationships stay in typed columns and are not mirrored into `entity_relationships`.

Examples:

- `locations.parent_location_entity_id`
- `quests.parent_quest_entity_id`
- `factions.parent_faction_entity_id`
- `encounters.related_session_entity_id`
- `timeline_events.related_session_entity_id`

A read-only related-records view should union explicit relationships with typed structural links.

```text
entity_related_records
- campaign_id
- source_entity_id
- target_entity_id
- relation_source -- explicit | structural | mention
- relationship_type_key nullable
- label
- visibility
```

## Relationship Types

Relationship types are database-driven.

```text
relationship_types
- id
- campaign_id nullable
- key
- label
- inverse_label nullable
- default_directionality
- sort_order
- is_system
- is_active
- created_by nullable
- updated_by nullable
- created_at
- updated_at
```

Rules:

- `campaign_id null` means global system default.
- Non-null `campaign_id` means campaign-scoped custom type.
- MVP seeds system defaults.
- Custom relationship type UI can wait.

Initial system defaults:

- related_to
- ally_of
- enemy_of
- member_of
- leader_of
- located_in
- owns
- works_for
- seeks
- protects
- threatens
- created_by
- parent_of
- child_of

## Status And Option Definitions

Statuses are database-driven.

```text
status_definitions
- id
- subject_key -- campaign | entity_resource | entity
- entity_type_id nullable fk -> entity_types.id
- campaign_id nullable
- key
- label
- sort_order
- color_token nullable
- is_terminal
- is_system
- is_active
- created_by nullable
- updated_by nullable
- created_at
- updated_at
```

Rules:

- MVP uses seeded system statuses.
- Future campaign-scoped custom statuses are allowed by the schema.
- Entity typed records store `status_id` values whose definitions have `subject_key = entity` and the matching `entity_type_id`.
- Campaign status uses definitions with `subject_key = campaign`.
- Resource status uses definitions with `subject_key = entity_resource`.

Initial system status keys:

- campaign: `planned`, `active`, `paused`, `completed`, `archived`
- character: `active`, `inactive`, `dead`, `retired`, `missing`
- npc apparent/real status: `alive`, `dead`, `missing`, `unknown`, `inactive`
- quest: `open`, `in_progress`, `completed`, `failed`, `abandoned`, `hidden`
- session: `planned`, `completed`, `cancelled`
- plot arc: `planned`, `active`, `resolved`, `abandoned`, `hidden`
- encounter: `planned`, `ready`, `completed`, `skipped`, `archived`
- resource: `active`, `inactive`, `lost`, `consumed`, `archived`

Open/configurable lists use a generalized option table.

```text
entity_option_definitions
- id
- entity_type_id nullable fk -> entity_types.id
- campaign_id nullable
- group_key
- key
- label
- sort_order
- is_system
- is_active
- created_by nullable
- updated_by nullable
- created_at
- updated_at
```

Use this for:

- location types
- timeline event types
- encounter types
- quest priority/importance
- other small open lists

Rules:

- `campaign_id null` means system default.
- Non-null `campaign_id` means campaign custom.
- MVP customization UI is only required for currencies.

Initial system option keys:

- location type: `world`, `continent`, `country`, `region`, `town`, `city`, `wilderness_area`, `district`, `landmark`, `building`, `room`, `dungeon`, `plane`, `other`
- timeline event type: `world_history`, `campaign_event`, `session_event`, `character_event`, `faction_event`, `location_event`, `quest_event`, `omen_prophecy`, `other`
- encounter type: `roleplay`, `exploration`, `combat`, `puzzle`, `travel`, `mixed`, `other`
- quest priority: `low`, `normal`, `high`, `urgent`

## Users And Settings

Application users are Supabase auth users. Store app display/profile data separately from auth account state.

```text
user_profiles
- user_id pk/fk -> auth.users.id
- display_name
- avatar_asset_id nullable
- created_at
- updated_at
```

```text
user_settings
- user_id pk/fk -> auth.users.id
- theme_preference
- default_landing_behavior
- default_campaign_id nullable
- accessibility_preferences_jsonb nullable
- created_at
- updated_at
```

Rules:

- User settings are global to the user and must not contain campaign layout state.
- Campaign image/media metadata remains campaign-scoped even if the underlying file is public by URL in MVP.
- Notification preferences are deferred until notifications exist.

## Campaign Membership And Roles

Roles are normalized and database-driven.

```text
role_definitions
- id
- key
- label
- sort_order
- is_system
- is_active
```

Initial system roles:

- `owner`
- `game_master`
- `player`

```text
campaign_memberships
- id
- campaign_id
- user_id
- status
- display_name_override nullable
- created_at
- updated_at
```

```text
campaign_membership_roles
- membership_id fk -> campaign_memberships.id
- role_id fk -> role_definitions.id
- created_at
```

Campaign ownership is represented both ways:

```text
campaigns
- id
- owner_user_id
- name
- description nullable
- status_id
- start_date
- end_date nullable
- image_asset_id nullable
- created_by
- updated_by
- created_at
- updated_at
```

Rules:

- `campaigns.owner_user_id` is canonical ownership.
- Owner role membership is also assigned for permission/UI consistency.
- Owner membership should be maintained by create/invite/member-management workflows.
- `campaign_memberships.status` supports active/removed membership lifecycle without relying only on hard deletes.
- RLS should treat only active memberships as campaign members.
- Character assignment is represented by `characters.controlling_user_id`; membership/member settings screens can derive assigned characters from that field.

## Campaign Invitations

```text
campaign_invitations
- id
- campaign_id
- email_normalized
- invited_by_user_id
- status
- accepted_by_user_id nullable
- accepted_at nullable
- declined_at nullable
- revoked_at nullable
- expires_at nullable
- created_at
- updated_at
```

```text
campaign_invitation_roles
- invitation_id fk -> campaign_invitations.id
- role_id fk -> role_definitions.id
- created_at
```

Rules:

- Prevent duplicate active invitations for the same campaign/email.
- Invitation acceptance must create campaign membership and roles in one transaction/RPC.
- Invitation roles define the roles assigned on acceptance.
- The acceptance RPC must validate the invite status, expiry, normalized email claim, campaign id, and assigned roles before creating membership.

## Media

Use Supabase Storage files plus Postgres metadata. Detailed image storage, variant, upload, and serving rules live in `docs/dev/specs/yife-media-image-storage-spec.md`.

Store bucket/path metadata, not public URLs. App code derives public URLs from bucket/path when rendering public MVP images.

```text
media_assets
- id
- campaign_id nullable
- owner_user_id nullable
- asset_scope -- campaign | user_profile
- storage_bucket
- status
- current_version_key
- title nullable
- alt_text nullable
- is_decorative
- crop_anchor
- dominant_color nullable
- blurhash nullable
- original_filename nullable
- original_mime_type nullable
- original_byte_size nullable
- original_width nullable
- original_height nullable
- retain_original
- created_by
- updated_by
- created_at
- updated_at
- deleted_at nullable
```

Generated files are represented as variants.

```text
media_asset_variants
- id
- media_asset_id fk -> media_assets.id
- variant -- thumb_160 | grid_480 | original_1600
- storage_bucket
- storage_path
- width
- height
- format
- mime_type
- byte_size
- version_key
- created_at
```

Primary image columns are allowed on records that need fast list display:

- campaigns
- characters
- npcs
- locations
- user_profiles, if avatar uploads are implemented

Optional/future attachments use generic links:

```text
media_asset_links
- id
- media_asset_id fk -> media_assets.id
- entity_id nullable fk -> campaign_entities.id
- note_id nullable fk -> notes.id
- section_id nullable fk -> entity_sections.id
- link_role
- sort_order
- created_by
- created_at
```

Rules:

- `thumb_160` and `grid_480` are required MVP variants for ready primary-image assets.
- Campaign, character, NPC, and location primary images must reference same-campaign media assets.
- User profile avatar assets, if implemented, use `asset_scope = user_profile`, `campaign_id = null`, and `owner_user_id` matching the profile user.
- MVP primary images are player-visible when the parent campaign/entity is visible.
- GM-private or spoiler images for otherwise player-visible records are deferred until media links support visibility or private media is promoted.
- Public URLs must not be stored in media tables or summary views.

## Funds And Resources

Funds and resources are generic across owner entities.

Initial allowed owner types:

- party
- character

Allowed owner types can be enforced by app/RPC validation first, then DB triggers if needed.

### Currency Definitions

```text
campaign_currency_definitions
- id
- campaign_id
- key
- label
- value_in_standard numeric
- is_standard
- sort_order
- is_active
- created_by
- updated_by
- created_at
- updated_at
```

Rules:

- New campaigns auto-seed D&D-friendly defaults in MVP.
- Gold is the standard currency in that default set.
- Default currency keys should include `cp`, `sp`, `ep`, `gp`, and `pp` unless a later preset changes them.
- Later campaign creation may support preset/no-currency choices.
- Currency customization UI is included in MVP.
- Calculated total value is done client-side.

### Fund Balances

```text
entity_fund_balances
- id
- campaign_id
- owner_entity_id fk -> campaign_entities.id
- currency_definition_id fk -> campaign_currency_definitions.id
- quantity numeric
- created_by
- updated_by
- created_at
- updated_at
```

Constraints:

```text
unique(owner_entity_id, currency_definition_id)
```

Rules:

- Funds are owner-only balances.
- Funds do not have holder/custodian tracking in MVP.
- Special carried valuables can be modeled as resources.
- `owner_entity_id` and `currency_definition_id` must belong to the same campaign.

### Resources

```text
entity_resources
- id
- campaign_id
- owner_entity_id fk -> campaign_entities.id
- holder_entity_id nullable fk -> campaign_entities.id
- name
- description_text nullable
- status_id
- quantity numeric nullable
- value_amount numeric nullable
- sort_order
- created_by
- updated_by
- created_at
- updated_at
```

Rules:

- `owner_entity_id` is who owns/controls the resource.
- `holder_entity_id` is who physically has it now.
- A party-owned item held by a character uses owner = party and holder = character.
- `value_amount` is always the campaign standard-currency equivalent.
- `description_text` is intentionally simple for MVP. If resource notes become substantial, add a resource notes/attachments model later rather than forcing resources into `campaign_entities`.
- Owner and holder entities must belong to the same campaign as the resource.

## Session Attendance

Track attending users and attending characters separately.

```text
session_attending_users
- session_entity_id fk -> campaign_entities.id
- user_id
- created_by
- created_at
```

```text
session_attending_characters
- session_entity_id fk -> campaign_entities.id
- character_entity_id fk -> campaign_entities.id
- created_by
- created_at
```

Users and characters are different facts. Do not collapse users into campaign entities.

Rules:

- `session_entity_id` must reference a session entity.
- `character_entity_id` must reference a character entity in the same campaign.
- Use unique constraints on `(session_entity_id, user_id)` and `(session_entity_id, character_entity_id)`.

## Summaries And Client State

The command palette and quick open can search client-side over loaded campaign summaries.

Create a lightweight role-safe summary view first. If view-only RLS becomes too awkward, wrap the summary read in an RPC, but the first implementation must already enforce membership, role, visibility, soft-delete, and media-safe filtering.

```text
campaign_entity_summaries
- campaign_id
- entity_id
- entity_type_key
- list_caption
- default_visibility
- status_key nullable
- status_label nullable
- primary_image_asset_id nullable
- primary_image_alt_text nullable
- primary_image_thumb_bucket nullable
- primary_image_thumb_path nullable
- primary_image_thumb_width nullable
- primary_image_thumb_height nullable
- primary_image_grid_bucket nullable
- primary_image_grid_path nullable
- primary_image_grid_width nullable
- primary_image_grid_height nullable
- primary_image_is_decorative nullable
- relevant_date nullable
- sort_key nullable
- parent_entity_id nullable
- related_session_entity_id nullable
- updated_at
- deleted_at
- type-specific nullable summary fields as needed
```

Use this for:

- app-state hydration
- command palette quick entity search
- open tabs
- pinned entities
- recent records
- dense list widgets

Deep search, full-text search, and semantic search are deferred to a later milestone.

Current requirements for future search:

- Preserve structured fields.
- Maintain `body_text` for notes and sections.
- Keep mention rows rebuildable/queryable.

## Workspace, Layout, And Recent State

Saved layouts are personal workspace state scoped to one user and one campaign. They are not campaign data shared with other members.

Use JSONB for layout structure because it is UI configuration, not the source of truth for campaign permissions or relationships. Entity references inside layout state must still be validated and rendered through safe summary/placeholder reads.

```text
user_campaign_workspaces
- id
- user_id
- campaign_id
- active_layout_id nullable fk -> saved_layouts.id
- current_session_entity_id nullable fk -> campaign_entities.id
- last_route nullable
- created_at
- updated_at
```

```text
saved_layouts
- id
- user_id
- campaign_id
- name
- role_context -- gm | player | mixed
- is_system_default
- source_default_key nullable
- layout_state_jsonb
- draft_layout_state_jsonb nullable
- has_unsaved_structural_changes
- created_at
- updated_at
```

```text
saved_layout_pinned_entities
- layout_id fk -> saved_layouts.id
- entity_id fk -> campaign_entities.id
- pin_context nullable
- sort_order
- created_at
```

```text
saved_layout_open_tabs
- layout_id fk -> saved_layouts.id
- entity_id fk -> campaign_entities.id
- sort_order
- is_selected
- created_at
- updated_at
```

```text
user_campaign_recent_entities
- user_id
- campaign_id
- entity_id fk -> campaign_entities.id
- last_opened_at
```

Rules:

- MVP provides three GM default layout records and two player default layout records per user/campaign, derived from system defaults.
- Structural layout edits update draft state until the user saves, discards, or resets.
- Low-risk state such as selected tab, recent entities, current route, and current-session override may auto-save.
- Open tabs, pins, recent entities, and current session references must degrade through placeholders when entities are deleted, hidden, or inaccessible.
- Mobile does not need to use desktop saved layout state in MVP.

## Recent Activity

Recent campaign activity is required in MVP, but it does not need immutable audit-log guarantees or field-by-field diffs.

Start with a role-aware view or RPC that derives activity from normal metadata:

```text
campaign_activity_feed
- campaign_id
- activity_type
- subject_type -- entity | note | section | contribution | relationship | media | membership
- subject_id
- subject_entity_id nullable
- actor_user_id nullable
- occurred_at
- label
- visibility
```

Activity sources:

- created or updated campaign entities
- new or updated notes
- updated sections
- new or updated contribution rows
- changed statuses
- new or updated relationships
- uploaded media
- membership or invitation changes where visible to the viewer

Rules:

- Activity reads must respect campaign membership, role, entity visibility, note visibility, section visibility, and relationship visibility.
- Player activity must not reveal GM-only record names, private notes, or hidden relationship existence.
- The feed may use generic private/unavailable placeholders for inaccessible subjects.
- A dedicated append-only activity event table is deferred unless derived activity proves too limited.

## Data Access And APIs

Use a hybrid data access approach.

Direct table/view calls are fine for:

- simple reads
- summary views
- simple single-row edits where RLS is enough

Use RPCs for:

- typed entity creation
- multi-row transactions
- save note
- save entity section
- rich text mention extraction
- optimistic concurrency checks
- invitation acceptance
- role and membership changes
- layout structural save/discard/reset
- soft delete / restore / empty trash
- operations with side effects
- privileged or mixed-visibility workflows

Avoid Edge Functions unless there is a clear reason. Postgres RPC calls are not Edge Function invocations.

### Entity Creation

Typed entity creation should use RPCs/transactions.

Each create RPC should:

1. Create `campaign_entities`.
2. Create the typed detail row.
3. Create default `entity_sections`.
4. Return the created entity id and summary data.

Create RPCs must apply the campaign's `campaign_entity_type_settings.default_visibility` for the entity type unless the caller supplies an allowed override.

### Rich Text Saves

Note, section, and contribution saves should use RPCs.

Each save RPC should:

1. Check expected `version_number`.
2. Update `body_json`.
3. Derive and update `body_text` / `body_preview`.
4. Increment `version_number`.
5. Set `updated_by` / `updated_at`.
6. Rebuild mention rows for that source.
7. Reject stale writes.

MVP conflict UI can be simple: tell the user content changed elsewhere and require reload before saving.

## Visibility And RLS

Campaign membership is the first security boundary.

General rules:

- Campaign data is restricted to campaign members.
- Owner has full campaign-management access, except author-private content remains author-only.
- GM-only sections are visible to members with GM role.
- Private notes are visible only to their author.
- Shared notes are visible to members who can view attached entities.
- Private timeline events, notes, and contribution rows are visible only to their author/creator.
- Relationship visibility is limited to `shared` and `gm_only` in MVP.
- Section-level visibility and editability are the main MVP mechanism for mixed-visibility records.
- Player-facing or mixed-visibility reads should use safe views/RPCs.

Sensitive creative content should live in protected section rows, not in player-readable typed columns.

Pragmatic exception:

- Some structured GM fields, such as NPC real status, may stay on typed rows.
- Player-facing reads must use safe views/RPCs that omit those fields.

Safe read surfaces should exist for:

- campaign entity summaries
- entity detail reads for player-facing/mixed records
- NPC reads that omit `real_status_id`
- timeline views with private/GM-only filtering
- related-record views
- rich text mention/backlink reads
- saved layout/open tab/pinned entity hydration
- recent activity

## Inaccessible Placeholders

Deleted, private, GM-only, or otherwise inaccessible references must degrade clearly rather than breaking UI.

Placeholder rules:

- Unauthorized players should receive generic labels such as unavailable, private, or deleted without leaking the hidden record's name, type-specific details, or relationship reason.
- Game Masters and users with restore permission may receive more specific context such as deleted, archived, or inaccessible due to role.
- Placeholders apply consistently to rich text mentions, backlinks, relationships, open tabs, pinned entities, recent activity, command palette results, and saved layouts.
- Soft-deleted records should offer restore actions only to users with permission.
- Hard-deleted records remain unavailable and should not break surrounding content.

Placeholder-safe read shapes should include only:

```text
entity_reference_resolution
- requested_entity_id
- resolution_state -- visible | deleted | private | gm_only | inaccessible | hard_deleted
- display_label nullable
- entity_type_key nullable
- can_restore
- can_request_access
```

## Delete And Restore

Use soft delete by default.

Soft delete behavior:

- Mark `campaign_entities.deleted_at`.
- Keep typed rows, sections, notes, relationships, resources, and mentions intact.
- Normal views hide deleted entities.
- Related-record UI can show deleted/inaccessible placeholders where useful.

Hard delete behavior:

- Campaign-owner "empty trash" action hard-deletes soft-deleted entities.
- Hard delete cascades dependent data.
- Empty trash should be RPC-only.

## Audit Fields

All user-editable tables should include audit fields where practical:

```text
created_by
updated_by
created_at
updated_at
```

Join tables that only record an attachment/assignment may use:

```text
created_by
created_at
```

Notes, sections, and contribution rows also include:

```text
version_number
```

## JSONB Guidance

Use `jsonb` for data that is flexible, optional, low-query, or system-specific:

- rich text source documents
- NPC stat blocks
- future game-system-specific fields
- display/config metadata where relational modeling is premature

Avoid `jsonb` for fields that are core to:

- permissions
- relationships
- filtering
- ordering
- ownership
- status
- campaign isolation
- parent/child hierarchy

## Deferred Decisions

The following are intentionally deferred:

- Deep search design.
- Semantic/vector search.
- Full revision history and historical content snapshots.
- Custom section UI.
- Custom status/relationship/option UI, except currencies.
- Import/export.
- Advanced inventory/accounting ledger.
- Real-time collaborative rich text.
- Full audit history.
