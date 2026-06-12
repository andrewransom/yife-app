# 04. Entity Creation And Directory Baseline

## Purpose

Implement the first real campaign entity workflows on top of the Supabase security foundation.

This milestone should prove the hybrid model end to end: typed creation RPCs create `campaign_entities`, typed detail rows, default section rows, safe summaries, and dense directory/detail UI shells without pulling rich text editing, relationship management, media upload, or workbench customization forward.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/01-project-foundation.md`
- `docs/dev/milestones/02-supabase-core-schema-and-security-foundation.md`
- `docs/dev/milestones/03-auth-campaign-home-and-campaign-creation.md`

## Goals

- Add typed detail tables for MVP campaign entity types.
- Add `entity_sections` if milestone 02 only seeded section definitions.
- Add typed creation RPCs for core entity types.
- Create default `entity_sections` rows during entity creation, using seeded section definitions.
- Add `entity_aliases` if needed for player-facing nicknames and alternate names, but keep it simple.
- Expand safe campaign entity summaries so directories can render useful dense rows.
- Add feature query/mutation composables for entity summaries, entity creation, and initial detail reads.
- Build reusable dense directory/list components and basic filters.
- Build first detail shells for core entity types.
- Keep component data access behind Yife query/mutation composables.
- Add schema, RLS/RPC, component, and browser smoke tests for creation, directory visibility, and detail shells.

## Non-Goals

- No Tiptap editor integration.
- No note creation or note attachment UI.
- No rich text save RPCs beyond creating empty section rows.
- No mention extraction or backlinks.
- No explicit relationship management UI.
- No media upload or primary image assignment.
- No saved workbench layouts.
- No full edit forms for every field after creation unless needed to prove the detail shell.
- No custom status, option, section, or relationship type management UI.
- No mobile-specific redesign beyond ensuring directory/detail screens remain usable.

## Assumptions

- Milestones 01-03 are complete.
- `campaign_entities`, `entity_types`, `entity_section_definitions`, `status_definitions`, `entity_option_definitions`, `campaign_entity_summaries`, RLS helpers, and generated DB types exist.
- Section definitions were seeded in milestone 02, but actual `entity_sections` content rows were deferred until typed entity creation.
- `entity_sections` may not exist yet; if it does not, M04 owns the base table and first RLS policies, while M05 owns rich text editing and contribution rows.
- Creation workflows are permission-sensitive and must use RPCs.
- Detail reads may use safe views/RPCs rather than raw typed table reads where player/GM visibility differs.
- The app can start with simple form layouts for creation and dense read-only detail shells.

## Entity Scope

Implement typed detail tables and creation workflows for:

- characters
- NPCs
- parties
- factions
- locations
- quests
- sessions
- plot arcs
- encounters
- timeline events

Every created record must have:

- one `campaign_entities` row
- one matching typed detail row
- a sensible `list_caption`
- default visibility from `campaign_entity_type_settings` unless an allowed override is supplied
- default `entity_sections` rows from active section definitions for the entity type
- audit fields where practical

## Implementation Steps

### 1. Confirm And Adjust Schema Baseline

- Verify milestone 02 created the core registry and lookup tables as expected.
- Add migrations for missing typed detail tables from the content model spec.
- Add the base `entity_sections` table if it does not already exist:
  - `id`
  - `entity_id`
  - `section_definition_id`
  - `section_key`
  - `label`
  - `visibility`
  - `edit_policy`
  - `content_mode`
  - `body_json`
  - `body_text`
  - `body_preview`
  - `version_number`
  - audit fields
- Add same-campaign validation for structural foreign keys where practical.
- Add typed table constraints so each `entity_id` references the expected entity type.
- Prefer RPC validation first for cross-table type/campaign checks; add triggers or constraint helpers where they reduce real risk.
- Add or confirm useful indexes for directory reads:
  - `campaign_entities(campaign_id, entity_type_id, deleted_at, archived_at, updated_at desc)`
  - typed status/date/parent fields used by filters
  - `characters(controlling_user_id)` for future player character views
  - parent columns for factions, locations, and quests
- Keep all new tables under RLS.
- Add conservative `entity_sections` RLS:
  - visible only when the caller can view the parent entity and the section visibility permits it
  - mutable only through later RPCs, except for create RPC internals
  - private sections visible only to the creator/author where applicable
  - GM-only sections visible only to owners/GMs

### 2. Add Entity Aliases If Needed

- Add `entity_aliases` if it was deferred in milestone 02.
- Keep the first UI use narrow:
  - NPC nicknames
  - alternate names/titles as secondary context
- Alias rows must include visibility and soft-delete behavior.
- Player-facing alias reads must not expose GM-only aliases.
- Do not let aliases replace `list_caption` as the primary app label.
- Defer rich alias management UI if it distracts from core entity creation.

### 3. Implement Typed Creation RPCs

Add RPCs, or one well-typed dispatcher RPC if that is simpler to keep consistent, for creating:

- character
- NPC
- party
- faction
- location
- quest
- session
- plot arc
- encounter
- timeline event

Each create RPC must:

1. Require an authenticated caller.
2. Validate active campaign membership.
3. Validate the caller can create that entity type.
4. Validate the campaign entity type setting is enabled.
5. Apply default visibility from campaign entity type settings unless the caller supplies an allowed override.
6. Reject player-created typed entities in M04, including GM-only planning entity types.
7. Validate status ids against active system or campaign-scoped definitions for the expected `subject_key = entity` and matching entity type.
8. Validate option ids against active system or campaign-scoped definitions for the expected entity type and option `group_key`.
9. Validate same-campaign structural references.
10. Create `campaign_entities`.
11. Create the typed detail row.
12. Create default `entity_sections` rows from active section definitions.
13. Return created entity id plus summary/detail data needed by the UI.

Recommended create permissions:

- Owners and Game Masters can create every MVP entity type.
- Players can create player-allowed notes later, but cannot create typed campaign entities in this milestone.
- Character self-creation can remain deferred because the requirements say GMs create and assign characters.
- Timeline events with `private` visibility may be creator-only later, but keep creation GM-owned until role-aware visibility is hardened in milestone 06 unless product pressure says otherwise.

### 4. Define Entity Creation Inputs

Use concise, type-specific inputs.

Common fields:

- `campaign_id`
- `list_caption` optional, defaulted from the primary name/title
- `default_visibility` optional, restricted by role

Typed inputs:

- character: `name`, `status_id`, `controlling_user_id`
- NPC: `name`, `real_status_id`, optional `apparent_status_id`, optional `faction_entity_id`
- party: `name`
- faction: `name`, optional `status_id`, optional `parent_faction_entity_id`
- location: `name`, `location_type_option_id`, optional `status_id`, optional `parent_location_entity_id`
- quest: `title`, `status_id`, optional `priority_option_id`, `is_major`, optional `parent_quest_entity_id`
- session: `title`, `session_date`, `status_id`
- plot arc: `title`, `status_id`
- encounter: `title`, `encounter_type_option_id`, `status_id`, optional `related_session_entity_id`, optional `related_plot_arc_entity_id`
- timeline event: `title`, `date_expression`, optional `sort_key`, `event_type_option_id`, optional `related_session_entity_id`

Rules:

- `list_caption` defaults from `name` or `title`.
- Character `controlling_user_id` must be an active campaign member. For a solo owner/GM campaign, the create UI may default it to the creator.
- NPC `apparent_status_id` defaults to `real_status_id` unless explicitly supplied.
- Plot arcs and encounters default to GM-only visibility.
- Disabled campaign entity types are hidden from creation UI and rejected by create RPCs.
- Empty required text fields are rejected.
- All dates are stored in the expected database date/timestamp shape; display formatting stays in the UI.

### 5. Create Default Entity Sections

- For each active section definition matching the entity type, create one `entity_sections` row.
- Copy section definition defaults into the created section row:
  - `section_key`
  - `label`
  - `visibility`
  - `edit_policy`
  - `content_mode`
- Initialize `body_json` to an empty valid ProseMirror/Tiptap document.
- Initialize `body_text` and `body_preview` to empty strings or null consistently.
- Initialize `version_number` to `1`.
- Do not expose a rich text editor until milestone 05.
- Keep section creation inside the typed create transaction so detail shells can rely on the expected section rows.

### 6. Expand Safe Summary Reads

Update `campaign_entity_summaries` or equivalent safe read RPC to support directories.

Minimum fields:

- `campaign_id`
- `entity_id`
- `entity_type_key`
- `list_caption`
- `default_visibility`
- `status_key`
- `status_label`
- `relevant_date`
- `sort_key`
- `parent_entity_id`
- `related_session_entity_id`
- `updated_at`
- `archived_at`
- `deleted_at`

Useful type-specific nullable fields:

- character controlling user display label
- NPC apparent status label, never real status for player-safe reads
- faction parent label/id
- location type label and parent label/id
- quest priority label and major/minor flag
- session date/status
- encounter type and related session
- timeline date expression/type

Rules:

- Normal summary reads exclude soft-deleted records.
- Player-facing reads must not leak hidden or GM-only record labels/existence.
- Private records are visible only to their creator.
- Denormalized structural-reference labels must use null or generic placeholders when the referenced record is inaccessible, even if the source record is visible.
- Summary image fields remain nullable until media is implemented.
- If the view cannot safely support mixed visibility, use an RLS-gated RPC.

### 7. Add Safe Detail Read Surfaces

Create one detail read surface per entity type or one typed detail dispatcher.

Rules:

- Reads validate active campaign membership.
- Reads return only fields safe for the caller's role and record visibility.
- NPC player-safe reads omit `real_status_id` and GM-only structured fields.
- GM reads may include GM-only structured fields.
- Section rows are included only if visible to the caller.
- Deleted or inaccessible records return placeholder-safe states, not raw rows.
- Detail read shapes should be stable enough for detail shells and later rich text UI.
- Raw typed tables with GM-only columns, especially `npcs.real_status_id` and future stat block data, must not become broad player-readable tables.

### 8. Add Frontend Entity Feature Modules

Add feature folders/composables for entities.

Expected composables:

- `useCampaignEntitySummariesQuery`
- `useEntityDetailQuery`
- `useCreateEntityMutation`
- `useEntityTypeOptionsQuery`
- `useStatusOptionsQuery`
- `useEntityOptionDefinitionsQuery`

Rules:

- Components do not call Supabase directly.
- TanStack Query owns entity summaries and detail records.
- Pinia stores selected/open entity UI state only.
- Query keys include campaign id and entity/detail scope.
- Mutations update or invalidate summary and detail caches.
- Creation success opens/selects the created entity in the workspace shell.

### 9. Build Dense Directory Components

Create reusable components for:

- entity directory shell
- entity row
- entity type filter group
- status filter
- simple search over loaded authorized summaries
- empty state
- loading state
- permission/error state
- quick create trigger

Rules:

- Use `ListCaption` as primary label.
- Show compact metadata: entity type, status, parent/session context, visibility marker where useful.
- Keep row heights stable.
- Use icons from Lucide through existing Yife icon-button patterns.
- Default filters hide archived/deleted records.
- Directories must be reusable later as workbench widgets.
- Do not add TanStack Table unless a specific directory needs real table behavior.

### 10. Build Directory Routes And Workspace Integration

- Add campaign directory routes or route state for each MVP entity type.
- Add fallback navigation from the campaign directories menu.
- Selecting a directory should show the dense list in the main area if no workbench widget exists yet.
- Selecting a row should open the entity detail shell.
- If a selected entity is inaccessible, show a generic unavailable state and clear invalid selection where appropriate.
- Keep the workspace shell compact and role-aware.
- Hide GM-only directories from non-GM users.

### 11. Build Initial Detail Shells

Build read-only or minimally editable detail shells for:

- characters
- NPCs
- parties
- factions
- locations
- quests
- sessions
- plot arcs
- encounters
- timeline events

Each detail shell should show:

- title/list caption
- entity type
- status/type/date metadata
- visibility indicator
- basic structural references
- section placeholders from visible default sections
- related/context panel placeholder, not full relationships
- missing/inaccessible placeholder states

Rules:

- Do not add rich text editing yet.
- Do not expose GM-only fields to player detail shells.
- Detail shells should make it obvious which areas are GM-only or player-visible.
- Use small, dense controls and stable layout dimensions.

### 12. Add Creation UI

- Add a common quick-create entry point from the campaign workspace.
- Add type-specific creation forms.
- Validate with Zod and VeeValidate.
- Load statuses/options from safe composables rather than hardcoding labels in forms.
- Show role-appropriate and campaign-enabled entity types.
- Disable or hide controls the current user cannot use.
- Submit through create RPC mutation composables.
- Preserve form data on errors.
- On success, invalidate summaries and open the new detail shell.

### 13. Add Tests

Database/RLS/RPC tests:

- each create RPC rejects unauthenticated callers
- non-members cannot create records
- players cannot create any M04 typed entity, including GM-only planning records
- owners/GMs can create every entity type
- invalid status/option ids are rejected
- wrong-entity-type status ids and wrong-group option ids are rejected
- disabled campaign entity types cannot be created
- cross-campaign structural references are rejected
- character controlling users must be active campaign members
- NPC apparent status defaults to real status
- default section rows are created transactionally
- section RLS hides GM-only/default-private sections from unauthorized users
- summary reads include visible created records
- player summary reads omit GM-only and private records
- player summary reads use generic/null labels for hidden structural references
- NPC player reads do not expose real status

Unit/component tests:

- directory row renders `ListCaption` and compact metadata
- directory filters hide archived/deleted by default
- directory filters can rely on summary `archived_at` and `deleted_at` fields
- create forms validate required fields
- create forms hide disabled entity types and load only matching status/option groups
- create mutation invalidates summaries
- detail shell renders visible sections and placeholder states

Playwright smoke tests:

- create a campaign entity as owner/GM
- created entity appears in its directory
- open created entity detail shell
- non-GM user does not see GM-only directories
- inaccessible entity route shows a generic unavailable state

### 14. Verify Locally

Run:

```sh
pnpm supabase:start
pnpm supabase:reset
pnpm db:test
pnpm db:types
pnpm typecheck
pnpm lint
pnpm format:check
pnpm test:unit
pnpm build
pnpm test:e2e
```

If local Supabase or browser tests cannot run, document the exact blocker and the manual coverage used instead.

## Manual Steps Required From Andrew

- Confirm that player-created campaign entities stay deferred for M04.
- Review the initial create-form field set before implementation if campaign-specific fields feel too sparse.
- Manually verify dense directory usability on desktop and mobile after implementation.

## Success Criteria

- Typed detail tables exist for all MVP entity types.
- `entity_sections` exists with conservative RLS if it was not already present.
- Typed creation RPCs create registry, detail, and default section rows transactionally.
- Generated database types include the new tables/RPCs.
- Entity summaries support dense directories without unsafe client joins.
- Entity summaries expose archive/delete state and safe structural-reference placeholders.
- Components use Yife query/mutation composables, not direct Supabase calls.
- Owner/GM can create and browse all MVP entity types.
- Players cannot create typed campaign entities in M04.
- Non-GM users do not see GM-only directories or fields.
- Player-safe NPC reads omit real status.
- Directory rows use `ListCaption` as the primary label.
- Detail shells render basic metadata and visible section placeholders.
- Archived and soft-deleted records remain excluded from normal directories by default.
- Creation, directory, and detail smoke tests pass.

## What Good Looks Like

- A user can create the main campaign records and immediately browse/open them.
- The UI feels like a dense campaign workspace rather than a generic CRUD admin.
- Future milestones can add rich text, notes, relationships, media, and saved layouts without rewriting entity basics.
- Authorization-sensitive behavior is centralized in RLS/RPC/read surfaces, not patched in components.

## Resolved Decisions

- M04 implements creation for all MVP entity types, but keeps detail content shallow.
- Player-created typed entities are deferred; owners/GMs create typed campaign records in this milestone.
- Characters require an active campaign-member controlling user; the solo-owner create UI can default to the creator.
- Default `entity_sections` rows are created during typed entity creation, but editing them waits for M05.
- Plot arcs and encounters default to GM-only visibility.
- Disabled campaign entity types are not createable or shown as create targets in M04.
- Directory components are custom dense lists, not TanStack Table.
- Entity aliases may be added here only for simple alternate labels/nicknames; rich alias workflows are deferred.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Added explicit ownership of the base `entity_sections` table when milestone 02 only created section definitions.
- Added conservative section RLS requirements before section rows appear in detail shells.
- Tightened character creation so `controlling_user_id` is required and must be an active campaign member.

Pass 2 corrections incorporated:

- Strengthened safe detail-read guidance so raw typed tables with GM-only columns do not become player-readable shortcuts.
- Added tests for section visibility and character controller validation.

Pass 3 corrections incorporated:

- Added archive-state summary requirements so directory filters do not need unsafe joins.
- Tightened status/option validation to require the correct entity type, subject, and option group.
- Required safe placeholder behavior for hidden structural-reference labels in summaries.
- Required disabled campaign entity types to be hidden in creation UI and rejected by RPCs.
