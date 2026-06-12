# 08. Sessions, Quests, Encounters, Plot Arcs, And Activity

## Purpose

Build the campaign-prep and post-session maintenance workflows around sessions, quests, encounters, plot arcs, and recent activity.

This milestone should make session-oriented campaign management useful without becoming a virtual tabletop, combat tracker, or live-session automation system.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/05-notes-sections-rich-text-and-mentions.md`
- `docs/dev/milestones/06-role-aware-visibility-and-player-gm-views.md`
- `docs/dev/milestones/07-relationships-timeline-and-context-panels.md`

## Goals

- Add or finish session attendance tables and workflows.
- Build session directory, session detail, session notes, and session-oriented context surfaces.
- Build quest log views for player and GM use.
- Build lightweight encounter planning and outcome surfaces.
- Build plot arc planning views for owners/GMs.
- Add role-aware recent activity feed derived from existing metadata.
- Add current-session selection helpers for later layout work.
- Improve quick create/context behavior for sessions, quests, encounters, timeline events, and notes.
- Add tests for role-aware session/quest/encounter/plot arc/activity behavior.

## Non-Goals

- No combat tracker.
- No initiative, turn order, dice automation, or rules automation.
- No active-session live collaboration.
- No automatic timeline generation.
- No AI-derived summaries or activity.
- No append-only audit/event log unless derived activity is inadequate.
- No full calendar engine.
- No saved layout persistence.
- No party resources/funds; those are M09.

## Assumptions

- M04 created typed records for sessions, quests, encounters, plot arcs, and timeline events.
- M05 added notes and rich text sections.
- M07 added relationships, related-records, timeline browsing, and context panels.
- Activity can start as derived read models over existing metadata rather than an append-only event table.

## Implementation Steps

### 1. Add Session Attendance Tables

Create or confirm:

- `session_attending_users`
- `session_attending_characters`

Rules:

- Attending users and attending characters are separate facts.
- A character can attend when the controlling user is absent.
- `session_entity_id` must reference a session entity.
- `character_entity_id` must reference a character entity in the same campaign.
- `user_id` must belong to an active campaign membership.
- Unique constraints prevent duplicate attendance rows.
- Owners/GMs can manage attendance.
- Players can view visible attendance and may update their own attendance only if the product decision is explicitly enabled; default to owner/GM-managed attendance for M08.
- Attendance UI must use safe member profile display data only; it must not expose auth email or user settings.

### 2. Build Session Detail Workflow

Enhance session detail shells with:

- session date
- status
- visible summary section
- GM prep section
- GM private notes section
- attached notes
- attending users
- attending characters
- related quests
- related NPCs/locations/encounters
- related timeline events

Rules:

- Players see only shared/player-visible session sections and notes.
- Owners/GMs see prep and private sections.
- Session notes reuse the common notes component.
- Session date display uses native `Intl`; no date library unless implementation proves painful.
- Session status uses seeded definitions.

### 3. Build Session Directory And Filters

Add a dense session directory with:

- upcoming/planned sessions
- recent/completed sessions
- cancelled sessions behind filters
- date sorting
- status filtering
- quick open
- quick create

Rules:

- Default filters prioritize current and recent sessions.
- Player reads respect session visibility.
- Directory row heights remain stable.
- The directory can later become a workbench widget without rewriting data access.

### 4. Add Current-Session Helper

Implement a query/composable that resolves current session context:

1. nearest upcoming planned session
2. most recent completed session
3. manual override later from workspace settings

For M08:

- Store no persistent override unless the M11 workspace table already exists.
- Keep any temporary override in Pinia/local UI state.
- Return placeholder state when no sessions exist.
- Use this helper for session-oriented context panels and quick create defaults.

### 5. Build Quest Log Workflow

Enhance quest directory/detail with:

- status filters
- priority filter
- major/minor filter
- parent quest display
- related NPC/location/faction/session context
- player-facing quest log projection
- GM private details
- player observations/contributions

Rules:

- Players see player-visible quest log content.
- Owners/GMs see private quest details.
- Hidden quest status remains GM-only unless explicitly shared through safe reads.
- Parent quest structural links appear in related records.
- Quest workflows stay lightweight; no kanban board or automation.

### 6. Build Encounter Workflow

Enhance encounter detail/list surfaces with:

- encounter type
- status
- related session
- related plot arc
- related NPCs/locations/quests through relationships
- GM prep sections
- player-visible outcome section after play where exposed

Rules:

- Encounters default to GM-only.
- Player-visible outcomes are shared sections or notes, not exposure of the full encounter record unless explicitly made shared.
- No tactical stat block editor beyond existing simple GM-only structured/stat-block placeholder if present.
- No combat/run mode.

### 7. Build Plot Arc Workflow

Enhance plot arc detail/list surfaces with:

- status
- related quests
- related NPCs/locations/encounters
- GM planning sections
- outcome/summary sections where useful

Rules:

- Plot arcs are GM-only by default.
- Players should not see plot arc directories or hidden arc names.
- Plot arcs organize prep; they do not create player-facing navigation unless content is explicitly exposed through shared entities/sections.

### 8. Add Session-Oriented Quick Create

Use current context to prefill safe defaults for:

- session notes attached to current/selected session
- encounters related to current session
- timeline events related to current session
- notes attached to selected entity and current session where appropriate
- quest/session relationship prompts where useful

Rules:

- Quick create respects role and visibility permissions.
- Prefills must never expose hidden selected/current-session context to unauthorized users.
- If context is ambiguous, show a compact selector rather than guessing silently.

### 9. Add Recent Activity Feed

Create a derived role-aware read surface such as `campaign_activity_feed`.

Initial sources:

- created/updated campaign entities
- updated statuses
- new/updated notes
- updated entity sections
- new/updated contributions
- new/updated relationships
- uploaded media later
- membership/invitation changes later where visible

Minimum fields:

- `campaign_id`
- `activity_type`
- `subject_type`
- `subject_id`
- `subject_entity_id`
- `actor_user_id`
- `occurred_at`
- `label`
- `visibility`

Rules:

- Activity is derived and does not need immutable audit guarantees.
- Activity labels and subject links must be produced only after visibility filtering; do not expose raw hidden labels and then mask them in the client.
- Player activity must not reveal GM-only names, private notes, hidden relationships, or hidden source existence.
- Author-private activity is visible only to the author, even when viewed by owners/GMs who are not the author.
- Use generic placeholders only where the caller already has a legitimate visible context.
- Owners/GMs can see GM-only activity.
- An append-only event table is deferred unless derived activity cannot satisfy the UI.

### 10. Add Activity UI

Build compact activity surfaces:

- campaign overview recent activity block
- right panel activity widget where useful
- session-oriented activity widget

Rules:

- Rows show actor, action, subject label, timestamp, and type icon where visible.
- Rows link to visible subjects.
- Inaccessible subjects render safe placeholders.
- Empty/loading/error states are explicit.
- Keep activity concise; no field-level diff UI.

### 11. Add Query And Mutation Composables

Expected query composables:

- `useSessionsQuery`
- `useSessionDetailQuery`
- `useSessionAttendanceQuery`
- `useCurrentSessionQuery`
- `useQuestsQuery`
- `useQuestDetailQuery`
- `useEncountersQuery`
- `useEncounterDetailQuery`
- `usePlotArcsQuery`
- `usePlotArcDetailQuery`
- `useCampaignActivityQuery`

Expected mutation composables:

- `useUpdateSessionMutation`
- `useUpdateSessionAttendanceMutation`
- `useUpdateQuestMutation`
- `useUpdateEncounterMutation`
- `useUpdatePlotArcMutation`
- existing create entity mutation where creation is unchanged

Rules:

- Components do not call Supabase directly.
- TanStack Query owns server data.
- Mutations invalidate summaries, detail, related records, activity, and current-session caches where relevant.
- Pinia stores only current UI selection or temporary current-session override.

### 12. Add Tests

Database/RLS/RPC tests:

- session attendance rejects non-member users
- session attendance rejects cross-campaign characters
- duplicate attendance rows are prevented
- players cannot read GM prep/private session sections
- players cannot see GM-only plot arcs or encounters
- hidden quests do not appear in player quest log
- derived activity omits GM-only/private sources for players
- private note/contribution activity is visible only to the author
- activity feed labels are generated from visible safe subjects, not raw hidden labels
- current-session query respects visibility and date/status ordering

Unit/component tests:

- current-session resolver handles upcoming, completed, and empty cases
- session directory filters/sorts correctly
- quest log filters status/priority/major-minor
- activity row renders actor/action/subject safely
- quick create prefill respects selected entity/current session context

Playwright smoke tests:

- create planned session and mark attendance
- add session note with player-visible and GM-only variants
- verify player session detail omits GM prep
- create quest and verify player quest log projection
- create GM-only encounter/plot arc and verify player cannot see it
- verify recent activity differs for GM and player

### 13. Verify Locally

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

Document any manual verification for role-aware activity and session context.

## Manual Steps Required From Andrew

- Review the session workflow for actual table-use during prep and post-session cleanup.
- Verify quest log player/GM differences with realistic data.
- Review recent activity noise level and labels.

## Success Criteria

- Sessions support attendance, notes, visible summaries, and GM prep/private sections.
- Quest log is usable for player and GM views.
- Encounters and plot arcs are usable as lightweight GM planning records.
- Current-session helper chooses sensible defaults.
- Quick create uses current session/selected entity context safely.
- Recent activity shows meaningful changes without leaking hidden content.
- Tests cover visibility, attendance constraints, activity filtering, and browser smoke flows.

## What Good Looks Like

- A GM can prep a session, track attendance, connect relevant records, and add notes.
- A player can see the sessions, quests, notes, and activity they are allowed to know about.
- Activity gives useful orientation without pretending to be a full audit log.

## Resolved Decisions

- Session support is knowledge workflow, not live gameplay automation.
- Activity starts as a role-aware derived feed, not an append-only event log.
- Timeline events remain manual and may link to sessions.
- Attendance is owner/GM-managed in M08 unless explicitly expanded later.
- Encounters and plot arcs default to GM-only.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Required attendance UI to use safe member profile display data only.
- Tightened derived activity so labels and links are generated after visibility filtering.

Pass 2 corrections incorporated:

- Added author-private activity handling and tests so private note/contribution activity remains author-only.
- Preserved activity as derived/non-audit behavior while avoiding hidden-label client masking.
