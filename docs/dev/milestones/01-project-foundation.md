# 01. Project Foundation

## Purpose

Create the app and developer foundation for Yife without introducing database schema yet.

This milestone should leave the repository ready for repeatable Nuxt/Vue implementation, AI-assisted edits, local verification, dense UI component development, and later Supabase integration.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-technology-stack-decisions.md`

## Goals

- Scaffold a single Nuxt 4 app in top-level `app/`.
- Keep Nuxt in SPA mode with `ssr: false`.
- Use Vue 3, TypeScript strict mode, pnpm, Tailwind CSS, Nuxt UI, Pinia, TanStack Query Vue, Zod, VeeValidate, Tiptap Vue 3, and Lucide.
- Establish local scripts for dev, build, typecheck, lint, format, unit tests, and browser/e2e tests.
- Add a design-token source and wire it into Tailwind/Nuxt UI config.
- Create the first Yife wrapper component patterns for dense UI.
- Add public, authenticated-home, campaign-workspace, and dev-only component-workbench route shells.
- Add environment-file conventions without real secrets.
- Add initial tests that prove the app boots and basic route shells render.

## Non-Goals

- No Supabase migrations.
- No production database tables.
- No RLS policies.
- No real auth flow.
- No campaign creation persistence.
- No rich text persistence.
- No deployment setup beyond build compatibility.

## Assumptions

- The repo remains a single app repo, not a monorepo.
- Use a root-owned Nuxt app: root `package.json`, root lockfile, root scripts, and Nuxt configured to use `app/` as the source directory.
- Do not create `app/package.json` in this milestone.
- Vercel deployment will run from the repo root with explicit settings or `vercel.json`.
- Supabase credentials may be represented in `.env.example`, but no real credentials are committed.

## Required Dependencies

Install runtime dependencies:

- `nuxt`
- `vue`
- `@nuxt/ui`
- `tailwindcss`
- `@nuxtjs/supabase`
- `@pinia/nuxt`
- `pinia`
- `@tanstack/vue-query`
- `@supabase/supabase-js`
- `zod`
- `vee-validate`
- `@vee-validate/zod`
- `@tiptap/vue-3`
- `@tiptap/starter-kit`
- `@tiptap/extension-link`
- `@tiptap/extension-placeholder`
- `lucide-vue-next`

Install dev dependencies as needed for:

- TypeScript
- ESLint
- Prettier
- Vitest
- Vue Test Utils
- Playwright
- Nuxt test utilities where useful

## Implementation Steps

### 1. Initialize Package And App Structure

- Create root `package.json` for a single pnpm-managed project.
- Add `packageManager` with an exact pnpm version.
- Pin Node 24 for local and Vercel compatibility:
  - `.nvmrc` should use `24.16.0` unless a newer Node 24 LTS patch is intentionally chosen during implementation.
  - `package.json` `engines.node` should use `24.x`.
- Do not create `app/package.json`.
- Create or update `pnpm-workspace.yaml` only if Nuxt tooling requires it; do not create a multi-package workspace.
- Add `.npmrc` with strict pnpm-friendly defaults if useful.
- Create the top-level `app/` Nuxt project.
- Keep non-app concerns at top level:
  - `docs/`
  - `scripts/`
  - `supabase/` later

Expected shape after this step:

```text
/
  app/
  docs/
  scripts/
  package.json
  .nvmrc
```

### 2. Configure Nuxt SPA Mode

- Add `app/nuxt.config.ts`.
- Set `ssr: false`.
- Configure Nuxt so repo-root scripts run the app from `app/` without a nested package.
- Add global CSS under `app/assets/css/` and import Tailwind CSS plus Nuxt UI from there.
- Wrap the app with Nuxt UI's app provider so toasts, tooltips, and overlays work.
- Register modules:
  - Nuxt UI.
  - Supabase Nuxt module.
  - Pinia.
- Do not add the old Tailwind Nuxt module unless current Nuxt UI guidance changes; Nuxt UI plus `tailwindcss` is the intended M01 path.
- Add app aliases for stable imports if helpful, using Nuxt-friendly aliases such as `~/` or `@/`.
- Avoid custom `#*` aliases unless there is a clear need, because Nuxt reserves that prefix for virtual imports.
- Keep runtime config placeholders for Supabase URL and anon key.
- Do not add server routes or Nitro APIs for MVP app data.

