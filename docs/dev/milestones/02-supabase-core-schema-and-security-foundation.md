# 02. Supabase Core Schema And Security Foundation

## Purpose

Create the local Supabase foundation for Yife's campaign data model and security boundary.

This milestone should establish the first real database schema, seed system defaults, generate TypeScript database types, and prove that campaign membership is the primary access boundary through RLS smoke tests.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`

## Goals

- Add Supabase local development configuration.
- Create migrations for core users, campaigns, memberships, roles, invitations, entity registry/config tables, statuses, options, relationship types, media metadata shell, and currency definitions.
- Seed required system defaults only.
- Add helper SQL functions for membership/role checks.
- Enable RLS on all user/campaign data tables created in this milestone.
- Add the first safe read surfaces for campaign lists and entity summaries.
- Add RPCs for campaign creation and owner membership setup.
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
- `entity_aliases` if low-cost; otherwise defer to the entity baseline milestone and document that deferral.

### System Definitions

- `status_definitions`
- `entity_option_definitions`
- `relationship_types`

### Campaign Defaults

- `campaign_currency_definitions`

### Media Metadata Shell

- `media_assets`

Only add `media_asset_links` in this milestone if it does not force unresolved note/section dependencies. Otherwise defer until media or notes exist.

`media_assets` must store bucket/path metadata only. Do not persist public URLs; derive URLs in the app from bucket/path. Include enough path fields or variant metadata shape to support future `thumb_160` and `grid_480` variants without changing the source-of-truth rule.

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

### 2. Define Shared SQL Conventions

- Use `uuid` primary keys where appropriate.
- Use `timestamptz` for timestamps.
- Store timestamps in UTC.
- Add `created_at` and `updated_at` defaults.
- Add `created_by` and `updated_by` where practical for user-editable rows.
- Use `deleted_at` only where soft delete is required in current scope.
- Use check constraints for stable value sets such as visibility keys and invitation statuses where lookup tables are not warranted.
- Avoid PostgreSQL enums for app taxonomies that requirements expect to remain database-driven.

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
- If using `security definer`, set a safe `search_path`.
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
- Nullable `campaign_id` config tables must be RLS-protected:
  - system rows with `campaign_id is null` are readable where needed
  - campaign-scoped rows are readable only by active campaign members
  - campaign-scoped rows are mutable only by owners/GMs where the feature allows customization

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
- Seed status definitions for campaign and entity/resource statuses.
- Seed option definitions for location types, timeline event types, encounter types, and quest priority.
- Seed relationship types.

### 7. Add Campaign Creation RPC

Create an RPC such as `create_campaign`.

It should transactionally:

1. Create the campaign.
2. Create or ensure the creator's user profile/settings if needed.
3. Create active owner membership.
4. Assign owner role.
5. Seed `campaign_entity_type_settings` from system entity types.
6. Seed D&D-friendly `campaign_currency_definitions` with gold as the standard currency.
7. Return created campaign data in a shape usable by the app.

The RPC should validate required campaign fields and reject invalid status/currency defaults.

### 8. Add Safe Read Surfaces

Add initial views or RPCs for:

- current user's campaign list
- campaign membership/role summary
- campaign entity summaries
- safe member profile display

Rules:

- Any Postgres view used as a safe read surface must be created with `security_invoker = true`, or the read surface must be implemented as an RLS-gated RPC.
- Every safe read surface must have tests for active member, non-member, and removed-member behavior.
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
- `relevant_date`
- `parent_entity_id`
- `related_session_entity_id`
- `updated_at`
- `deleted_at`

### 9. Add Invitation Table Constraints

- Add invitation status lifecycle columns.
- Store normalized email.
- Prevent duplicate active invitations for the same campaign/email.
- Add constraints for status, expiry, normalized email, and assigned roles.
- Seed no invitation rows.
- Defer full invitation acceptance behavior to the later invitation milestone.
- Lock the future `accept_campaign_invitation` contract now: it must transactionally validate invite status, expiry, normalized email claim, campaign id, and assigned roles before creating membership and roles.

### 10. Add Type Generation

- Configure type generation into `supabase/types/database.types.ts`.
- Add app import wrapper or alias only if the app scaffold already exists.
- Ensure generated types are committed.
- Add a short README or script comment explaining how to regenerate types after migrations.

### 11. Add Supabase Smoke Tests

Add tests that can run locally after `supabase start/reset`.

Minimum coverage:

- System roles are seeded.
- System entity types are seeded.
- System statuses/options/relationship types are seeded.
- Campaign-scoped config rows in nullable `campaign_id` tables are hidden from non-members.
- `create_campaign` creates campaign, owner membership, owner role, entity type settings, and currency defaults.
- Campaign owner can read their campaign.
- Canonical owner cannot be removed, demoted, or left without owner membership/role.
- Non-member cannot read another user's campaign.
- Removed member cannot read campaign data.
- GM role helper returns true only for active GM members.
- Player cannot read GM-only or private entity summary labels/existence.
- Owner/GM can read GM-only entity summaries.
- Creator can read their own private entity summaries.
- Safe read surfaces use `security_invoker = true` views or RLS-gated RPCs.
- Active co-member can read only safe profile display fields, not user settings.
- Duplicate active invitation is rejected.
- Entity summaries exclude soft-deleted entities.

Use SQL tests, pgTAP, or a small script against the local Supabase database. Prefer the simplest maintainable option.

### 12. Verify Locally

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
- RLS is enabled on all created user/campaign tables.
- RLS is enabled on config tables that can contain campaign-scoped rows.
- Campaign membership is proven as the primary access boundary by tests.
- Entity summary visibility is proven for player, GM, owner, creator-private, non-member, removed-member, and soft-deleted cases.
- Owner membership/role invariants are enforced and tested.
- `create_campaign` works transactionally and creates required defaults.
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

## Open Decisions

- Whether `entity_aliases` should be created with the registry foundation or deferred to entity UI work.
- Whether `media_asset_links` should wait until notes/sections exist.
- Whether Supabase tests should use pgTAP, SQL scripts, or a small TypeScript runner.

## Adversarial Review Notes

Reviewed by subagent after initial draft. Valid corrections incorporated:

- Required `security_invoker = true` views or RLS-gated RPCs for safe read surfaces.
- Added entity summary visibility rules and player/GM/owner/private tests.
- Added canonical owner membership/role invariants.
- Added RLS requirements for nullable `campaign_id` config tables.
- Added safe co-member profile display scope while keeping settings owner-only.
- Clarified media metadata stores bucket/path only, not persisted public URLs.
- Added `entity_section_definitions` seeding without creating section content rows.
- Explicitly deferred invitation acceptance to a later invitation milestone while locking the future RPC contract.
