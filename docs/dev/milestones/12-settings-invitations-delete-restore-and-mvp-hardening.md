# 12. Settings, Invitations, Delete/Restore, And MVP Hardening

## Purpose

Close the MVP product gaps and harden Yife for real campaign use.

This milestone should finish settings scope separation, campaign invitations, member management, soft delete/restore/empty trash, attention cues, mobile simplification, accessibility, browser coverage, and deployment readiness without adding post-MVP services or runtime vendors.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/dev/specs/yife-media-image-storage-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/03-auth-campaign-home-and-campaign-creation.md`
- `docs/dev/milestones/06-role-aware-visibility-and-player-gm-views.md`
- `docs/dev/milestones/10-media-and-image-workflow.md`
- `docs/dev/milestones/11-workbench-layouts-command-palette-and-shortcuts.md`

## Goals

- Build one coherent settings area with scoped sections.
- Implement user settings.
- Implement campaign settings.
- Implement campaign member settings/roster.
- Implement personal workspace/layout settings entry points.
- Implement campaign invitations and acceptance/decline/revocation.
- Implement membership removal and role updates within owner invariants.
- Implement soft delete, restore, and owner empty-trash flows.
- Add local in-app attention cues for important states.
- Add mobile simplified role-aware layout.
- Run accessibility, browser, and deployment-readiness hardening.
- Add final MVP smoke/e2e coverage.

## Non-Goals

- No custom transactional email provider.
- No product analytics.
- No external error monitoring.
- No feature flag service.
- No realtime collaboration.
- No offline/PWA.
- No private media.
- No import/export.
- No billing/payments.
- No CI unless explicitly promoted.
- No custom role taxonomy or custom permission matrix.

## Assumptions

- Earlier milestones implemented auth, campaign/entity workflows, notes, visibility, relationships, session workflows, media, and layouts.
- Supabase Auth built-in email remains the only email system in MVP.
- Route middleware remains UX; Supabase RLS/RPCs remain the security boundary.
- Settings must make scope obvious to users.
- Dangerous broad-impact actions require confirmation.

## Implementation Steps

### 1. Build Scoped Settings Area

Create one coherent settings area with sections/tabs:

- user settings
- campaign settings
- campaign members
- workspace/layout settings

Entry points:

- global user menu opens user settings
- campaign menu opens campaign settings
- member list opens campaign members
- layout/workbench controls open workspace settings

Rules:

- Users should not need to understand database scopes.
- Settings affecting all campaign members are labeled campaign-wide.
- Personal settings are labeled personal.
- Controls hide or disable based on permissions.
- Dangerous settings require confirmation.

### 2. Implement User Settings

User settings include:

- display name
- avatar display placeholder or existing avatar field, upload deferred unless promoted
- theme preference
- default landing behavior
- optional default campaign
- accessibility preferences where supported
- account/email management entry points through Supabase Auth where available

Rules:

- Users can edit only their own user settings.
- User settings do not store campaign-specific layout state.
- Theme changes persist and work in light/dark mode.
- Profile display uses safe profile surfaces in campaign membership UI.

### 3. Implement Campaign Settings

Campaign settings include:

- name
- description
- image
- start date
- end date
- status
- default visibility per entity type
- public media policy notice
- seeded option/relationship/status display where useful
- currency customization entry point from M09

Rules:

- Owners can edit campaign settings.
- GMs can edit non-membership campaign settings only if the existing RLS/RPC policy explicitly permits it.
- Membership security settings are owner-only in MVP.
- Player users can view only safe campaign settings needed for display.
- Image changes reuse M10 media workflow and warning.

### 4. Implement Campaign Member Settings

Member settings include:

- member roster
- role display
- membership status
- display name override where permitted
- assigned player characters
- invitation status where relevant

Rules:

- Owners manage invitations, role changes, membership removal, and revoked invites in MVP.
- GMs can view the roster and manage attendance/character assignment only where earlier feature RPCs permit it.
- The canonical owner cannot be removed, demoted, or left without active owner membership/role.
- Removed members immediately lose campaign data access through RLS.
- Member rows use safe profile display data only, not auth emails except where invitation management requires normalized invite email.

### 5. Implement Campaign Invitations

Add or complete RPCs:

- create invitation
- revoke invitation
- accept invitation
- decline invitation
- list invitations for owner
- list invitations for current user

Acceptance RPC must transactionally validate:

- authenticated caller
- invitation status
- expiration
- normalized email derived from the authenticated user's verified identity, not caller-supplied email
- campaign id
- assigned roles
- duplicate active membership/invite constraints

Rules:

- Duplicate active invitations to the same campaign/email are prevented.
- Invitation roles define roles assigned on acceptance.
- Invitations may assign `player` and/or `game_master`; they must not assign `owner`.
- Accepted invitation creates membership and roles in one transaction.
- Declined/revoked/expired invitations cannot be accepted.
- Invitations must not expose private campaign details unnecessarily.
- Use Supabase Auth/built-in email only; no Resend/custom provider.
- If automatic invitation email is not implemented, provide a clear copyable invite flow and document the limitation.

### 6. Implement Soft Delete And Restore

Add RPCs:

- soft delete entity
- restore entity
- empty trash

Soft delete:

- marks `campaign_entities.deleted_at`
- preserves typed details, sections, notes, relationships, mentions, resources, layout references, and pins
- hides records from normal lists/search/pickers

Restore:

- clears `deleted_at` where permitted
- restores record visibility according to existing visibility fields
- invalidates summaries, details, related records, command palette, layouts, and activity

Empty trash:

- owner-only
- requires confirmation
- hard-deletes soft-deleted entities and cascades dependent data where appropriate
- must not hard-delete records outside the campaign
- media Storage object cleanup remains best effort and follows the M10 cleanup script; empty trash must not depend on Storage deletion succeeding

Rules:

- Lifecycle does not override visibility.
- GM-only archived/deleted records remain GM-only.
- Soft-deleted references render placeholders.
- Users with restore permission see restore actions in trash/placeholder contexts.

### 7. Add Trash And Lifecycle UI

Add:

- trash view
- restore action
- empty trash action
- deleted placeholder action where permitted
- archive/default filters across directories

Rules:

- Normal views hide soft-deleted records.
- Archived records are hidden from default active lists but available through filters.
- Trash view is visible only to users with restore/manage permission.
- Empty trash confirmation explains permanence.
- Hard-deleted records remain unavailable and do not break surrounding content.

### 8. Add Attention Cues

Add local in-app cues for:

- pending campaign invitations
- stale-save conflicts
- unsaved layout changes
- inaccessible/private/deleted placeholders
- failed saves
- failed uploads
- permission-denied actions
- pending destructive confirmation

Rules:

- No global notification center.
- Cues appear in the relevant context.
- Cues respect role and visibility.
- Use Yife notification wrapper for toasts, not raw Nuxt UI toast calls.

### 9. Add Mobile Simplified Layout

Implement mobile role-aware navigation:

- campaign navigation
- entity lists
- entity detail
- notes
- relationships
- timeline
- settings

Rules:

- Mobile uses stacked views, tabs, or drawers.
- Desktop saved layouts do not apply on mobile.
- Core flows remain usable on mobile.
- Dense desktop controls collapse to accessible mobile controls.
- Text must not overflow buttons/cards/panels.

### 10. Accessibility And UX Hardening

Audit:

- icon-only controls have accessible labels
- tooltips are not the only accessible names
- dialogs trap/restore focus
- dropdowns/popovers are keyboard accessible
- focus states are visible
- contrast is sufficient in light/dark themes
- forms have labels and errors
- command palette and shortcuts are keyboard-safe
- rich text editor has labels/instructions where needed

Rules:

- Do not claim formal WCAG compliance.
- Fix high-impact accessibility issues before considering MVP complete.

### 11. Deployment Readiness

Verify:

- Nuxt remains SPA mode with `ssr: false`
- Vercel build settings are documented or configured
- `.env.example` is current
- no real secrets are committed
- generated Supabase DB types are current
- local migrations reset cleanly
- remote Supabase migration path is documented
- public Storage bucket setup is documented
- deferred services remain absent

Rules:

- Use one remote Supabase MVP project unless environments are explicitly expanded.
- Keep Vercel Functions out of MVP unless a concrete need appears.
- No paid/runtime vendors are added without approval.

### 12. Add Final Tests

Database/RLS/RPC tests:

- invitation create/revoke/accept/decline lifecycle
- invitation acceptance rejects wrong email, expired invite, revoked invite, and duplicate membership
- owner invariants survive role/member mutations
- removed members lose access
- soft delete hides from normal reads
- restore returns record to normal reads
- empty trash is owner-only and campaign-scoped
- user/campaign/member/workspace settings RLS

Unit/component tests:

- settings scope navigation
- invitation list states
- trash/restore controls
- attention cue rendering
- mobile navigation states
- accessibility labels for icon controls
- confirmation dialogs

Playwright smoke/e2e tests:

- accept invitation and enter campaign
- owner removes member and removed member loses access
- soft delete entity, see placeholder, restore entity
- empty trash confirmation
- pending invitation cue
- failed permission action cue
- mobile entity browse/detail/notes flow
- command palette still works after settings/layout hardening

Manual browser pass:

- desktop Chrome
- desktop Firefox
- desktop Safari
- mobile Safari
- mobile Chrome

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

Document any manual browser, mobile, email, or remote deployment checks that cannot be automated locally.

## Manual Steps Required From Andrew

- Confirm the owner-only membership-security decision before implementation.
- Configure/verify remote Supabase project and Vercel environment variables when ready to deploy.
- Manually test invitation email/copy flow.
- Manually test mobile Safari and mobile Chrome.
- Review accessibility and MVP deferred-feature list before launch.

## Success Criteria

- Settings are organized by clear scope.
- User, campaign, member, and workspace settings respect permissions.
- Campaign invitations can be created, accepted, declined, revoked, and listed safely.
- Owner invariants cannot be broken.
- Removed members lose campaign access.
- Soft delete, restore, and empty trash work through RPCs.
- Placeholders remain safe for deleted/inaccessible records.
- Attention cues cover MVP failure/attention states.
- Mobile simplified layout supports core campaign browsing and note/detail workflows.
- Accessibility baseline issues are addressed.
- Local verification commands pass or exact blockers are documented.
- Deployment readiness checklist is complete.

## What Good Looks Like

- A real group can be invited into a campaign and use the app without obvious privacy, deletion, or navigation hazards.
- Settings clearly communicate who is affected by each change.
- The app remains compact and fast while handling mobile and accessibility basics.
- Deferred post-MVP features stay clearly out of scope.

## Resolved Decisions

- Use Supabase Auth/built-in email or a copyable invite flow; no custom transactional email provider.
- Membership security management is owner-only in MVP.
- GMs can manage campaign workflow data only where specific earlier feature permissions allow it.
- Soft delete is default; empty trash hard delete is owner-only.
- Mobile uses simplified role-aware layout rather than desktop layout parity.
- No CI, analytics, monitoring, feature flags, private media, realtime, or offline support in MVP.

## Decision Log

GM membership management:

- Option 1: owners and GMs can manage invitations, member roles, and removals.
- Option 2: owners only manage membership security; GMs manage campaign workflow data where permitted.
- Decision: choose option 2 for MVP. It is safer, preserves owner invariants, and matches explicit owner-focused invitation/removal requirements. Broader GM member administration can be promoted later with dedicated copy and tests.

Invitation email delivery:

- Option 1: integrate a custom transactional email provider.
- Option 2: use Supabase/Auth defaults and/or a copyable invite flow.
- Decision: choose option 2 for MVP to avoid a new runtime vendor.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Tightened invitation acceptance so normalized email comes from authenticated identity, not caller input.
- Prohibited invitations from assigning the owner role.

Pass 2 corrections incorporated:

- Clarified that empty-trash hard delete must not depend on successful Storage object cleanup.
- Kept owner-only membership security as a documented MVP product/security decision.