### 3. Configure TypeScript And Quality Tools

- Enable TypeScript strict behavior.
- Add ESLint with practical Nuxt/Vue/TypeScript rules.
- Add Prettier.
- Add scripts:
  - `dev`
  - `build`
  - `preview`
  - `typecheck`
  - `lint`
  - `format`
  - `format:check`
  - `test:unit`
  - `test:e2e`
- Make scripts runnable from the repo root.
- Add either `vercel.json` or documented Vercel project settings covering install command, build command, output directory, and root behavior.
- Prefer boring defaults that AI tools can follow consistently.

### 4. Add Project `.gitignore`

- Add a project-appropriate `.gitignore`.
- Cover at minimum:
  - `node_modules`
  - `.nuxt`
  - `.output`
  - coverage output
  - Playwright reports
  - test results
  - local env files
  - logs
  - OS/editor noise
- Keep `.env.example` tracked.

### 5. Add Tailwind/Nuxt UI Theme Foundation

- Create `app/design/tokens.ts` as the explicit token source.
- Include tokens for:
  - color roles
  - typography scale
  - spacing/density
  - low radius policy
  - component sizing
  - focus ring
  - z-index/layers
  - light and dark theme roles
- Wire tokens into Tailwind/Nuxt UI configuration.
- Use `app/design/tokens.ts` as the imported source for Tailwind/Nuxt UI theme config, global CSS variables, and wrapper component sizing/style constants.
- Add a lightweight test or lintable import convention so token consumers import from the token source rather than duplicating values.
- Keep the palette balanced and work-focused, avoiding a one-note color theme.
- Use compact spacing and low radii from the start.

### 6. Add App Shell Route Skeletons

- Add public landing route shell.
- Add authenticated home route shell.
- Add campaign workspace route shell.
- Add dev-only component workbench route.
- Route shells are visual-only placeholders in this milestone: no auth middleware, no permission claims, and no protected data.
- The public route must not show the campaign workspace shell.
- The authenticated home route must not show the campaign workspace shell until a campaign is selected.
- Gate the dev-only workbench with an environment flag that defaults off.
- No route middleware is required for this gate in M01.
- Add a build/preview check proving the dev-only route shows the app-level not-found state or redirects when the flag is off.
- Do not rely on HTTP 404 status for this check; Nuxt SPA preview may still serve the shell with a 200 response.
- The campaign workspace shell should reserve the eventual desktop regions:
  - compact top navigation/action area
  - left sidebar/list area
  - central detail area
  - collapsible right contextual panel

### 7. Add Yife UI Wrapper Seeds

Create the first reusable wrappers under a clear component namespace.

Start with:

- dense button
- icon button with accessible label and tooltip support
- compact toolbar
- panel surface
- entity row skeleton
- status badge skeleton
- visibility badge skeleton
- form field wrapper
- empty state

Rules:

- Use Nuxt UI as accessible primitives.
- Use Lucide icons for icon buttons.
- Icon-only controls must have accessible labels.
- Tooltips must not be the only accessible name.
- Avoid nested cards.
- Keep row heights stable.

### 8. Add State And Data Access Boundaries

- Add Pinia store skeletons for app/UI state only:
  - selected campaign id
  - active view preference
  - selected entity id
  - command palette open state
  - right panel collapsed state
- Add TanStack Query Vue plugin wiring.
- Add placeholder query/mutation composable folders.
- Add a local rule in docs or comments that components must not call Supabase directly.
- Do not add a real Supabase client wrapper until generated database types exist.
- If a placeholder adapter is useful, keep it empty/internal and do not expose it to components.

