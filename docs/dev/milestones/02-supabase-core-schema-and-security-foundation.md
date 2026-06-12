# 02. Supabase Core Schema And Security Foundation

## Purpose

Create the local Supabase foundation for Yife's campaign data model and security boundary.

This milestone should establish the first real database schema, seed system defaults, generate TypeScript database types, and prove that campaign membership is the primary access boundary through RLS smoke tests.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/dev/specs/yife-media-image-storage-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`

## Goals

- Add Supabase local development configuration.
- Create migrations for core users, campaigns, memberships, roles, invitations, entity registry/config tables, statuses, options, relationship types, media metadata shell, and currency definitions.
- Seed required system defaults only.
- Add helper SQL functions for membership/role checks.
- Enable RLS on all user/campaign data tables created in this milestone.
- Add the first safe read surfaces for campaign lists and entity summaries.
- Add RPCs for user default initialization, campaign creation, and owner membership setup.
- Add local Supabase smoke tests for RLS, seed data, helper functions, and campaign creation.
- Generate `supabase/types/database.types.ts`.

## Non-Goals

- No full typed entity detail tables beyond the minimum needed for registry validation unless needed by constraints.
- No note/section/rich text tables yet.
- No `entity_sections` content rows yet.
- No Tiptap integration.
- No real image upload.
- No UI integration beyond making generated types importable later.
- No remote Supabase project setup unless explicitly pulled forward.
- No custom status/relationship/option management UI.

## Assumptions

- Supabase CLI is available locally or can be installed by Andrew.
- Local schema work happens before remote project work.
- System seed data should be deterministic and migration-backed.
- RLS policies should be simple but real, not placeholders.
- The first schema may evolve; this milestone favors clear constraints over premature optimization.

## Schema Scope

Create migrations for these groups.

### User And Campaign Core

- `user_profiles`
- `user_settings`
- `campaigns`
- `role_definitions`
- `campaign_memberships`
- `campaign_membership_roles`
- `campaign_invitations`
- `campaign_invitation_roles`

### Entity Registry And Configuration

- `entity_types`
- `campaign_entity_type_settings`
- `campaign_entities`
- `entity_section_definitions`

Defer `entity_aliases` to the later entity baseline milestone. Aliases are useful, but this milestone should avoid adding player-editable entity-adjacent data before entity create/update workflows exist.

### System Definitions

- `status_definitions`
- `entity_option_definitions`
- `relationship_types`

### Campaign Defaults

- `campaign_currency_definitions`

### Media Metadata Shell

- `media_assets`
- `media_asset_variants`

Defer `media_asset_links` until media attachments, notes, or sections exist.

`media_assets` must store logical asset metadata. `media_asset_variants` must store generated file bucket/path metadata for `thumb_160` and `grid_480`. Do not persist public URLs; derive URLs in the app from bucket/path. This milestone does not implement uploads, but the schema must match the media spec's asset/variant split so future summary views can render primary images without schema churn.

### Workspace Shell Tables

Defer workspace/layout tables unless implementation pressure shows they are needed for early campaign switching. They are not required to prove the first security boundary.

## Implementation Steps

### 1. Add Supabase Project Structure

- Add `supabase/config.toml`.
- Add `supabase/migrations/`.
- Add `supabase/seed.sql` only if it fits Supabase local workflow better than seed migrations; prefer migrations for deterministic system defaults.
- Add `supabase/tests/` or `scripts/supabase/` for smoke tests.
- Add root scripts:
  - `supabase:start`
  - `supabase:stop`
  - `supabase:reset`
  - `db:types`
  - `db:test`
- Implement `db:test` as a plain SQL smoke-test runner against the local Supabase database using `psql` or `supabase db query`. Do not add pgTAP or a TypeScript test runner unless the plain SQL approach proves inadequate.
- Implement `db:types` with local Supabase type generation into `supabase/types/database.types.ts`.

### 2. Define Shared SQL Conventions

- Use `uuid` primary keys where appropriate.
- Use `timestamptz` for timestamps.
- Store timestamps in UTC.
- Add `created_at` and `updated_at` defaults.
- Add `created_by` and `updated_by` where practical for user-editable rows.
- Use `deleted_at` only where soft delete is required in current scope.
- Use check constraints for stable value sets such as visibility keys and invitation statuses where lookup tables are not warranted.
- Avoid PostgreSQL enums for app taxonomies that requirements expect to remain database-driven.
- Add deterministic unique constraints for system/default lookup rows, including role keys, entity type keys, section definition keys per entity type, status keys per subject/entity type/campaign scope, option keys per group/entity type/campaign scope, relationship type keys per campaign scope, and currency keys per campaign.
- Treat `campaign_id is null` system/default config rows as app-immutable. App users may read needed system rows, but must not insert, update, or delete them through normal client roles.

### 3. Create Role And Membership Foundation

- Seed role definitions:
  - `owner`
  - `game_master`
  - `player`
- Add memberships with active/removed-style lifecycle.
- Add membership-role join table.
- Add constraints to prevent duplicate active memberships for one user/campaign.
- Store canonical campaign ownership on `campaigns.owner_user_id`.
- Ensure campaign owners also receive owner role membership through creation RPC.
- Preserve owner invariants:
  - The canonical owner must keep an active membership.
  - The canonical owner must keep owner role membership.
  - Direct writes must not remove/demote the canonical owner.
- Prefer RPC-only membership/role changes. If direct writes are allowed for simple cases, add constraints, triggers, or policies that still preserve owner invariants.

### 4. Add Helper Functions

Add stable helper functions for RLS and RPC use.

Minimum helpers:

- `current_user_id()`
- `is_campaign_member(campaign_id uuid)`
- `is_campaign_owner(campaign_id uuid)`
- `has_campaign_role(campaign_id uuid, role_key text)`
- `is_campaign_gm(campaign_id uuid)`
- `normalize_email(email text)`

Rules:

- Helpers must not accidentally bypass RLS for caller-visible queries.
- Membership and role helpers used inside RLS policies should be boolean-only functions. They may use `security definer` where needed to avoid recursive policy failures, but must return only yes/no decisions rather than caller-visible rows.
- Any `security definer` helper must set a safe `search_path`, be owned by an appropriate privileged database role, and avoid dynamic SQL.
- Helper predicates must count only active memberships and active role assignments.
- Keep helpers focused and testable.

### 5. Add Core RLS Policies

Enable RLS on every user/campaign table created.

Policy intent:

- Users can read and update their own profile/settings.
- Active co-members can read a minimal safe profile surface for display names and avatars only.
- `user_settings` remains owner-only.
- Active campaign members can read campaign rows they belong to.
- Campaign owners can manage campaign settings and memberships.
- Owners and Game Masters can edit campaign-wide settings in MVP unless a setting is explicitly owner-only.
- Game Masters can read GM-allowed campaign management surfaces where the requirements allow it.
- Only active memberships count for access.
- Removed users lose access to campaign data.
- Invitations are visible/manageable only to campaign owners/GMs and to matching invitees where safe.
- Raw campaign-scoped `media_assets` and `media_asset_variants` metadata must not be broadly selectable by all players. Player-facing media metadata should come through safe campaign/entity summary surfaces for visible records.
- Nullable `campaign_id` config tables must be RLS-protected:
  - system rows with `campaign_id is null` are readable where needed
  - system rows with `campaign_id is null` are not mutable by normal app users
  - campaign-scoped rows are readable only by active campaign members
  - campaign-scoped rows are mutable only by owners/GMs where the feature allows customization
  - campaign-scoped uniqueness must prevent duplicate active/default keys within the same campaign scope

The first pass may be conservative. Do not expose data just to simplify UI.

### 6. Add Entity Registry And System Defaults

- Create `entity_types`.
- Seed system entity types:
  - `character`
  - `npc`
  - `party`
  - `faction`
  - `location`
  - `quest`
  - `session`
  - `plot_arc`
  - `encounter`
  - `timeline_event`
- Create `campaign_entity_type_settings`.
- Create `campaign_entities`.
- Create `entity_section_definitions`.
- Apply soft delete columns to `campaign_entities`.
- Ensure normal summary reads exclude deleted entities.
- Seed default section definitions per entity type, but do not create `entity_sections` content rows yet.
- Every seeded `entity_section_definitions` row must include stable `section_key`, `label`, `default_visibility`, `default_edit_policy`, `default_content_mode`, `sort_order`, `is_system`, and `is_active` values.
- Seed at least the section definitions already named in the content model spec:
  - NPC: `player_summary`, `gm_details`, `player_observations`
  - Quest: `player_summary`, `gm_details`, `player_observations`
  - Session: `summary`, `gm_prep`, `gm_private_notes`
- Seed status definitions for campaign and entity/resource statuses.
- Seed option definitions for location types, timeline event types, encounter types, and quest priority.
- Seed relationship types.

### 7. Add User Defaults RPC

Create an idempotent RPC such as `ensure_user_defaults`.

Rules:

- The RPC must require an authenticated caller.
- The RPC must derive `user_id` from `auth.uid()`/`current_user_id()`.
- The RPC must ignore or reject caller-supplied user ids.
- The RPC must create missing `user_profiles` and `user_settings` rows for the caller.
- Existing profile/settings rows must not be overwritten except for filling safe missing defaults.
- Default profile/settings values should be minimal and match milestone 03 needs:
  - display name from email prefix if safely available, otherwise empty/editable
  - default theme preference
  - default landing behavior
  - no campaign layout state
- The RPC should return the ensured profile/settings identifiers or rows in a shape usable by auth composables.

### 8. Add Campaign Creation RPC

Create an RPC such as `create_campaign`.

Identity and permission rules:

- The RPC must require an authenticated caller.
- The RPC must derive creator, owner, `created_by`, and owner membership user ids from `auth.uid()`/`current_user_id()`.
- The RPC must ignore or reject any caller-supplied owner/user id fields.
- The RPC must not allow creating a campaign owned by another user.

It should transactionally:

1. Create the campaign.
2. Create or ensure the creator's user profile/settings if needed.
3. Create active owner membership.
4. Assign owner role.
5. Seed `campaign_entity_type_settings` from system entity types.
6. Seed D&D-friendly `campaign_currency_definitions` with gold as the standard currency.
7. Return created campaign data in a shape usable by the app.

The RPC should validate required campaign fields, reject invalid status/currency defaults, and reject invalid date ranges. If no campaign status is supplied, default to the seeded `planned` campaign status.

### 9. Add Safe Read Surfaces

Add initial views or RPCs for:

- current user's campaign list
- campaign membership/role summary
- campaign entity summaries
- safe member profile display

Rules:

- Any Postgres view used as a safe read surface must be created with `security_invoker = true`, or the read surface must be implemented as an RLS-gated RPC.
- Every safe read surface must have tests for active member, non-member, and removed-member behavior.
- The current user's campaign-list surface must be sufficient for milestone 03 campaign cards without ad hoc client joins. Include at least:
  - `campaign_id`
  - `name`
  - `description`
  - `status_key`
  - `status_label`
  - `membership_status`
  - `role_keys`
  - primary campaign image fields when visible/ready
  - `updated_at`
- Campaign-list reads must not expose pending invitations, other members' emails, hidden entity data, raw media filenames, or unassigned/failed media rows.
- The safe member profile display surface should include only `user_id`, display name, display-name override where relevant, and safe avatar display metadata if avatars are in schema. It must not expose `user_settings` or auth email.
- Entity summaries must not leak hidden record existence or labels.
- Summary visibility rules:
  - `shared` records are visible to active campaign members.
  - `gm_only` records are visible only to owners and Game Masters.
  - `private` records are visible only to the creator/author.
  - soft-deleted records are excluded from normal summary reads.

The entity summary view may be sparse until typed entity tables exist, but it should establish the eventual shape:

- `campaign_id`
- `entity_id`
- `entity_type_key`
- `list_caption`
- `default_visibility`
- `status_key`
- `status_label`
- `primary_image_asset_id`
- `primary_image_alt_text`
- `primary_image_thumb_bucket`
- `primary_image_thumb_path`
- `primary_image_thumb_width`
- `primary_image_thumb_height`
- `primary_image_grid_bucket`
- `primary_image_grid_path`
- `primary_image_grid_width`
- `primary_image_grid_height`
- `primary_image_is_decorative`
- `relevant_date`
- `parent_entity_id`
- `related_session_entity_id`
- `updated_at`
- `deleted_at`

### 10. Add Invitation Table Constraints

- Add invitation status lifecycle columns.
- Store normalized email.
- Prevent duplicate active invitations for the same campaign/email.
- Add constraints for status, expiry, normalized email, and assigned roles.
- Seed no invitation rows.
- Defer full invitation acceptance behavior to the later invitation milestone.
- Lock the future `accept_campaign_invitation` contract now: it must transactionally validate invite status, expiry, normalized email claim, campaign id, and assigned roles before creating membership and roles.

### 11. Add Type Generation

- Configure type generation into `supabase/types/database.types.ts`.
- Add app import wrapper or alias only if the app scaffold already exists.
- Ensure generated types are committed.
- Add a short README or script comment explaining how to regenerate types after migrations.

### 12. Add Supabase Smoke Tests

Add tests that can run locally after `supabase start/reset`.

Minimum coverage:

- System roles are seeded.
- System entity types are seeded.
- System statuses/options/relationship types are seeded.
- System/default config rows have deterministic unique constraints and are not mutable by normal app users.
- Campaign-scoped config rows in nullable `campaign_id` tables are hidden from non-members.
- `ensure_user_defaults` creates missing profile/settings rows for the authenticated caller, is idempotent, rejects unauthenticated callers, and cannot create or overwrite another user's defaults.
- `create_campaign` creates campaign, owner membership, owner role, entity type settings, and currency defaults.
- `create_campaign` rejects unauthenticated callers and cannot be used to create a campaign owned by another user.
- `create_campaign` defaults missing status to `planned` and rejects invalid date ranges.
- Campaign owner can read their campaign.
- Canonical owner cannot be removed, demoted, or left without owner membership/role.
- Non-member cannot read another user's campaign.
- Removed member cannot read campaign data.
- Membership/role helpers return correct boolean results for active members, non-members, removed members, owners, GMs, and players.
- GM role helper returns true only for active GM members.
- Player cannot read GM-only or private entity summary labels/existence.
- Owner/GM can read GM-only entity summaries.
- Creator can read their own private entity summaries.
- Safe read surfaces use `security_invoker = true` views or RLS-gated RPCs.
- Campaign-list reads include role/status/card fields needed by milestone 03 without leaking invitations, member emails, hidden entity data, or raw media metadata.
- Active co-member can read only safe profile display fields, not user settings.
- Players cannot directly read raw campaign media metadata outside safe visible summary surfaces.
- Duplicate active invitation is rejected.
- Entity summaries exclude soft-deleted entities.
- Ready media assets require active `thumb_160` and `grid_480` variant metadata.

Use plain SQL smoke tests against the local Supabase database first. Prefer no new test framework dependency for this milestone.

### 13. Verify Locally

Run:

```sh
pnpm supabase:start
pnpm supabase:reset
pnpm db:test
pnpm db:types
pnpm typecheck
```

If Supabase cannot run locally, document the exact blocker and do not claim the milestone is complete.

## Manual Steps Required From Andrew

- Install or update the Supabase CLI if it is not available locally.
- Ensure Docker is running for Supabase local development.
- Confirm any owner-only campaign settings exceptions if they differ from the settled MVP rule that owners and Game Masters can edit campaign-wide settings.

## Success Criteria

- Supabase local development starts and resets cleanly.
- Migrations apply from an empty database without manual intervention.
- Required system defaults are migration-backed and deterministic.
- System/default lookup rows have uniqueness constraints and cannot be mutated through normal app roles.
- RLS is enabled on all created user/campaign tables.
- RLS is enabled on config tables that can contain campaign-scoped rows.
- Campaign membership is proven as the primary access boundary by tests.
- Entity summary visibility is proven for player, GM, owner, creator-private, non-member, removed-member, and soft-deleted cases.
- Owner membership/role invariants are enforced and tested.
- `create_campaign` works transactionally, derives ownership from the authenticated caller, rejects unauthenticated use, and creates required defaults.
- `ensure_user_defaults` works idempotently and is ready for milestone 03 auth composables.
- Safe campaign-list and membership-summary surfaces expose the fields needed by milestone 03.
- Duplicate active invitations are prevented.
- Invitation acceptance is explicitly deferred, but the future transactional contract and schema constraints are documented in the migration comments or developer docs.
- Generated database types exist at `supabase/types/database.types.ts`.
- `db:test` passes locally.
- The app can import generated database types without path hacks.

## What Good Looks Like

- A future feature can trust that campaigns, ownership, membership, roles, entity types, statuses, options, relationship types, and currencies exist.
- Security rules are conservative and test-backed.
- Database defaults are clear enough for AI agents to extend without inventing parallel taxonomies.
- There is still no ORM or custom backend API.
- The schema is broad enough to support the first app workflow, but not bloated with unimplemented rich-text/workbench complexity.

## Implementation Defaults Locked For This Milestone

- Defer `entity_aliases` to entity baseline work.
- Defer `media_asset_links` until media attachments, notes, or sections exist.
- Use plain SQL smoke tests for `db:test`; add pgTAP or a script runner later only if SQL tests become too awkward.

## Adversarial Review Notes

Reviewed by subagent after initial draft. Valid corrections incorporated:

- Required `security_invoker = true` views or RLS-gated RPCs for safe read surfaces.
- Added entity summary visibility rules and player/GM/owner/private tests.
- Added canonical owner membership/role invariants.
- Added an idempotent `ensure_user_defaults` RPC requirement for milestone 03 auth/profile initialization.
- Tightened `create_campaign` so ownership and audit user ids are derived from the authenticated caller.
- Required `create_campaign` to default missing campaign status to `planned` and reject invalid date ranges.
- Tightened RLS helper guidance for boolean-only membership predicates, safe `security definer` usage, and active-membership semantics.
- Added RLS requirements for nullable `campaign_id` config tables.
- Added immutability and uniqueness requirements for system/default config rows.
- Added safe co-member profile display scope while keeping settings owner-only.
- Added safe campaign-list output requirements needed by milestone 03.
- Added raw media metadata RLS/read-surface constraints.
- Clarified media metadata uses the current asset/variant split and stores bucket/path only, not persisted public URLs.
- Added `entity_section_definitions` seeding without creating section content rows.
- Required stable section definition keys and default visibility/edit/content-mode fields for seeded definitions.
- Locked remaining implementation defaults for aliases, media links, and SQL smoke tests.
- Explicitly deferred invitation acceptance to a later invitation milestone while locking the future RPC contract.
