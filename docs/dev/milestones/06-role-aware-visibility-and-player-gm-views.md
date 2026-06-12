# 06. Role-Aware Visibility And Player/GM Views

## Purpose

Harden Yife's role-aware read and interaction model so mixed Game Master/player campaigns can safely use the same app.

This milestone should make visibility behavior trustworthy across entity summaries, detail reads, sections, notes, contributions, NPC status fields, placeholders, navigation, and player/GM view modes. The UI may be compact and pragmatic, but it must not rely on client-side hiding as the data security boundary.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/05-notes-sections-rich-text-and-mentions.md`

## Goals

- Harden player-facing and mixed-visibility read surfaces.
- Make GM/player role context clear in the campaign workspace.
- Ensure NPC real status and apparent status behave correctly.
- Distinguish GM canon, player-visible canon, and player-authored knowledge.
- Add placeholder-safe resolution for inaccessible, private, GM-only, deleted, and hard-deleted entity references.
- Ensure private notes/timeline/contributions are author-only.
- Add player contribution workflows where section edit policies allow them.
- Add tests proving player users cannot access GM-only data through summaries, detail reads, notes, sections, mentions, backlinks, or routes.

## Non-Goals

- No invitation or membership-management UI.
- No custom role definitions.
- No per-field arbitrary permission editor.
- No approval workflow for player contributions.
- No private media.
- No realtime collaboration.
- No soft-delete/restore management UI beyond placeholder support.
- No full audit history.

## Assumptions

- Milestones 04 and 05 created typed entities, default sections, notes, contributions, mentions, and backlinks.
- Campaign membership and role helpers are already RLS-tested.
- Section-level visibility/editability is the main MVP mechanism for mixed-visibility records.
- Some structured GM-only fields, especially NPC `real_status_id`, remain in typed tables but are exposed only through safe read surfaces.
- Route middleware remains UX only; Supabase RLS, views, and RPCs are the real security boundary.

## Implementation Steps

### 1. Audit Existing Read Surfaces

Review all app data reads added in milestones 03-05.

Classify each read as:

- safe for all active campaign members
- owner/GM only
- author-private
- creator-private
- placeholder/reference resolution only

Rules:

- Components must not call raw typed tables directly.
- Mixed player/GM surfaces must use safe views or RPCs.
- Views must use `security_invoker = true`, or the behavior must be implemented as RLS-gated RPCs.
- Any read that includes GM-only columns must be owner/GM gated.
- Any read that can reveal hidden source existence must be explicitly tested.

### 2. Define Effective Role/View Context

Implement a campaign role context composable derived from membership summary query data.

It should expose:

- active campaign id
- role keys
- `isOwner`
- `isGameMaster`
- `isPlayer`
- effective workspace mode: GM, player, or mixed
- selected view preference when the user has multiple roles

Rules:

- Role facts come from TanStack Query membership data, not Pinia.
- Pinia may store the selected view preference only.
- View preference affects UI framing, filters, and defaults; it never grants access.
- If a GM chooses player view, read surfaces should request player-safe projections where useful to preview player experience.
- If the server denies data, the UI shows permission/error states rather than falling back to broader reads.

### 3. Harden Entity Summary Visibility

Ensure entity summary reads obey:

- `shared`: visible to active campaign members
- `gm_only`: visible to owners/GMs
- `private`: visible only to creator/author
- soft-deleted: excluded from normal summaries

Rules:

- Player summary reads must not include hidden labels, status labels, parent labels, image alt text, or type-specific metadata for inaccessible records.
- GM summary reads may include GM-only records.
- Private records are still author-only unless a future product decision changes this.
- Directory counts, filters, and empty states must not reveal hidden record existence to unauthorized users.
- Command palette and mention suggestions must consume the same safe summaries.

### 4. Harden Entity Detail Reads

For every entity type, verify detail read shapes are role-safe.

Rules:

- Player reads include only player-visible typed fields and visible sections.
- Owner/GM reads include GM-visible typed fields and sections.
- NPC player reads include `apparent_status_id` only.
- NPC owner/GM reads include `real_status_id`, `apparent_status_id`, and the apparent override state if implemented.
- Plot arcs and encounters default to owner/GM-only reads.
- Private timeline events are visible only to their creator.
- Detail read responses must include explicit capability flags for UI controls, such as `can_edit`, `can_delete`, `can_add_note`, and `can_add_contribution`.

### 5. Implement NPC Apparent/Real Status Behavior

Add or confirm RPC behavior for NPC status updates.

Rules:

- `real_status_id` is GM-only.
- `apparent_status_id` is player-visible.
- When a GM changes real status, apparent status defaults to the new real status unless the GM intentionally preserves or sets a different apparent status.
- The UI must make the difference between apparent and real status clear to GMs.
- Player UI must never show real status, override controls, or labels implying hidden truth exists.
- Tests must cover status update behavior and player-safe reads.

### 6. Harden Notes, Sections, Contributions, Mentions, And Backlinks

Verify the M05 rich text surfaces under player/GM role combinations.

Rules:

- Shared notes respect attached target visibility.
- GM-only notes are owner/GM-visible only.
- Private notes are author-only.
- GM-only sections are owner/GM-visible only.
- Player contribution sections show attributed player-authored rows.
- Player contribution controls appear only when the edit policy allows append/contribution behavior.
- Mention rendering resolves current visibility state and does not trust stale mention labels.
- Backlinks omit hidden sources for unauthorized users.

### 7. Add Placeholder-Safe Reference Resolution

Add a safe reference resolution surface such as:

- `resolve_entity_references`
- `entity_reference_resolution`

Minimum shape:

- `requested_entity_id`
- `resolution_state`
- `display_label`
- `entity_type_key`
- `can_restore`
- `can_request_access`

Allowed states:

- `visible`
- `deleted`
- `private`
- `gm_only`
- `inaccessible`
- `hard_deleted`

Rules:

- Unauthorized players get generic private/unavailable/deleted placeholders without labels.
- For arbitrary requested ids, unauthorized callers should receive coarse `inaccessible` or `hard_deleted` states rather than precise `private` or `gm_only` states.
- More specific states such as `deleted`, `private`, or `gm_only` are allowed only when the caller already has a legitimate visible source context for the reference or has management/restore permission.
- GMs and users with restore permission may get more specific deleted/archived context.
- Hard-deleted references remain unavailable.
- Placeholder labels must be short and must not expose hidden entity names.
- Use this surface for mentions, backlinks, relationship placeholders later, open tabs later, pins later, recent activity later, and direct inaccessible routes.

### 8. Add Player And GM Detail Framing

Update entity detail shells so users can visually distinguish:

- GM canon/private content
- player-visible canon
- player-authored knowledge
- private user notes
- unavailable/private/deleted placeholders

Rules:

- Use compact visibility badges and section headers.
- Do not use large explanatory copy inside dense workspace screens.
- Empty hidden sections should generally be absent for unauthorized users.
- GMs viewing player mode should see only player-safe projections in preview areas where feasible.
- Keep keyboard/focus behavior accessible.

### 9. Add Player Contribution Workflows

For sections with `append_contributions` or `contribution_feed`:

- Allow permitted players to add contributions.
- Let authors edit their own contributions where permitted.
- Let owners/GMs edit, delete, or moderate contributions where permitted.
- Show author and timestamp.
- Keep contribution visibility explicit.
- Do not add approval queues.

### 10. Add Visibility Controls For Allowed Fields

Add compact controls where users can set allowed visibility:

- entity default visibility during create/edit where permitted
- note visibility
- section visibility for owners/GMs where permitted
- contribution visibility where permitted

Rules:

- Controls must show only allowed options for the current user's role.
- Controls must not imply private content can be made visible by unauthorized users.
- Visibility changes that affect other users should require a clear save action.
- Do not build a full permission matrix editor.

### 11. Add Tests

Database/RLS/RPC tests:

- player cannot read GM-only entity summary labels
- player cannot read GM-only detail fields
- player cannot read NPC real status
- player cannot infer GM-only records through directory counts or command palette results
- private notes/timeline/contributions are author-only
- GM can read GM-only sections and records
- GM player-preview read uses player-safe projection where implemented
- mention/backlink reads do not expose hidden source labels
- reference resolution returns generic placeholders for unauthorized players
- arbitrary reference resolution requests do not reveal whether a hidden id is private, GM-only, or nonexistent
- deleted reference resolution returns restorable detail only to permitted users

Unit/component tests:

- role context derives flags from membership query data
- Pinia stores only selected view preference, not role authority
- visibility badges render compact labels
- detail shells omit hidden sections for unauthorized users
- placeholder components do not render hidden labels
- NPC player and GM views show different status fields

Playwright smoke tests:

- seed a campaign with owner/GM/player users
- create shared and GM-only NPCs
- verify player directory cannot see GM-only NPC
- verify player NPC detail omits real status
- verify GM detail shows real/apparent status controls
- verify private note is author-only
- verify inaccessible mention renders as generic placeholder

### 12. Verify Locally

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

Any manual verification must use at least owner/GM/player personas and document exact data used.

## Manual Steps Required From Andrew

- Review GM/player visual framing in detail shells.
- Manually inspect the same campaign as owner/GM/player to confirm hidden data is not visually leaked.
- Confirm the MVP private-content rule remains author-only even for owners/GMs.

## Success Criteria

- Player-facing and mixed-visibility reads use safe server read surfaces.
- Client UI does not receive GM-only fields in player-safe responses.
- NPC real status is GM-only and apparent status is player-visible.
- Private content is author-only.
- GMs can clearly distinguish GM canon, player-visible canon, and player-authored knowledge.
- Player contribution controls appear only where edit policies allow them.
- Inaccessible references render safe placeholders.
- Directory/search/palette counts and results do not leak hidden record existence.
- Tests cover owner, GM, player, non-member, private author, and deleted-reference cases.

## What Good Looks Like

- A player can browse a campaign without accidentally seeing spoilers.
- A GM can work in the same data set with private planning context.
- Placeholders are boring and consistent rather than leaking hidden names.
- Later relationships, layouts, activity, and command palette features can reuse the same reference-resolution model.

## Resolved Decisions

- Mixed visibility must be enforced by safe views/RPCs, not by client-side filtering.
- NPCs keep separate real and apparent statuses.
- Author-private notes, timeline events, and contributions remain author-only in MVP, including from owners/GMs who are not the author.
- A GM/player multi-role user may choose a view preference, but that preference does not grant permissions.
- Placeholder resolution becomes a shared API shape for future relationships, tabs, pins, activity, and layouts.

## Decision Log

Author-private override:

- Option 1: owners/GMs can override and read all private content in their campaigns.
- Option 2: author-private content remains author-only unless explicitly shared.
- Decision: choose option 2 for MVP. It matches the current privacy language and keeps private notes meaningful. If owner override becomes necessary later, it should be promoted as a product/security decision with clear UI copy.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Tightened reference resolution so arbitrary id lookups do not reveal whether a hidden record is private, GM-only, or nonexistent.
- Required precise placeholder states only when the caller has a legitimate visible source context or restore/management permission.

Pass 2 corrections incorporated:

- Added explicit tests for arbitrary reference-resolution enumeration leakage.
- Kept author-private content author-only as a documented product/security decision instead of an unresolved implementation question.
