# 11. Workbench Layouts, Command Palette, And Shortcuts

## Purpose

Implement Yife's dense power-user workspace.

This milestone should add constrained desktop workbench layouts, per-user/per-campaign saved layout state, open entity tabs, pins, current-session context, command palette, context-aware quick create, and a fixed MVP shortcut set. It should improve speed without turning the workspace into a fully freeform dashboard builder.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/07-relationships-timeline-and-context-panels.md`
- `docs/dev/milestones/08-sessions-storylines-encounters-and-activity.md`

## Goals

- Add user-campaign workspace and saved-layout persistence.
- Provide three GM default layouts and two player default layouts.
- Implement constrained workbench regions, zones, widget tabs, and persisted sizes.
- Implement main-zone open entity tabs with dedupe and placeholder restoration.
- Implement pinned entities per layout.
- Implement current-session context and override plumbing.
- Implement draft layout save/discard/reset behavior.
- Implement command palette / quick switcher.
- Implement context-aware quick create.
- Implement fixed MVP keyboard shortcuts.
- Add tests for layout persistence, placeholder hydration, command ranking, and shortcuts.

## Non-Goals

- No arbitrary nested split panes.
- No fully freeform dashboard builder.
- No user-customizable keyboard shortcuts.
- No mobile parity with desktop saved layouts.
- No realtime multi-user layout collaboration.
- No AI-ranked command palette.
- No command palette preview/details pane.
- No advanced graph/workflow canvas.

## Assumptions

- Earlier milestones provide entity summaries, details, notes, relationships, timeline, activity, and current-session helper queries.
- Desktop/larger-screen UX is the primary optimization target.
- Mobile simplification is finalized in M12; M11 should not force desktop saved layouts onto mobile.
- Layout state is personal workspace state scoped to one user and one campaign.
- Pinia may hold active UI state, but persisted layout state belongs in Supabase tables.

## Implementation Steps

### 1. Add Workspace Persistence Schema

Create or confirm:

- `user_campaign_workspaces`
- `saved_layouts`
- `saved_layout_pinned_entities`
- `saved_layout_open_tabs`
- `user_campaign_recent_entities`

Rules:

- Rows are scoped to `user_id` and `campaign_id`.
- Users can read/write only their own workspace rows for campaigns they actively belong to.
- Layout state is JSONB because it is UI configuration.
- Layout state is not a security boundary.
- Layout JSON must include a schema version and be validated by RPCs before save.
- Reject layout JSON that exceeds practical size/depth limits.
- Entity references inside layout state must hydrate through safe summaries/reference resolution.
- Deleted, hidden, or inaccessible layout references degrade through placeholders.
- Mobile does not need to consume desktop saved layout state.

### 2. Seed Default Layouts Per User/Campaign

Provide default layout records:

GM defaults:

- campaign development / writing prep
- session prep
- active session placeholder

Player defaults:

- player overview
- player session

Rules:

- Defaults are created for a user/campaign through an idempotent RPC.
- Role context controls which defaults are offered.
- Users with both GM and player roles can access both relevant default sets.
- Default layouts can be restored/reset.
- System defaults should be versioned by `source_default_key` so future updates can be detected.

### 3. Implement Workbench Region Model

Desktop regions:

- compact top navigation/action area
- left sidebar/list region
- central main detail region
- collapsible right context panel

Zones:

- Regions may contain zones.
- Side regions may split into stacked zones.
- Zones can contain one or more widgets as tabs.
- Main zone contains open entity tabs.

Rules:

- Enforce sensible min/max sizes.
- Persist region and zone sizes.
- Do not allow arbitrary nested split panes.
- Do not nest UI cards inside cards.
- Use stable dimensions for list rows, tabs, toolbars, and panels.

### 4. Define Widget Types

Supported MVP widgets:

- entity list
- notes
- relationships
- backlinks
- related records
- timeline
- search results
- recent activity
- entity detail in main zone
- current session context

Widget context modes:

- all records for current campaign
- selected entity related
- current session related
- pinned records
- recent records

Rules:

- Widgets use existing query composables.
- Widget configuration is small and typed.
- No query-builder widget configuration.
- Widgets respect campaign, role, selected entity, current session, and visibility permissions.

### 5. Implement Layout Draft Behavior

Structural edits update draft state:

- region structure
- zone structure
- widget/tab assignment
- sizes
- collapsed panel state when part of structure

Actions:

- save draft
- discard draft
- reset to default
- duplicate layout
- rename layout
- delete custom layout

Rules:

- `has_unsaved_structural_changes` shows subtle in-app indicator.
- Clicking the indicator opens save/discard/continue prompt.
- Low-risk state may auto-save:
  - selected tab
  - open tabs
  - recent entities
  - current route
  - current-session override
- Dangerous layout reset/delete actions require confirmation.

### 6. Implement Open Tabs And Pins

Open tabs:

- selecting an entity opens or selects an existing main tab
- duplicate tabs are prevented
- tabs can close
- selected tab persists
- inaccessible/deleted tabs restore as placeholders

Pinned entities:

- pins are per layout
- pins can include optional context
- pins render through safe summaries/reference resolution
- inaccessible/deleted pins degrade gracefully

Recent entities:

- persist per user/campaign
- update when visible entities open
- store entity ids and timestamps only, not copied labels or hidden metadata
- hydrate labels through safe summaries/reference resolution

### 7. Implement Current Session Context

- Reuse M08 current-session helper.
- Persist user override in `user_campaign_workspaces.current_session_entity_id`.
- Validate override against a visible session entity.
- If the override becomes inaccessible/deleted, show placeholder and fallback option.
- Session-oriented layouts use current session context for widgets and quick create defaults.

### 8. Implement Command Palette

Command palette groups:

- entities
- actions
- navigation
- layouts
- campaigns
- create actions

Supported behavior:

- search entities by `ListCaption`
- open entities
- switch campaigns
- switch saved layouts
- jump to major navigation areas
- trigger common actions
- trigger context-aware quick create

Rules:

- Scope entity search to active campaign by default.
- Global campaign switching remains available from authenticated areas.
- Results use compact metadata, not preview pane.
- Results respect membership, role, and visibility permissions.
- Command palette uses authorized summaries and safe actions only.
- Command palette dialog must be keyboard accessible, trap focus while open, and restore focus on close.
- Ranking is deterministic:
  - exact match
  - prefix match
  - substring/fuzzy match
  - recent entities
  - pinned entities
  - selected/current-session context
  - current layout relevance
- Optional prefixes:
  - `>` actions
  - `@` entities
  - `/` navigation
  - `+` create actions

### 9. Implement Quick Create

Quick create supports:

- notes attached to selected entity
- notes attached to current session
- common entity creation
- encounters related to current session
- timeline events related to current session
- Storylines and related records where context is safe

Rules:

- Context can include current campaign, selected entity, current session, active layout, and active widget.
- Prefills are suggestions, not hidden side effects.
- Quick create respects role and visibility.
- If context is ambiguous, show compact selector.
- Creation success opens/selects the created entity or note context.

### 10. Implement Keyboard Shortcuts

Fixed MVP shortcut set:

- `Mod+K`: open command palette
- `/`: focus current search field or open command palette search when no search field is active
- `N`: create new note from current context
- `E`: create new entity from current context
- `Alt+W`: close current main entity tab
- `Alt+[`: previous main tab
- `Alt+]`: next main tab
- `Mod+\\`: toggle right panel

Rules:

- `Mod` means Command on macOS and Control on Windows/Linux.
- Single-key shortcuts are active only when focus is not inside text inputs, selects, dialogs that capture text, or the rich text editor.
- Do not override browser-critical shortcuts where avoidable.
- Shortcut labels should appear in menus/tooltips where helpful.
- Custom shortcut editing is deferred.

### 11. Add Query And Mutation Composables

Expected query composables:

- `useUserCampaignWorkspaceQuery`
- `useSavedLayoutsQuery`
- `useActiveLayoutQuery`
- `useLayoutPinsQuery`
- `useOpenTabsQuery`
- `useRecentEntitiesQuery`
- `useCommandPaletteQuery`

Expected mutation composables:

- `useEnsureWorkspaceDefaultsMutation`
- `useSaveLayoutDraftMutation`
- `useDiscardLayoutDraftMutation`
- `useResetLayoutMutation`
- `useDuplicateLayoutMutation`
- `useRenameLayoutMutation`
- `useDeleteLayoutMutation`
- `useUpdateOpenTabsMutation`
- `useUpdatePinnedEntitiesMutation`
- `useUpdateCurrentSessionOverrideMutation`
- `useTrackRecentEntityMutation`

Rules:

- Structural layout mutations use RPCs.
- Layout hydration uses safe reference resolution for entity ids.
- TanStack Query owns persisted workspace state.
- Pinia owns active transient UI state only.

### 12. Add Tests

Database/RLS/RPC tests:

- users cannot read/write another user's workspace rows
- users cannot create workspace rows for campaigns they do not belong to
- default layout creation is idempotent
- layout save rejects invalid schema version or overlarge JSON
- structural save/discard/reset works
- current-session override rejects inaccessible/non-session entities
- open tab/pin hydration handles deleted/inaccessible entities

Unit/component tests:

- layout draft indicator appears only for structural changes
- open tabs dedupe entities
- command palette ranking is deterministic
- command prefixes filter result groups
- keyboard shortcuts are disabled in inputs/editors
- quick create builds safe context
- right panel toggle works

Playwright smoke tests:

- create/open several entity tabs and switch between them
- pin an entity and reload layout
- resize/collapse regions and save layout
- make draft change, discard, and verify previous layout
- use command palette to open entity, switch layout, and create note
- verify shortcuts work outside editor and do not fire inside editor

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

Document manual keyboard/browser checks if Playwright cannot cover a shortcut reliably.

## Manual Steps Required From Andrew

- Review the exact MVP shortcut set before implementation if any chord conflicts with personal workflow.
- Try all default layouts with a realistic campaign.
- Verify command palette ranking feels predictable.
- Manually check region resizing on desktop widths.

## Success Criteria

- Workspace layouts persist per user/campaign.
- Default GM/player layouts are available and restorable.
- Layout draft save/discard/reset works.
- Main entity tabs persist and restore through placeholders.
- Pins and recent entities persist without leaking hidden labels.
- Current-session context works with override/fallback behavior.
- Command palette supports entity search, actions, navigation, layout switching, campaign switching, and quick create.
- Fixed shortcuts work and do not fire inside text/editing contexts.
- Components use Yife composables and safe reads.

## What Good Looks Like

- A GM can keep a dense prep workspace open with lists, details, context, and session notes close at hand.
- A player can move quickly between visible campaign records without seeing GM-only data.
- The app feels keyboard-friendly without becoming configurable shortcut software.

## Resolved Decisions

- Workbench customization is constrained, not fully freeform.
- Saved layouts are per user/campaign in Supabase.
- Structural edits use draft save/discard/reset.
- Desktop saved layouts do not apply to mobile in MVP.
- Command ranking is deterministic, not AI/user-trained.
- Keyboard shortcuts are fixed in MVP.

## Decision Log

Shortcut chord mapping:

- Option 1: use mostly browser-like `Mod` chords.
- Option 2: use single-key app shortcuts outside editing contexts.
- Option 3: defer exact mapping to implementation.
- Decision: use a small hybrid fixed set: `Mod+K`, `/`, `N`, `E`, `Alt+W`, `Alt+[`, `Alt+]`, and `Mod+\\`. Single-key shortcuts are disabled in text/editing contexts. If any chord conflicts during manual verification, revise the mapping before implementation starts.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Required layout JSON schema versioning, validation, and practical size/depth limits.
- Required recent entities to persist ids/timestamps only, with labels hydrated through safe reads.

Pass 2 corrections incorporated:

- Added command palette accessibility requirements for focus trap and focus restore.
- Added database/RPC tests for invalid or overlarge layout JSON.
