# Yife Content Model And Database Decisions

This file records the settled content model and database decisions from the data model review.

## 1. Core Model

Decision: Use a hybrid model.

- `campaign_entities` is the shared registry for major campaign records.
- Type-specific tables store structured fields.
- Shared systems reference `campaign_entities.id`.
- Long-form prose goes in `entity_sections`.
- Notes are separate records, not campaign entities.

Rationale: The app needs generic entity behavior, but NPCs, quests, sessions, locations, timeline events, parties, plot arcs, and encounters have real type-specific behavior.

## 2. Notes

Decision: Notes are not `campaign_entities`.

- Notes live in `notes`.
- Notes attach to entities through `note_attachments`.
- Notes are searchable and visible through note-aware systems.
- Rich text `@` mentions do not target notes in MVP.

Rationale: Keeps the entity registry focused and avoids flooding entity UI with note records.

## 3. Sections

Decision: Use `entity_sections` for section-level content and permissions.

- All substantial prose goes in sections.
- This includes player summaries, canonical descriptions, GM details, player observations, backstories, and session summaries.
- Typed tables keep structured/filterable fields only.

Rationale: Section rows map directly to the visibility/editability requirements and avoid column-level RLS problems.

## 4. Section Definitions

Decision: Section definitions are database-driven.

- Use `entity_section_definitions`.
- Seed default sections per entity type.
- Custom sections are post-MVP.

Rationale: Predictable sections make create flows, UI, RLS, and AI-assisted development clearer.

## 5. Rich Text Storage

Decision: Store rich text as JSON source plus derived text.

- `body_json` is source of truth.
- `body_text` supports search and previews.
- `body_preview` is optional.
- Data model should support Tiptap/ProseMirror-style JSON.

Rationale: Supports durable mentions and future collaboration better than Markdown-only storage.

## 6. Versioning

Decision: No full content history in MVP.

- Notes and sections get `version_number`, `updated_by`, and timestamps.
- No historical snapshot table yet.

Rationale: Gives optimistic concurrency and a future migration path without building revision history early.

## 7. Rich Text Saves

Decision: Save notes and sections through RPCs.

- RPC checks expected `version_number`.
- RPC updates JSON/text fields.
- RPC increments version.
- RPC rebuilds mention rows.
- Stale writes are rejected.

Rationale: Rich text saves have derived data and concurrency concerns.

## 8. Inline Mentions

Decision: Store inline mentions in JSON and extracted rows.

- JSON is source of truth.
- `rich_text_entity_mentions` is rebuildable derived data.
- Mentions target campaign entities only.

Rationale: Rendering needs JSON; backlinks/search need queryable rows.

## 9. Explicit Relationships

Decision: Use one generic `entity_relationships` table.

- Relationships connect `campaign_entities`.
- Relationship visibility is stored on the relationship.
- Structural links are not duplicated into this table.

Rationale: A generic relationship table fits backlinks, context panels, and arbitrary cross-entity links.

## 10. Relationship Types

Decision: Use database-driven `relationship_types`.

- System defaults are global rows with `campaign_id null`.
- Future custom types are campaign-scoped.
- Include `is_system`.

Rationale: Supports fixed MVP defaults while allowing campaign-specific labels later.

## 11. Structural Links

Decision: Store hierarchy and core structural links as typed columns.

Examples:

- location parent
- quest parent
- faction parent
- encounter related session
- timeline event related session

Decision: Create a read-only related-records view that unions explicit relationships with structural links.

Rationale: Typed columns are better source of truth; the UI still gets one related-record surface.

## 12. Entity Types

Decision: Use an `entity_types` lookup table.

- `campaign_entities.entity_type_id` references it.
- Seed system entity types.
- Include labels, sort order, icon key, default visibility, `is_system`, and active state.

Rationale: Aligns with the preference for database-driven configuration.

## 13. Statuses

Decision: Use database-driven `status_definitions`.

- Entity statuses are scoped by entity type.
- Campaign and resource statuses are also stored in `status_definitions` using a non-entity subject key.
- MVP seeds system defaults.
- Typed records, campaigns, and resources reference `status_id`.

Rationale: Allows labels/order/colors/future customization without enum migrations.

## 14. Open Options

Decision: Use generalized `entity_option_definitions`.

Use for:

- location types
- timeline event types
- encounter types
- quest priority/importance

Rules:

- Global system defaults have `campaign_id null`.
- Campaign custom options have `campaign_id`.

Rationale: Avoids many small lookup tables while preserving DB-driven options.

## 15. Configuration UI Timing

Decision: MVP customization UI is only required for currencies.

- Other config tables are seeded/default-driven.
- Custom status/relationship/section/option UIs are deferred.

Rationale: Currency values are campaign-specific immediately; the rest can wait.

## 16. Roles

Decision: Normalize campaign roles.

- Use `role_definitions`.
- Use `campaign_membership_roles`.
- Users can hold multiple roles in one campaign.

