# 03. Auth, Campaign Home, And Campaign Creation

## Purpose

Implement the first usable authenticated vertical slice.

A user should be able to reach the public landing page, sign up or sign in with Supabase Auth, arrive at authenticated home, create a campaign, receive owner membership/role/defaults through the database RPC, see their campaign list, switch into a campaign, and land in the campaign workspace shell.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/dev/milestones/01-project-foundation.md`
- `docs/dev/milestones/02-supabase-core-schema-and-security-foundation.md`

## Goals

- Wire Supabase Auth into the Nuxt SPA through `@nuxtjs/supabase`.
- Add public landing page entry points for sign in and account creation.
- Add sign-in, sign-up, sign-out, and auth callback/error handling.
- Add route middleware for authenticated-route UX.
- Create user profile/settings defaults after first sign-in where needed.
- Build authenticated home with campaign cards.
- Implement campaign creation through the `create_campaign` RPC.
- Implement campaign list reads through Yife query composables.
- Implement campaign switching into the workspace shell.
- Store selected campaign and UI view preference in Pinia.
- Keep all server content in TanStack Query.
- Add initial tests for auth UI states, campaign list, campaign creation, and route guards.

## Non-Goals

- No campaign invitation workflow.
- Invitation acceptance is a later named milestone and must not be treated as part of this slice.
- No remote transactional email customization beyond Supabase Auth defaults.
- No full campaign settings UI.
- No campaign image upload. Campaign image fields may be shown as disabled/placeholder until the media milestone.
- No entity directories beyond placeholder navigation.
- No rich text.
- No workbench layout persistence.
- No role switching beyond displaying the effective role/view context available from membership data.

## Assumptions

- Milestone 01 has created the Nuxt app foundation.
- Milestone 02 has created local Supabase schema, RLS, generated types, and `create_campaign`.
- Local development uses Supabase local Auth first.
- A single remote Supabase MVP project will be configured later unless Andrew explicitly wants remote setup now.
- Supabase Auth email/password and magic link are both allowed by the stack decision.
- This is a partial campaign-creation slice. Create-time image upload and create-time member invitations remain tracked follow-up work for the media and invitation milestones.

## User-Facing Scope

### Public Visitor

- Can view a concise landing page.
- Can navigate to sign in or create account.
- Does not see campaign workspace navigation.

### Signed-In User With No Campaigns

- Lands on authenticated home.
- Sees an empty campaign state.
- Can create a campaign.
- Can access user menu/settings placeholder.

### Signed-In User With Campaigns

- Sees campaign cards with name, description, status, role, and placeholder image area.
- Can open a campaign.
- Can sign out.

### Campaign Owner After Creation

- Becomes owner and active member.
- Has owner role membership.
- Gets seeded campaign entity type settings and currency defaults from the RPC.
- Lands in or can navigate to the campaign workspace shell.

## Implementation Steps

### 1. Configure Supabase Auth In Nuxt

- Configure `@nuxtjs/supabase` with public runtime config:
  - `NUXT_PUBLIC_SUPABASE_URL`
  - `NUXT_PUBLIC_SUPABASE_ANON_KEY`
- Add typed Supabase client wrapper for app composables.
- Confirm generated database types are imported through a Yife-owned module.
- Ensure components still do not call Supabase directly.
- Add explicit auth redirect configuration:
  - `/auth/callback` route in the Nuxt app
  - local Supabase `site_url`
  - local allowed redirect URLs for sign-in, sign-up, and magic-link flows
  - documented email-confirmation behavior for local development

### 2. Add Auth Composables

Create app-owned auth composables, for example:

- `useCurrentUser`
- `useAuthSession`
- `useSignIn`
- `useSignUp`
- `useSignOut`
- `useEnsureUserProfile`

Rules:

- Auth composables may use Supabase client wrappers.
- Components consume composables, not Supabase directly.
- Profile/settings creation must call an idempotent `ensure_user_defaults` RPC.
- If milestone 02 did not provide that RPC, milestone 03 must add the migration, regenerate types, and test it before building the UI flow.
- Auth errors should flow through the Yife notification wrapper.

### 3. Add Route Middleware

- Add guest/public route handling for landing and auth pages.
- Add authenticated route middleware for home and campaign routes.
- Wait for Supabase session hydration before deciding redirects.
- Redirect unauthenticated users to sign in.
- Preserve intended destination with a `redirectTo` parameter for protected routes.
- Redirect signed-in users away from auth pages when appropriate.
- Treat middleware as UX only. Do not describe it as a security boundary.

### 4. Build Public Landing Page

- Keep the landing page concise and product-specific.
- Describe Yife as a campaign knowledge-management tool for tabletop roleplaying games.
- Provide sign-in and account-creation entry points.
- Do not expose authenticated app shell or campaign workspace navigation.
- Keep copy functional; avoid overbuilding marketing sections.

### 5. Build Auth Pages

- Add sign-in form.
- Add sign-up form.
- Support email/password.
- Support magic-link sign-in only after the callback route and local redirect configuration are verified.
- Add clear loading, error, and success states.
- Validate forms with Zod and VeeValidate.
- Use dense Yife form wrappers from milestone 01.

### 6. Ensure User Profile And Settings

- On first authenticated app entry, ensure:
  - `user_profiles` row exists.
  - `user_settings` row exists.
- Use the idempotent `ensure_user_defaults` RPC.
- Profile defaults should be minimal:
  - display name from email prefix or empty editable value
  - theme preference default
  - default landing behavior default
- Do not store campaign layout state in user settings.

### 7. Build Campaign Query Composables

Create feature query composables:

- `useMyCampaignsQuery`
- `useCampaignMembershipSummaryQuery`
- `useCampaignByIdQuery`
- `useCampaignStatusOptionsQuery`

Create feature mutation composables:

- `useCreateCampaignMutation`

Rules:

- TanStack Query owns fetched campaign server state.
- Pinia stores only selected campaign id and UI state.
- Effective campaign roles are derived from `useCampaignMembershipSummaryQuery`.
- Pinia role/view values are UI preferences only and must never authorize GM content or permission-sensitive controls.
- `useMyCampaignsQuery` must use the safe campaign-list view/RPC from milestone 02.
- `useCampaignMembershipSummaryQuery` must use the safe membership/role summary view/RPC from milestone 02.
- Do not build ad hoc joins in components or services for role-bearing campaign summaries.
- Mutations invalidate or update relevant campaign query caches.
- Query keys should be stable and future-realtime-friendly.

### 8. Build Authenticated Home

- Show campaign cards using the safe campaign list read surface.
- Each card should show:
  - campaign name
  - description
  - status
  - user's role summary
  - placeholder image area
  - recent/next session placeholder if unavailable
- Add create-campaign action.
- Add user menu with sign-out and settings placeholder.
- Do not render the campaign workspace shell on home.

### 9. Implement Campaign Creation

- Add campaign creation form.
- Required fields:
  - name
  - start date
- Campaign status should either:
  - load valid campaign statuses from `status_definitions` through `useCampaignStatusOptionsQuery`, or
  - be omitted from the form and defaulted by `create_campaign`.
- Optional fields:
  - description
  - end date
- Show image upload as unavailable/deferred, or omit it with an explicit product TODO in implementation notes.
- Do not implement invite-member inputs in this form yet; track it as invitation milestone work.
- Submit through `create_campaign` RPC mutation.
- On success:
  - invalidate campaign list query
  - set active campaign id in Pinia
  - navigate to the campaign workspace shell or show a clear open action
- On failure:
  - show contextual error
  - preserve form data

### 10. Implement Campaign Switching

- Add campaign switcher to authenticated navigation/workspace shell.
- Use loaded authorized campaign summaries.
- Changing campaigns should:
  - update Pinia active campaign id
  - navigate to the selected campaign workspace route
  - clear selected entity/open placeholder state as needed
- If a campaign id is inaccessible, show a generic unavailable state and route back to home.

### 11. Build Campaign Workspace Landing Shell

- Add route such as `/campaigns/[campaignId]`.
- Load campaign membership/role summary.
- Show compact campaign identity in top navigation.
- Show role/view indicator derived from membership summary query data.
- Show placeholder directories menu.
- Show campaign overview placeholder in the main area.
- Respect missing/inaccessible campaign states.
- Do not implement saved layouts yet.

### 12. Add Attention Cues For This Scope

Add contextual cues for:

- failed sign-in/sign-up
- sign-up email confirmation pending if applicable
- failed profile/settings initialization
- failed campaign creation
- inaccessible campaign route
- permission denied from RPC/RLS

Do not add a global notification center.

### 13. Add Tests

Unit/component tests:

- auth form validation
- campaign card rendering
- campaign creation form validation
- campaign switcher empty and populated states

Integration or mocked-query tests:

- campaign creation mutation invalidates campaign list
- Pinia active campaign id updates after selection
- route middleware redirects unauthenticated users

Playwright smoke tests:

- public landing page loads
- sign-in page loads
- authenticated home route redirects when unauthenticated
- campaign workspace route shows unavailable/redirect behavior when unauthenticated

Mandatory vertical-slice proof:

- sign up or sign in a local test user
- create campaign
- verify campaign card appears
- open campaign workspace shell

This can be automated with a seeded local Auth user/admin script or verified with a documented manual checklist. One of those paths must be completed before the milestone is considered done.

### 14. Verify Locally

Run:

```sh
pnpm supabase:start
pnpm supabase:reset
pnpm db:test
pnpm typecheck
pnpm lint
pnpm format:check
pnpm test:unit
pnpm build
pnpm test:e2e
```

If Auth email flows cannot be fully automated locally, run and record the manual verification path.

## Manual Steps Required From Andrew

- Provide local `.env` values for Supabase URL and anon key from the local Supabase CLI output.
- Confirm Supabase Auth local `site_url`, allowed redirect URLs, email-confirmation behavior, and magic-link behavior.
- Manually verify any email/magic-link flow that cannot be automated locally.
- Decide whether campaign creation should immediately navigate into the workspace or return to home with the new campaign selected.
- Decide whether image upload should be visibly disabled in the create form or omitted until the media milestone.
- Decide whether the mandatory e2e proof uses a seeded local Auth user script or a manual checklist.

## Success Criteria

- Public landing page is reachable while signed out.
- Auth pages are reachable while signed out.
- `/auth/callback` handles successful and failed auth redirects.
- Authenticated home is protected by route middleware.
- Protected-route redirects wait for session hydration and preserve intended destination.
- A signed-in user can reach authenticated home.
- First app entry creates or verifies user profile/settings defaults.
- Campaign list loads through a query composable.
- Campaign list and membership summary composables use milestone 02 safe read surfaces.
- Campaign creation calls the database RPC through a mutation composable.
- Created campaign appears on home without a full page reload.
- Creator receives owner membership and owner role from the database workflow.
- Campaign switcher opens the campaign workspace shell.
- Pinia contains UI/app state only, not duplicated campaign records.
- Effective roles are derived from TanStack Query membership data, not Pinia.
- Components do not call Supabase directly.
- A mandatory login/create-campaign/open-workspace proof path is completed and documented.
- Typecheck, lint, unit tests, build, and relevant Playwright smoke tests pass.

## What Good Looks Like

- The app has a real login-to-created-campaign loop.
- Database security still does the real access control.
- UI route guards improve navigation without pretending to secure data.
- The home page feels like the start of the product, not a generic demo.
- Campaign creation proves the app/database boundary before broad entity work begins.
- Deferred features are clearly absent rather than half-implemented.
- Create-time image upload and member invitations are explicitly tracked as later milestone work.

## Open Decisions

- Whether campaign creation navigates directly into the new campaign workspace.
- Whether local Auth should require email confirmation during development.
- Whether magic-link sign-in is included immediately or only email/password for the first pass.
- Whether profile display name defaults from email prefix or starts blank.
- Whether create-campaign image UI is omitted or shown disabled until media support exists.
- Whether e2e tests should seed Auth users directly or use UI-driven sign-up.

## Adversarial Review Notes

Reviewed by subagent after initial draft. Valid corrections incorporated:

- Clarified invitation acceptance is a later named milestone, not milestone 03.
- Added `/auth/callback`, redirect URL, `site_url`, and local email/magic-link configuration requirements.
- Made login/create-campaign/open-workspace proof mandatory through automation or documented manual verification.
- Removed server membership facts from Pinia; effective roles come from membership summary query data.
- Required idempotent `ensure_user_defaults` RPC.
- Pinned campaign composables to safe database read surfaces.
- Added campaign status loading/defaulting requirements.
- Marked create-time image upload and invitations as explicit later work.
- Added session-hydration and `redirectTo` requirements for route middleware.