### 9. Add Environment Conventions

- Add `.env.example`.
- Include public client variables only:
  - `NUXT_PUBLIC_SUPABASE_URL`
  - `NUXT_PUBLIC_SUPABASE_ANON_KEY`
- Add comments that real secrets must not be committed.
- Confirm `.env` is ignored.
- Add a disabled-by-default environment variable for the dev component workbench flag.

### 10. Add Initial Tests

- Add a Vitest smoke test for at least one wrapper/component.
- Add a route or app smoke test if Nuxt test utilities are available.
- Add a minimal Playwright config and one smoke test that loads the local app.
- Configure Playwright with deterministic `baseURL`, a `webServer` that starts the production preview from root scripts, and a smoke suite that runs against `pnpm build` output.
- Make `pnpm test:e2e` self-contained by running or depending on `pnpm build` before Playwright starts preview.
- Prefer production preview for M01 Playwright smoke tests because it catches build/runtime issues and verifies the dev-only workbench is not exposed in production-like output.
- Defer a separate `pnpm dev` Playwright target until interactive/authenticated flows make it useful.
- Keep Playwright broad coverage for later milestones; this milestone only proves the harness works.

### 11. Verify Locally

Run:

```sh
pnpm install
pnpm typecheck
pnpm lint
pnpm format:check
pnpm test:unit
pnpm build
pnpm test:e2e
```

If Playwright browsers are not installed, install them locally and rerun, or document the blocker clearly.

## Manual Steps Required From Andrew

- Approve any dependency that appears to add a paid runtime vendor or non-MVP service. None are expected in this milestone.
- Run local browser installation for Playwright if the machine requires interactive/system-level setup.
- Confirm Vercel project settings if `vercel.json` is not committed in this milestone.

## Success Criteria

- `app/` contains a working Nuxt 4 SPA with `ssr: false`.
- Root package metadata pins Node and pnpm versions.
- `.gitignore` covers project-appropriate generated files, local env files, test artifacts, logs, and OS/editor noise.
- Root pnpm scripts work from the repository root.
- Typecheck, lint, format check, unit tests, and build pass locally.
- A minimal Playwright smoke test can load the app.
- Playwright starts the app through configured root-script `webServer`.
- Route shells exist for public landing, authenticated home, campaign workspace, and dev component workbench.
- The dev component workbench is inaccessible in production preview/build verification.
- Design tokens are defined in one explicit source and used by app styling config.
- Initial Yife wrappers demonstrate compact dense UI patterns.
- Pinia is present only for UI/app state.
- TanStack Query is wired for future server state.
- Components have no direct Supabase calls.
- `.env.example` exists, local env files are ignored, and no real secrets are committed.
- Vercel build/root behavior is explicitly configured or documented.

## What Good Looks Like

- A future AI agent can add a feature without first guessing project structure, script names, or styling conventions.
- The app boots quickly into clear placeholder route shells.
- Dense UI wrappers already communicate the intended workbench style.
- There is no premature backend abstraction or ORM.
- The foundation is boring, conventional, and easy to change.

## Open Decisions

None for M01 after current decisions.

Resolved:

- Node target: local `.nvmrc` uses `24.16.0` unless a newer Node 24 LTS patch is intentionally chosen; `package.json` uses `engines.node: "24.x"`.
- Dev-only workbench gate: disabled-by-default environment flag is sufficient.
- Playwright target: M01 smoke tests should run against production preview/build output.

## Adversarial Review Notes

Reviewed by subagent after initial draft. Valid corrections incorporated:

- Chose root-owned Nuxt with `app/` as source; no nested `app/package.json`.
- Added explicit Node/pnpm pinning and Vercel root/build configuration requirements.
- Required production gating and verification for the dev-only component workbench.
- Deferred real Supabase client wrapper until generated DB types exist.
- Clarified route shells are visual-only with no auth/security claims.
- Tightened Playwright, `.gitignore`, and design-token drift requirements.