Rationale: Supports owner, GM, player, and future roles cleanly.

## 17. Ownership

Decision: Store campaign ownership both directly and as a role.

- `campaigns.owner_user_id` is canonical.
- Owner role membership is also assigned.

Rationale: Direct owner lookup is useful for RLS and workflows; role membership is useful for UI and permissions.

## 18. Invitations

Decision: Invitations include email and claim lifecycle fields.

- Store normalized email.
- Store inviter.
- Store status/timestamps.
- Store nullable `accepted_by_user_id`.
- Prevent duplicate active invite per campaign/email.

Rationale: Clear lifecycle and safer acceptance flow.

## 19. Media

Decision: Use both primary image columns and generic media links.

- `media_assets` stores metadata.
- Campaigns, characters, NPCs, and locations can have primary image fields.
- `media_asset_links` supports broader/future attachments.

Rationale: Primary images need fast dense-list access; generic links preserve flexibility.

## 20. Funds And Resources

Decision: Funds and resources are generic across owner entities.

- Initial owners are parties and characters.
- Funds use `entity_fund_balances`.
- Resources use `entity_resources`.

Decision: Funds are owner-only.

- No holder/custodian field for numeric fund balances in MVP.

Decision: Resources have holder support.

- `owner_entity_id` is who owns/controls it.
- `holder_entity_id` is who physically has it.
- Party-owned item held by a character is supported.

Decision: Resource value is simple.

- `value_amount` is numeric.
- It is always campaign standard-currency equivalent.

Rationale: Supports current campaign use cases without building full inventory/accounting.

## 21. Currencies

Decision: Use campaign currency definitions.

- `campaign_currency_definitions` stores currency key, label, standard conversion value, sort order, and active state.
- New campaigns auto-seed D&D-friendly defaults in MVP.
- Gold is the standard in the default set.
- Later campaign creation can support presets/no-currency mode.

Rationale: Currency is campaign-specific and immediately needs customization.

## 22. Session Attendance

Decision: Track attending users and attending characters separately.

- Use `session_attending_users`.
- Use `session_attending_characters`.

Rationale: Player attendance and character participation are different facts.

## 23. Summaries

Decision: Use `campaign_entity_summaries` for app-state hydration.

- Start as a database view.
- Wrap in RPC later only if RLS/visibility logic requires it.
- Include practical summary fields, not just caption.

Rationale: Command palette and quick-open can search client-side over hundreds of campaign summaries.

## 24. Deep Search

Decision: Defer deep/full-text/semantic search design.

Current requirements:

- Keep `body_text`.
- Keep structured fields.
- Keep mention rows.

Rationale: Quick entity search does not need database search yet; semantic search deserves its own milestone.

## 25. RLS And Player-Facing Reads

Decision: Use safe views/RPCs for player-facing or mixed-visibility reads.

- GM-private long-form content lives in protected section rows.
- Some structured GM-only fields may stay in typed tables as documented exceptions.
- NPC `real_status_id` is allowed on `npcs`, but player-facing NPC reads must omit it.

Rationale: Supabase RLS is row-level, not column-level. Views/RPCs reduce accidental exposure while keeping the schema pragmatic.

## 26. Data Access Style

Decision: Use a hybrid API approach.

Direct calls are allowed for:

- simple reads
- summary views
- simple single-row edits where RLS is enough

RPCs are required for:

- typed entity creation
- multi-row workflows
- rich text saves
- optimistic concurrency checks
- mention extraction
- invitation acceptance
- soft delete / restore / empty trash
- privileged or side-effect-heavy operations

Rationale: RPC-heavy design is not inherently cheaper. Hybrid keeps development fast while centralizing complex workflows.

## 27. Entity Creation

Decision: Typed entity creation uses RPCs/transactions.

Create RPCs create:

1. `campaign_entities`
2. typed row
3. default sections

Rationale: Prevents partial creation and keeps defaults consistent.

## 28. Soft Delete

Decision: Soft delete by default.

- Mark `campaign_entities.deleted_at`.
- Keep dependents intact for restore.
- Normal views hide deleted entities.
- Campaign owner can "empty trash" to hard-delete and cascade.

Rationale: Preserves tabs, pins, backlinks, and recovery until explicit cleanup.

## 29. Audit Fields

Decision: All user-editable tables get audit fields where practical.

Use:

- `created_by`
- `updated_by`
- `created_at`
- `updated_at`

Join tables may only need:

- `created_by`
- `created_at`

Rationale: Useful for debugging, future audit history, and player/GM contribution clarity.

## 30. JSONB Use

Decision: Use JSONB selectively.

Good uses:

- rich text JSON
- NPC stat blocks
- future system-specific fields
- low-query flexible metadata

Avoid JSONB for:

- status
- visibility
- ownership
- campaign id
- parent ids
- relationship targets
- dates/sort keys
- filterable fields

Rationale: Keep core app behavior structured and queryable.
