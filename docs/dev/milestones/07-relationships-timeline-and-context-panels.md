# 07. Relationships, Timeline, And Context Panels

## Purpose

Turn isolated campaign records into navigable campaign knowledge.

This milestone should add explicit entity relationships, role-safe related-record reads, timeline browsing, backlinks integration, and first right-context panel widgets. It should combine explicit relationships, structural links, and rich text mentions for navigation while keeping each source distinct and visibility-safe.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/05-notes-sections-rich-text-and-mentions.md`
- `docs/dev/milestones/06-role-aware-visibility-and-player-gm-views.md`

## Goals

- Add explicit entity relationship storage and RPCs.
- Expose a role-safe related-records read surface that unions explicit relationships, structural links, and mentions.
- Keep structural relationships in typed columns and do not mirror them into explicit relationships.
- Add relationship visibility for `shared` and `gm_only`.
- Add reusable relationship picker and relationship list components.
- Add timeline event directory/detail enhancements and timeline widgets.
- Add right contextual panel widgets for notes, relationships, backlinks, and related records.
- Ensure inaccessible/deleted relationship targets render placeholder-safe states.
- Add tests for relationship visibility, directionality, related-record union behavior, and context panel rendering.

## Non-Goals

- No custom relationship type management UI.
- No advanced graph visualization.
- No private explicit relationships.
- No automatic timeline generation from sessions or notes.
- No AI-derived timeline events.
- No saved workbench layout customization.
- No full active-session tooling.
- No arbitrary note mentions as relationship targets.

## Assumptions

- Milestone 04 created typed entity tables and structural link columns.
- Milestone 05 created mention indexes and backlinks.
- Milestone 06 created placeholder-safe reference resolution and hardened visibility rules.
- Seeded system relationship types already exist from milestone 02.
- Timeline events exist as typed campaign entities, but their richer browsing/context experience is still thin.

## Implementation Steps

### 1. Add Explicit Relationship Table

Create or confirm `entity_relationships`:

- `id`
- `campaign_id`
- `source_entity_id`
- `target_entity_id`
- `relationship_type_id`
- `visibility`
- audit fields
- `deleted_at`

Rules:

- Source and target entities must belong to the same campaign.
- Source and target cannot be hard-deleted.
- Relationship visibility is `shared` or `gm_only` in MVP.
- Private explicit relationships are deferred.
- Relationship types come from seeded system rows or active campaign-scoped rows if already supported by schema.
- Deleted relationships are hidden from normal reads.
- Relationship rows are user-managed explicit relationships only.
- Enable RLS on `entity_relationships` and keep direct writes blocked unless a simple RLS-covered edit is intentionally added later.
- Prevent duplicate active explicit relationships for the same source, target, relationship type, and visibility. For undirected types, normalize endpoint order before enforcing uniqueness.

### 2. Implement Relationship Type Semantics

Use seeded `relationship_types`:

- `related_to`
- `ally_of`
- `enemy_of`
- `member_of`
- `leader_of`
- `located_in`
- `owns`
- `works_for`
- `seeks`
- `protects`
- `threatens`
- `created_by`
- `parent_of`
- `child_of`

Rules:

- Directionality comes from `relationship_types.default_directionality`.
- Undirected relationship types should display from either side with the same label.
- Directed relationship types should use `label` from source to target and `inverse_label` from target to source where available.
- The user does not configure direction per relationship beyond choosing source/target and type.
- Custom relationship type UI is not included.

### 3. Add Relationship RPCs

Add RPCs for:

- create relationship
- update relationship type/visibility
- soft delete relationship
- restore relationship if needed

Each RPC must:

1. Require authenticated caller.
2. Validate active campaign membership.
3. Validate create/edit/delete permission.
4. Validate both entities are visible enough for the intended relationship.
5. Validate relationship type is active and allowed.
6. Validate visibility choice is allowed for the caller.
7. Reject cross-campaign relationships.
8. Return updated relationship and related-record summary data.

Recommended permissions:

- Owners/GMs can create and manage shared or GM-only relationships.
- Players do not create explicit relationships in M07. They can create rich text mentions and section/note contributions where permitted.
- Players never create GM-only relationships.
- Shared relationships must have endpoints visible to the shared audience. If either endpoint is GM-only or otherwise not player-visible, the RPC must reject `shared` or force an explicit GM-only choice.

### 4. Add Related-Records Read Surface

Create a view or RPC similar to `entity_related_records`.

It should union:

- explicit relationships from `entity_relationships`
- structural links from typed tables
- mention links from `rich_text_entity_mentions`

Minimum fields:

- `campaign_id`
- `source_entity_id`
- `target_entity_id`
- `relation_source`
- `relationship_type_key`
- `label`
- `visibility`
- `source_type`
- nullable `source_note_id`
- nullable `source_section_id`
- nullable `source_contribution_id`
- `source_summary`
- nullable `mention_count`
- `updated_at` or `created_at`

Rules:

- `relation_source` is `explicit`, `structural`, or `mention`.
- Structural links stay read-only in this surface.
- Mention links are derived read-only relationships.
- Multiple mentions between the same source and target should be deduped or grouped for display, while preserving safe source locators and counts so the UI can navigate to the underlying note/section/contribution context.
- Relationship source must be shown in UI so users know whether they can edit it.
- Explicit relationship visibility filtering must apply to source entity, target entity, and relationship row visibility.
- Structural relationship visibility filtering must apply to source entity, target entity, and the typed row/field visibility rules that create the structural link.
- Mention-derived related-record visibility must reuse the same security envelope as backlinks:
  - source entity visibility
  - current target entity visibility
  - note visibility for note sources
  - section visibility for section sources
  - parent section visibility plus contribution-row visibility for contribution sources
  - `private`, `gm_only`, and `character_owner_gm` restrictions from milestone 06
- Unauthorized users must not learn hidden mention/relationship existence through row presence, grouped counts, or source labels.
- Player reads must not reveal GM-only relationship existence even when both entities are otherwise visible.
- Mention/group rows must use the milestone 06 placeholder-resolution rules when a previously valid target later becomes deleted or inaccessible.
- Arbitrary related-record reads for unauthorized callers should collapse hidden target states to coarse placeholder-safe outcomes rather than exposing precise hidden-state reasons unless the caller already has legitimate visible source context.

### 5. Add Structural Link Coverage

Include structural links from:

- location parent
- storyline parent
- faction parent
- encounter related session
- encounter related storyline
- timeline event related session
- character controlling user context where useful, but do not treat users as campaign entities
- party membership links later extended in M09

Rules:

- Structural links are not duplicated into `entity_relationships`.
- Editing structural links remains part of the typed entity edit workflow, not relationship UI.
- Related-record UI may show them with source label `structural`.

### 6. Add Relationship UI Components

Build reusable components:

- relationship list
- relationship row
- relationship create/edit dialog
- entity relationship picker
- related records grouped by source
- placeholder-safe related target row

Rules:

- Use `ListCaption` from safe summaries.
- Show relationship type and direction compactly.
- Show visibility badges for GM-only relationships to GMs.
- Hide GM-only relationship controls from players.
- Use fixed row heights and compact controls.
- Use empty/loading/error states.

### 7. Add Timeline Browsing

Enhance timeline event support with:

- timeline directory/list
- timeline filters by event type, related session, related entity, and visibility where permitted
- ordering by `sort_key` first, then display date fallback
- compact timeline row with date expression, type, status/visibility, and related context
- timeline detail shell with sections and related records

Rules:

- Timeline dates use human-readable `date_expression` plus optional `sort_key`.
- No custom fantasy calendar engine.
- Timeline events are manually created.
- Private timeline events are visible only to their creator.
- GM-only timeline events are owner/GM-visible only.
- Player timeline reads must not leak hidden events through gaps/counts.
- `related session` filter uses the typed `timeline_events.related_session_entity_id`.
- `related entity` filter must be defined explicitly in the implementation/read surface. In MVP it should match timeline events linked to the selected entity through explicit relationships plus typed structural links, and must not treat mention-derived links as timeline-filter matches.

### 8. Add Context Panel Widgets

Implement the first right contextual panel widgets:

- notes for selected entity
- explicit relationships
- related records
- backlinks
- timeline context where relevant

Rules:

- The right panel defaults to selected-entity context.
- If no entity is selected, show campaign-level context or an empty state.
- Widgets must use the same safe query composables as detail screens.
- Widgets should be reusable later as workbench widgets.
- Pinned context and saved layout behavior are deferred to M11.
- Collapsed right panel UI state may remain Pinia/local until layout persistence exists.

### 9. Add Query And Mutation Composables

Expected query composables:

- `useEntityRelationshipsQuery`
- `useEntityRelatedRecordsQuery`
- `useRelationshipTypesQuery`
- `useTimelineEventsQuery`
- `useTimelineEventDetailQuery`
- `useContextPanelWidgetsQuery` only if useful as an orchestration wrapper

Expected mutation composables:

- `useCreateEntityRelationshipMutation`
- `useUpdateEntityRelationshipMutation`
- `useDeleteEntityRelationshipMutation`
- `useUpdateStructuralLinkMutation` only for typed entity edit flows if included

Rules:

- TanStack Query owns related server state.
- Pinia stores selected entity and panel collapsed state only.
- Relationship mutations invalidate relationship, related-record, backlink, summary, and activity-related caches where relevant.
- Components do not call Supabase directly.

### 10. Add Tests

Database/RLS/RPC tests:

- non-members cannot read or write relationships
- players cannot read GM-only relationships
- GM-only relationship existence is hidden even when both endpoint entities are shared
- cross-campaign relationships are rejected
- invalid relationship types are rejected
- duplicate active relationships are rejected or idempotently returned
- shared relationships cannot point at GM-only/inaccessible endpoints
- direction/inverse labels resolve correctly
- related-record surface includes explicit, structural, and mention sources
- related-record surface filters hidden mention sources
- timeline private events are author-only
- timeline GM-only events are GM-only

Unit/component tests:

- relationship rows render source, target, type, direction, and visibility correctly
- related-record grouping distinguishes explicit, structural, and mention links
- relationship picker uses authorized summaries only
- context widgets show empty/loading/error states
- timeline sorting respects `sort_key`
- inaccessible targets render generic placeholders

Playwright smoke tests:

- create relationship between two visible entities
- verify reciprocal related-record display
- create GM-only relationship and verify player cannot see it
- verify structural parent link appears in related records
- verify mention appears in related records/backlinks
- open timeline directory and filter by type/session
- verify context panel updates when selected entity changes

### 11. Verify Locally

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

Document any relationship visibility or timeline behavior that requires manual owner/GM/player verification.

## Manual Steps Required From Andrew

- Review the relationship create/edit UI for speed and clarity.
- Verify related-record grouping feels useful rather than noisy.
- Review timeline sorting behavior with real campaign-style date expressions.

## Success Criteria

- Explicit relationships can be created, listed, updated, and soft-deleted where permitted.
- Owner/GM relationship management works; player explicit relationship creation is deferred.
- Relationship direction and inverse labels render correctly.
- Related records combine explicit, structural, and mention sources without losing source distinction.
- Structural links are not duplicated into explicit relationship rows.
- GM-only relationships do not leak to players.
- Timeline event lists and detail shells respect visibility.
- Right context panel widgets show notes, relationships, related records, and backlinks for the selected entity.
- Inaccessible/deleted related targets render safe placeholders.
- Tests cover owner/GM/player/non-member visibility and cross-campaign rejection.

## What Good Looks Like

- An entity page starts to feel connected to the rest of the campaign.
- Users can navigate from notes, mentions, relationships, timeline events, and structural context without losing role safety.
- The app gains useful context panels without committing to the full saved layout system yet.

## Resolved Decisions

- Structural links remain in typed columns and are not mirrored into explicit relationships.
- Related-record UI uses a union read surface over explicit, structural, and mention sources.
- Explicit relationships support `shared` and `gm_only` visibility only in MVP.
- Owners/GMs manage explicit relationships in M07; player-authored linkage happens through rich text mentions and contributions.
- Relationship type direction comes from seeded type defaults.
- Custom relationship type UI and advanced graph visualization are deferred.
- Timeline events remain manually created; automatic/AI timeline extraction is deferred.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Resolved player-created explicit relationships conservatively: owners/GMs manage explicit relationships in M07.
- Required RLS on relationship rows and blocked direct client writes by default.
- Added endpoint visibility validation so shared relationships cannot point at GM-only/inaccessible endpoints.

Pass 2 corrections incorporated:

- Added duplicate active relationship handling, including normalized endpoint ordering for undirected types.
- Added dedupe/grouping guidance for repeated mention-derived related records.
