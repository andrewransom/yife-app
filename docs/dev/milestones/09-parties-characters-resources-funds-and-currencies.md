# 09. Parties, Characters, Resources, Funds, And Currencies

## Purpose

Implement the MVP party-management layer without turning Yife into an inventory or accounting system.

This milestone should make characters, parties, party membership, campaign currencies, simple funds, and simple resources useful for campaign knowledge management while preserving the system-agnostic, D&D-friendly default model.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/06-role-aware-visibility-and-player-gm-views.md`
- `docs/dev/milestones/07-relationships-timeline-and-context-panels.md`

## Goals

- Add character assignment and character management surfaces.
- Add party membership workflow.
- Add party and character-owned fund balances.
- Add party and character-owned resources with optional holder.
- Add campaign currency customization UI.
- Add player and GM views for parties, assigned characters, resources, and funds.
- Add safe query/mutation composables and RLS/RPC tests.
- Keep funds/resources lightweight and non-accounting.

## Non-Goals

- No full inventory system.
- No item rarity/rules automation.
- No encumbrance.
- No transaction ledger or audit history for funds.
- No holder/custodian history for funds.
- No resource note attachments beyond simple `description_text`.
- No currency presets/no-currency campaign creation choices.
- No custom non-currency option-list UI.
- No marketplace/economy tooling.

## Assumptions

- M04 created characters and parties as campaign entities.
- Campaign creation already seeds D&D-friendly currencies with gold as standard.
- `campaign_currency_definitions` exists from M02.
- M09 may need to add `party_members`, `entity_fund_balances`, and `entity_resources` if they were deferred.
- Owner/GM can manage party structure and currency settings in MVP.
- Players can view player-visible party/resource/fund data and manage assigned character details where permitted.

## Implementation Steps

### 1. Confirm Character Assignment Rules

Ensure `characters.controlling_user_id`:

- references an active campaign member
- is required for character creation/update
- can be changed by owners/GMs
- is visible through safe character detail and summary reads

Rules:

- Users are not campaign entities.
- A player can own/control multiple characters.
- Temporary session handling of an absent player's character does not change ownership.
- Player character management permissions must come from safe read capability flags and mutation RPC checks, not UI-only logic.
- Removing a member should not automatically delete assigned characters; later membership screens should surface reassignment needs.

### 2. Add Party Membership

Create or confirm `party_members`:

- `party_entity_id`
- `character_entity_id`
- `role_label`
- `sort_order`
- audit fields

Rules:

- Party and character entities must be in the same campaign.
- Party entity must have type `party`.
- Character entity must have type `character`.
- A character may be in zero, one, or multiple parties.
- Duplicate active party membership rows are prevented.
- Owners/GMs can manage party membership.
- Players can view visible party membership.
- Player party membership edits are deferred unless explicitly enabled later.

### 3. Add Fund Balances

Create or confirm `entity_fund_balances`:

- `id`
- `campaign_id`
- `owner_entity_id`
- `currency_definition_id`
- `quantity`
- audit fields

Rules:

- Allowed owner entity types are party and character.
- Owner entity and currency definition must belong to the same campaign.
- Unique constraint on `(owner_entity_id, currency_definition_id)`.
- Quantities can be zero or positive; negative balances are rejected for MVP unless Andrew explicitly wants debt tracking.
- Funds are owner-only balances.
- Funds do not store holder/custodian history.
- Calculated total standard-currency value is client-side using currency definitions.
- Substantial fund notes or transaction history are post-MVP.

### 4. Add Resources

Create or confirm `entity_resources`:

- `id`
- `campaign_id`
- `owner_entity_id`
- `holder_entity_id`
- `name`
- `description_text`
- `status_id`
- `quantity`
- `value_amount`
- `sort_order`
- audit fields

Rules:

- Allowed owner entity types are party and character.
- Holder is optional and must be a same-campaign party or character when present.
- A party-owned resource held by a character is allowed.
- `value_amount` is the campaign standard-currency equivalent.
- `description_text` stays simple.
- Resources use resource status definitions.
- Do not add rich text notes or attachments for resources in MVP.

### 5. Add Currency Customization

Build campaign settings UI for `campaign_currency_definitions`.

Capabilities:

- list currencies
- add currency
- edit key, label, value in standard, sort order, active state
- choose standard currency
- deactivate currency where safe
- restore default D&D values only if simple

Rules:

- Default currency keys are `cp`, `sp`, `ep`, `gp`, `pp`.
- Gold is the default standard currency.
- Exactly one active standard currency should exist per campaign.
- The active standard currency must have `value_in_standard = 1`.
- The current standard currency cannot be deactivated until another active currency is made standard in the same mutation.
- Currency keys are stable identifiers and should not be casually changed if balances already exist.
- Deactivating a currency with balances should either be blocked or require confirmation and preserve existing balance rows.
- Deleting currency definitions is not required; use inactive state.
- Owners/GMs can customize currencies in MVP.
- Players can read currency labels needed to understand visible funds/resources.

### 6. Add Party Detail Enhancements

Party detail should show:

- party name and visible sections
- member characters
- party notes
- party resources
- party funds
- related quests/sessions/locations/NPCs through related records

Rules:

- Parties are player-visible unless record visibility says otherwise.
- Party funds/resources are visible to players and GMs unless hidden by owner entity visibility or future row-level visibility rules.
- MVP funds/resources do not add per-row visibility because the current content model does not define it.
- Funds/resources inherit owner entity visibility; sensitive details belong in GM-only sections/notes unless a later schema update adds row-level visibility.
- Keep layout dense and scannable.
- Missing/removed character references render placeholders.

### 7. Add Character Detail Enhancements

Character detail should show:

- name
- controlling user safe display
- status
- visible sections/backstory
- party memberships
- character-owned resources
- character-owned funds
- related sessions/quests/relationships

Rules:

- Players can view characters in campaigns they belong to.
- Players can manage their assigned characters only where capability flags permit it.
- Owners/GMs can manage campaign characters.
- Character image slots remain placeholder until M10.

### 8. Add Funds And Resources UI

Build reusable components:

- funds table/list by owner
- fund balance editor
- resource list
- resource editor
- owner/holder picker
- currency display formatter
- standard-value total display

Rules:

- Use compact rows and stable dimensions.
- Use safe entity pickers restricted to party/character owner types.
- Show empty/loading/error states.
- Validate numeric values with Zod/VeeValidate.
- Do not add ledger-style history.
- Do not use TanStack Table unless the funds/resource UI needs real table behavior.

### 9. Add Query And Mutation Composables

Expected query composables:

- `useCharacterDetailQuery`
- `usePartyDetailQuery`
- `usePartyMembersQuery`
- `useEntityFundBalancesQuery`
- `useEntityResourcesQuery`
- `useCampaignCurrencyDefinitionsQuery`

Expected mutation composables:

- `useUpdateCharacterAssignmentMutation`
- `useUpdatePartyMembersMutation`
- `useUpdateFundBalanceMutation`
- `useCreateResourceMutation`
- `useUpdateResourceMutation`
- `useDeleteResourceMutation`
- `useUpdateCurrencyDefinitionsMutation`

Rules:

- Components do not call Supabase directly.
- Mutations touching multiple rows use RPCs.
- Currency customization should use an RPC if standard-currency invariants or active/deactivate rules span multiple rows.
- Mutations invalidate summaries, detail, party, resource, fund, currency, and activity caches where relevant.

### 10. Add Tests

Database/RLS/RPC tests:

- character controller must be active campaign member
- non-members cannot read party/fund/resource data
- party member rows reject cross-campaign characters
- duplicate party membership is prevented
- funds reject owner types outside party/character
- funds reject cross-campaign currency references
- funds enforce unique owner/currency row
- funds/resources inherit owner visibility; no per-row visibility control is exposed in M09
- resources reject cross-campaign owner/holder
- resource holder must be party/character if present
- exactly one active standard currency is enforced
- deactivating currencies with balances follows chosen block/confirm rule

Unit/component tests:

- currency formatter uses standard definitions correctly
- fund total calculation is client-side and deterministic
- party member list renders placeholders for inaccessible characters
- resource editor validates owner/holder/value/quantity
- character detail shows controlling user safe display data

Playwright smoke tests:

- create party and character
- assign character to party
- add party fund balances
- add party resource held by character
- customize a currency label/value
- verify player can see visible party/fund/resource data
- verify non-member cannot access data

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

Document any manual checks for currency customization or party workflows.

## Manual Steps Required From Andrew

- Review the explicit M09 compromise that funds/resources inherit owner visibility rather than having per-row visibility controls.
- Review whether deactivating currencies with balances should block or require confirmation.
- Verify party/resource UI with a realistic party and multiple characters.

## Success Criteria

- Characters have active campaign-member controllers.
- Parties can contain multiple characters, and characters can belong to multiple parties.
- Party/character fund balances work with campaign currency definitions.
- Resources support owner plus optional holder.
- Currency customization is available in campaign settings.
- Player and GM views respect campaign membership and visibility.
- Components use Yife composables, not direct Supabase calls.
- Tests cover same-campaign constraints, owner type constraints, currency invariants, and browser workflows.

## What Good Looks Like

- A party page gives players and GMs a compact shared view of members, money, and important resources.
- A character page connects the player, party membership, resources, and related campaign context.
- The app supports common D&D-style currency needs without becoming bookkeeping software.

## Resolved Decisions

- Characters can belong to zero, one, or multiple parties.
- Funds are simple balances by owner and currency, with no ledger.
- Resources have owner plus optional holder.
- Resource value is stored as standard-currency equivalent.
- D&D default currencies are seeded, with gold as standard.
- Currency customization UI is MVP; preset/no-currency campaign creation options are deferred.
- Funds/resources inherit owner entity visibility in MVP; per-row hidden resources/funds are deferred unless the content model is revised.

## Decision Log

Currency deactivation with balances:

- Option 1: block deactivation while balances exist.
- Option 2: allow deactivation after confirmation and preserve existing balances.
- Decision: prefer option 1 for MVP implementation simplicity. If Andrew wants inactive-but-retained historical balances visible, promote option 2 before implementation.

Funds/resources visibility:

- Option 1: add per-row visibility to funds and resources now.
- Option 2: follow the current content model and inherit owner entity visibility.
- Decision: choose option 2 for MVP plan alignment. Sensitive or GM-only details should live in protected notes/sections until a row-level visibility field is explicitly added.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Documented the funds/resources visibility compromise against the current content model.
- Added explicit guidance that sensitive resource/fund details belong in protected notes/sections unless row-level visibility is promoted.

Pass 2 corrections incorporated:

- Tightened currency invariants: standard currency has `value_in_standard = 1`, and deactivation cannot leave a campaign without an active standard currency.
- Added tests for inherited owner visibility and currency standard invariants.
