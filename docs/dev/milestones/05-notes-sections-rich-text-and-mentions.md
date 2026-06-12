# 05. Notes, Sections, Rich Text, And Mentions

## Purpose

Implement Yife's long-form campaign knowledge layer.

This milestone should make notes, entity sections, player contributions, Tiptap rich text, optimistic concurrency, derived text, inline entity mentions, and backlinks work through safe Supabase RPC/read surfaces without introducing realtime collaboration or a complex merge editor.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/02-supabase-core-schema-and-security-foundation.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`

## Goals

- Add notes and note attachments.
- Add entity section contribution rows.
- Add rich text mention index rows.
- Implement RPCs for note, section, and contribution saves.
- Implement deterministic derived text and preview generation.
- Implement Tiptap Vue 3 editor wrappers for notes and entity sections.
- Implement inline `@` entity mention suggestions and rendering.
- Implement backlinks and placeholder-safe mention rendering.
- Implement stale-save conflict detection and simple reload-required UX.
- Add reusable notes and section components across entity detail shells.
- Add database, unit, component, and browser tests for rich text persistence, visibility, mentions, and conflicts.

## Non-Goals

- No realtime collaborative editing.
- No merge UI for stale rich text saves.
- No comments, suggestions, revision history, or track changes.
- No note mentions as mention targets.
- No image/media embeds in rich text.
- No generic file attachments.
- No custom rich text extensions beyond the MVP extension set.
- No full deep-search UI beyond storing derived text and basic body search read surfaces where useful.
- No approval workflow for player contributions.

## Assumptions

- Milestone 04 created typed entities and default `entity_sections` rows.
- `entity_sections` has conservative RLS and version columns.
- Tiptap dependencies were installed in milestone 01.
- Entity summaries are sufficient for mention suggestions over already authorized campaign entities.
- All rich text writes must go through RPCs because they update derived text, version numbers, audit fields, and mention indexes.

## Schema Scope

Add or confirm these tables:

- `notes`
- `note_attachments`
- `entity_section_contributions`
- `rich_text_entity_mentions`

If `entity_sections` was not completed in milestone 04, finish it before any editor UI ships.

## Implementation Steps

### 1. Add Notes Schema

Create `notes`:

- `id`
- `campaign_id`
- `author_user_id`
- `visibility`
- `body_json`
- `body_text`
- `body_preview`
- `version_number`
- audit fields
- `deleted_at`

Create `note_attachments`:

- `id`
- `note_id`
- `target_type` with `campaign` and `entity`
- nullable `entity_id`
- `created_by`
- `created_at`

Rules:

- Notes are not campaign entities.
- A note can attach to a campaign or one or more campaign entities.
- A note must have at least one valid attachment target before it is visible in normal UI.
- Campaign-level shared notes are visible to active campaign members according to note visibility.
- Entity attachments must point to entities in the same campaign as the note.
- Shared notes are visible only to members who can view at least one attached target.
- GM-only notes are visible to owners/GMs.
- Private notes are visible only to their author.
- Notes soft delete by default.
- Note attachments should not leak hidden entity labels to unauthorized users.

### 2. Add Contribution Rows

Create `entity_section_contributions`:

- `id`
- `section_id`
- `author_user_id`
- `visibility`
- `body_json`
- `body_text`
- `body_preview`
- `version_number`
- audit fields
- `deleted_at`

Rules:

- Contributions attach only to sections with `content_mode = contribution_feed` or `edit_policy = append_contributions`.
- Player-authored observations, theories, reminders, and subjective details use contribution rows.
- Contributions must remain attributed.
- Owners/GMs can moderate contribution rows where the section permits it.
- Promotion/copy into canonical section text can be a simple manual copy action; no automated approval workflow is required.

### 3. Add Mention Index

Create `rich_text_entity_mentions`:

- `id`
- `campaign_id`
- `source_type`
- nullable source ids for note, entity section, and contribution
- `mentioned_entity_id`
- `mention_text`
- `created_at`

Rules:

- Mention rows are derived and rebuildable.
- Inline mentions target campaign entities only.
- Notes are not mention targets in MVP.
- Mentioned entities must belong to the same campaign as the source.
- On every rich text save, old mention rows for the source are deleted and current rows are inserted transactionally.
- Hard-deleted mentioned entities should not break source content rendering.

### 4. Add Rich Text Normalization Helpers

Implement database or shared service helpers for:

- validating the JSON document shape
- deriving plain text
- deriving preview text
- extracting entity mention ids and display text
- checking same-campaign mention targets

Implementation choices:

- The client may derive text for immediate preview, but RPCs remain authoritative.
- If SQL JSON extraction becomes too awkward, implement simple deterministic extraction in a TypeScript utility and pass `body_text`, `body_preview`, and mention ids to the RPC for validation.
- Any TypeScript extraction helper must live in an app-owned service/utility used by mutation composables, not inside components.
- The RPC must reject inconsistent text/mention payloads where practical.
- Keep the MVP document format narrow and stable.
- Reject unsupported node/mark types rather than silently storing unknown rich text structures.

MVP Tiptap extensions:

- paragraph
- headings
- bold
- italic
- inline code
- bullet list
- ordered list
- link
- blockquote
- horizontal rule
- entity mention

### 5. Implement Save RPCs

Add RPCs for:

- create note
- update note body
- attach/detach note targets where permitted
- soft delete note
- save entity section body
- create contribution
- update contribution
- soft delete contribution
- rebuild mentions for one source

Each body-save RPC must:

1. Require authenticated caller.
2. Validate campaign membership.
3. Validate target visibility and edit permission.
4. Check expected `version_number`.
5. Validate body JSON.
6. Derive or validate `body_text` and `body_preview`.
7. Update the body and audit fields.
8. Increment `version_number`.
9. Rebuild mention rows for that source.
10. Return updated row metadata and visible mention resolutions.

Stale writes:

- Reject stale version numbers.
- Return a structured stale-conflict error.
- Do not attempt automatic merge.
- UI tells the user content changed and requires reload before saving again.

### 6. Harden RLS And Safe Reads

Add RLS policies for notes, attachments, contributions, and mention rows.

Rules:

- Direct note reads must enforce visibility.
- Direct contribution reads must enforce parent section visibility and contribution visibility.
- Mention reads must not expose sources or mentioned entity labels that the caller cannot access.
- Backlink reads should use a safe RPC/view rather than raw mention table reads when visibility is mixed.
- The app must not grant broad raw `rich_text_entity_mentions` reads to clients because source ids and mention text can leak hidden content.
- Deleted notes and contributions are hidden from normal reads.
- Non-members cannot read any campaign rich text data.

Safe read surfaces:

- notes for campaign or entity target
- visible sections for an entity
- section contribution feed
- backlinks for an entity
- mention reference resolution for rendering

### 7. Build Rich Text Editor Wrappers

Add Yife-owned editor components/composables:

- `YRichTextEditor`
- `YRichTextViewer`
- `YEntityMention`
- editor toolbar wrapper
- stale-conflict banner
- autosave-disabled save controls

Rules:

- Use Tiptap Vue 3.
- Use compact toolbar controls with Lucide icons where suitable.
- Icon-only controls need accessible labels and tooltips.
- Editing is explicit save/cancel in MVP; do not autosave rich text.
- Local unsaved state stays in component state.
- Server content stays in TanStack Query.
- Viewer output must render inaccessible mentions as generic placeholders.
- Links must validate URL shape and use safe `rel` values for external targets.
- Viewer rendering must not render arbitrary HTML from stored content.
- Link marks must reject unsafe protocols such as `javascript:` and malformed URLs.

### 8. Build Mention Suggestions

- Use authorized loaded entity summaries for instant mention suggestions.
- Scope suggestions to the active campaign.
- Show compact metadata to distinguish similar records:
  - entity type
  - status
  - parent/session context where available
  - visibility marker where permitted
- Never include inaccessible GM-only/private records for unauthorized users.
- Store mention attrs with durable entity id and mention label.
- Rendering should resolve current access state from safe summary/reference data rather than trusting stale label text in the document.
- Mention labels stored in JSON are fallback display text only; they are not permission authority.

### 9. Add Notes UI

Build reusable notes surfaces for:

- campaign notes
- entity-attached notes
- session notes later reused by milestone 08
- right-panel placeholder integration

Capabilities:

- list visible notes
- create note
- edit own or permitted notes
- attach note to current entity
- set visibility
- soft delete permitted notes
- show author and timestamps
- show empty/loading/error states

Rules:

- Private notes are author-only.
- GM-only notes get clear visibility indicators.
- Shared notes attached to an inaccessible entity must not leak entity details.
- The same notes component should work inside detail pages and later as a workbench widget.

### 10. Add Entity Section UI

On entity detail shells:

- Show visible sections in definition order.
- Use `YRichTextViewer` for saved content.
- Show edit controls only when the caller can edit the section.
- For contribution-feed sections, show attributed contribution rows.
- Allow players to append contributions only when the section edit policy permits it.
- Show clear visual distinction between:
  - GM canon/private content
  - player-visible canon
  - player-authored contributions
- Keep hidden sections completely absent for unauthorized users unless a generic placeholder is explicitly useful.

### 11. Add Backlinks

Create a safe backlinks read surface.

Backlink results should include:

- source type
- source id
- source entity id where applicable
- source label
- snippet or preview when visible
- author where visible
- updated/created timestamp
- visibility marker where permitted

Rules:

- Backlinks must respect source visibility and mentioned entity visibility.
- Unauthorized users must not see that a hidden note or GM-only section mentioned an entity.
- Deleted sources are omitted from normal backlink reads.
- Inaccessible source references degrade to generic placeholders only where the caller already has a legitimate reason to know a reference exists.

### 12. Add Feature Composables

Expected query composables:

- `useEntitySectionsQuery`
- `useEntityNotesQuery`
- `useCampaignNotesQuery`
- `useSectionContributionsQuery`
- `useEntityBacklinksQuery`

Expected mutation composables:

- `useSaveEntitySectionMutation`
- `useCreateNoteMutation`
- `useUpdateNoteMutation`
- `useDeleteNoteMutation`
- `useCreateContributionMutation`
- `useUpdateContributionMutation`
- `useDeleteContributionMutation`

Rules:

- Mutations update or invalidate notes, sections, contributions, backlinks, summaries, and activity-related caches where relevant.
- Query keys include campaign id and target/source ids.
- Components never call Supabase directly.
- Stale-conflict errors are handled consistently through a shared helper.

### 13. Add Tests

Database/RLS/RPC tests:

- non-members cannot read notes, sections, contributions, or mentions
- players cannot read GM-only notes/sections/contributions
- private notes are author-only, including from owners/GMs who are not the author
- save RPCs reject stale version numbers
- save RPCs increment versions and update audit fields
- save RPCs rebuild mention rows transactionally
- mention target must be in same campaign
- backlinks omit hidden sources for unauthorized users
- soft-deleted notes/contributions disappear from normal reads

Unit/component tests:

- editor emits valid MVP document JSON
- derived text/preview utility handles basic rich text
- mention suggestion filtering uses authorized summaries
- inaccessible mention renderer shows generic placeholder
- stale-conflict banner blocks blind overwrite
- note list handles empty/loading/error states
- viewer rejects or safely ignores unsupported/unsafe document structures

Playwright smoke tests:

- create an entity note with a mention
- reload and verify rich text renders
- open mentioned entity backlinks
- simulate stale save and verify conflict message
- verify player cannot see GM-only section/note content

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

If any browser/editor behavior must be manually checked, document the exact browsers and cases.

## Manual Steps Required From Andrew

- Manually verify Tiptap editor behavior in Chrome, Firefox, Safari, mobile Safari, and mobile Chrome if automated coverage is not practical.
- Review stale-save conflict wording.
- Verify player vs GM rendering of the same entity with mixed section visibility.

## Success Criteria

- Notes can be created, read, edited, attached, and soft-deleted through safe workflows.
- Notes cannot become normal visible records without a valid campaign or entity attachment target.
- Entity sections can be viewed and saved with version checks.
- Player contribution sections support attributed contribution rows.
- Rich text JSON is stored as source of truth.
- Derived body text and preview text are maintained.
- Inline entity mentions persist durable entity ids and render safely.
- Mention index rows are rebuilt on save.
- Backlinks work without leaking hidden sources.
- Stale rich text saves are rejected with a clear reload-required UX.
- Components use Yife composables, not direct Supabase calls.
- Database, unit, component, build, and browser checks pass.

## What Good Looks Like

- Campaign knowledge can finally live in the app, not only in typed metadata.
- Players can contribute observations without overwriting GM canon.
- Mentions and backlinks make notes and sections navigable while preserving visibility boundaries.
- The conflict model is simple, predictable, and test-backed.

## Resolved Decisions

- Rich text saves use RPCs with version checks, derived text, and mention rebuilds.
- Inline mentions target campaign entities only; notes are not mention targets in MVP.
- Stale-save handling is reload-required, with no merge UI.
- Contributions use attributed rows rather than shared editable blobs.
- Rich text editing uses explicit save/cancel, not autosave.
- Media embeds and generic attachments are deferred.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Required notes to have valid attachment targets and clarified campaign-level shared note visibility.
- Tightened mention/backlink guidance so raw mention rows are not exposed directly to clients.
- Clarified that mention labels stored in JSON are fallback text, not authorization or display authority.

Pass 2 corrections incorporated:

- Added rich text document allow-listing and safe rendering requirements.
- Required unsafe link protocols and arbitrary stored HTML to be rejected or safely ignored.
- Kept any TypeScript text/mention extraction inside app-owned utilities used by composables, not components.
