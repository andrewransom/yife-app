# Yife Technology Stack

## Purpose

This document defines the initial technology stack for Yife.app.

The stack is optimized for:

- low operating cost and free-tier viability
- solo-developer speed
- AI-assisted development with clear conventions
- dense, responsive campaign-management workflows
- Supabase/PostgreSQL-first data security and consistency

Yife is an authenticated, data-heavy web app. The MVP should avoid unnecessary runtime services, paid dependencies, and infrastructure that does not directly support the core campaign knowledge-management experience.

## Core Stack

| Area | Decision |
|---|---|
| Frontend framework | Nuxt 4 with Vue 3 and TypeScript |
| Rendering mode | SPA mode with `ssr: false` |
| Hosting | Vercel Hobby |
| Backend | Supabase-first |
| Database | Supabase Postgres |
| Auth | Supabase Auth with email/password and magic link |
| Storage | Supabase Storage |
| Package manager | pnpm |
| Runtime | Current Vercel-supported Node.js LTS |

## Frontend

Use Nuxt 4 in SPA mode.

Nuxt is used for application structure, routing, layouts, modules, and developer experience. SSR is disabled for MVP to avoid auth, hydration, and server/client boundary complexity in the authenticated campaign workbench.

```ts
export default defineNuxtConfig({
  ssr: false
});
```

Public pages may be made prerendered or SSR later if SEO becomes important. The authenticated app should remain client-heavy unless there is a concrete reason to change.

## Hosting

Use Vercel Hobby for the web app.

The early workflow is:

- develop and test locally
- deploy live when ready
- defer Vercel preview deployments as a regular workflow

Vercel previews may be enabled later when branch-level hosted testing becomes useful. Keep Vercel Functions out of MVP unless a specific need appears.

## Backend And Data Access

Use Supabase as the primary backend:

- Postgres for relational data
- RLS for data protection
- RPCs for multi-step or permission-sensitive mutations
- views/RPCs for safe role-aware reads
- Storage for uploaded images
- generated TypeScript database types

Do not add an ORM for MVP. Use Supabase SQL migrations, generated TypeScript types, and `supabase-js`.

Generated database types live at:

```text
supabase/types/database.types.ts
```

The app imports them through app-owned wrapper modules or aliases.

## Supabase Development

Use Supabase local development for schema and migration work.

Expected workflow:

1. Run Supabase locally through the Supabase CLI.
2. Develop schema changes as SQL migrations.
3. Test RLS, views, triggers, and RPCs locally.
4. Generate TypeScript database types from the local database.
5. Commit migrations and generated types.
6. Push/apply migrations to one remote Supabase MVP project for deployed use.

Use one remote free Supabase project for MVP until separate staging/production projects are justified.

Required seed data should cover system defaults only, such as entity types, section definitions, roles, statuses, and option definitions. Do not add demo campaign seed data until it is clearly useful.

## App/API Boundary

Data-critical logic belongs in Supabase views, RLS, and RPCs.

Nuxt client code and composables should orchestrate UI behavior, not replace database-side consistency.

Use RPCs for:

- invitation acceptance
- typed entity creation
- rich text saves and mention rebuilding
- section and note version checks
- role/visibility-sensitive reads where views are not enough
- soft delete, restore, and empty trash
- multi-table mutations

Direct table reads/writes are acceptable only for simple cases where RLS and constraints fully cover the behavior.

Avoid Edge Functions, Vercel Functions, and custom backend APIs unless there is a clear need.

## Supabase Nuxt Integration

Use `@nuxtjs/supabase` for Nuxt integration, but do not let components call Supabase directly.

Components should use Yife-owned query/mutation composables and service modules.

Rule:

```text
Components do not call Supabase directly.
Server content is read through feature query composables.
Server mutations go through feature mutation composables.
```

## State Management

Use:

- TanStack Query Vue for server content and server-state cache
- Pinia for shared app/UI state
- local component state only for highly localized UI concerns

TanStack Query owns fetched server data:

- campaigns
- entity lists
- entity details
- notes
- sections
- relationships
- mutation state
- loading/error/refetch state
- optimistic updates
- invalidation

Pinia owns shared app/UI state:

- active campaign id
- active role/view mode
- selected entity id
- open tabs/panels
- layout mode
- command palette state
- drawer/sidebar state
- user workspace preferences that are not server records

Do not duplicate the same server content in both TanStack Query and Pinia.

All mutations that change server content must go through feature mutation composables. Mutations should update or invalidate the relevant TanStack Query caches.

## UI Framework

Use Tailwind CSS and Nuxt UI.

Nuxt UI should be treated as an accessible primitive/component base, not as the visual identity of the product. Yife should define its own compact wrappers around common controls.

Create Yife components for repeated UI patterns, such as:

- buttons and icon buttons
- toolbars
- panels
- entity rows
- dense lists
- form fields
- tabs
- status badges
- visibility indicators

Authenticated app UI should be dense, work-focused, and optimized for scanning. Avoid large marketing-style layouts inside the campaign workspace.

Default UI direction:

- compact spacing
- low border radius
- small icon CTAs with tooltips
- stable row heights
- clear focus states
- light and dark themes
- no nested card-heavy layouts

## Design Tokens

Use a small explicit design token source mapped into Tailwind and Nuxt UI configuration.

The token source may be TypeScript or JSON, for example:

```text
app/design/tokens.ts
```

Tokens should cover:

- color roles
- typography scale
- spacing and density scale
- radius policy
- component size tokens
- z-index/layer tokens
- light and dark theme roles

The token file exists to keep UI decisions explicit for humans and AI agents. It must not drift from the actual Tailwind/Nuxt UI configuration.

## Icons

Use Lucide as the standard icon set.

Use a different or custom icon only when Lucide does not provide a suitable symbol.

## Forms And Validation

Use Zod and VeeValidate.

Client-side validation exists for user experience and fast feedback. Database constraints, RLS, and RPC validation remain authoritative.

Avoid duplicating complex business rules across many forms. Prefer shared schema/helpers where practical.

## Rich Text

Use Tiptap Vue 3.

The existing content model stores rich text as ProseMirror-style JSON plus derived text. Tiptap aligns with that model and supports future entity mentions and collaboration paths.

MVP extension set should stay narrow:

- paragraphs
- headings
- bold
- italic
- inline code
- bullet and ordered lists
- links
- blockquote
- horizontal rule
- entity mentions

Defer:

- realtime collaborative editing
- comments
- embedded media
- complex tables
- custom document blocks

## Media And Images

Use Supabase Storage with public bucket files, Postgres metadata, and client-generated variants.

MVP image handling:

- generate variants locally in the browser before upload
- store variants in Supabase Storage
- store asset and variant metadata in Postgres
- query Postgres metadata for grids and lists
- store bucket/path as source of truth
- derive public URLs in the app
- keep original image retention optional and off by default
- defer private media

Required initial variants:

- `thumb_160`
- `grid_480`

Variant generation must support user-selected crop anchor points for cropped variants:

```text
top-left     top-center     top-right
center-left  center         center-right
bottom-left  bottom-center  bottom-right
```

Default crop anchor is `center`.

Media records should be campaign-scoped where relevant and track the uploading user. RLS protects metadata and associations. Public Storage files are accessible to anyone with the URL, so the UI and documentation must warn users not to upload sensitive images in MVP.

Campaigns, characters, NPCs, and locations may store direct primary image asset references for fast list and picker display. Generic media attachments are post-MVP unless promoted.

## Dense Lists And Tables

Build custom dense list components first.

Add TanStack Table only when a view needs true table behavior, such as:

- column sorting
- column visibility
- resizable columns
- row virtualization
- advanced table filtering

Do not force simple entity directories into a heavy table abstraction.

## Search

Use split search behavior:

- client-side search for instant navigation
- Postgres/Supabase search for deep content

Client-side search should cover:

- command palette navigation
- loaded campaign/entity names
- `ListCaption`
- simple type/status filtering on already-loaded lists

Client search must only search data already loaded for the authorized user.

Postgres/Supabase search should cover:

- note body text
- section body text
- larger campaign-wide search
- role/visibility-safe search results

Use derived `body_text` from rich text JSON for deep text search.

No external search service for MVP.

## Dates And Time

Use native JavaScript date handling and `Intl` initially.

Store timestamps in UTC with `Z`. Convert to local time only for display.

Use ISO strings in the database and APIs. Add `date-fns` only if real date math becomes painful.

## Notifications

Use Nuxt UI toasts through a Yife notification wrapper composable.

Feature code should call the wrapper, not the raw toast implementation. This keeps notifications consistent and allows the implementation to change later.

## Route Protection

Use Nuxt route middleware for authenticated route UX in SPA mode.

Client-side route middleware is not a security boundary. Supabase RLS, views, and RPCs are the real data security boundary.

## Testing

Use:

- Vitest for unit tests
- Vue Test Utils for component tests
- Playwright for browser/e2e tests

Add Supabase migration/RLS/RPC smoke tests once schema work starts.

Initial CI is not required. Run local scripts first. GitHub Actions can be added later for lint, typecheck, and unit tests. Playwright CI can be added after core flows exist.

## Code Quality

Use:

- TypeScript strict mode
- ESLint
- Prettier

Add scripts for:

- typecheck
- lint
- format/check format
- unit tests
- browser/e2e tests

Keep rules practical and aligned with Nuxt/Vue conventions.

## Environment Variables

Use:

- local `.env`
- Vercel environment variables
- committed `.env.example`

Do not commit real secrets.

Clearly distinguish public client variables from secrets. Supabase anon keys are expected to be client-visible; RLS is responsible for protecting data.

## Git Workflow

Use feature branches for meaningful work. Merge to `main` when ready.

No mandatory PR workflow is required during early solo development. Keep `main` deployable.

## Repo Structure

Use a single repo and single Nuxt app initially, with top-level folders reserved for non-app concerns.

Recommended shape:

```text
/
  app/
  docs/
  scripts/
  supabase/
  package.json
```

Do not start with a pnpm monorepo. Keep the structure monorepo-compatible so the app can move to `apps/web` later if needed.

## Browser Support

Support modern evergreen browsers only:

- Chrome
- Edge
- Firefox
- Safari
- mobile Safari
- mobile Chrome

Test Safari for image upload, canvas resizing, WebP, and mobile behavior.

## Accessibility

Use a pragmatic WCAG-minded baseline.

MVP UI should include:

- keyboard-accessible controls
- semantic buttons, links, and forms
- labels for form fields
- visible focus states
- sufficient color contrast
- accessible dialogs, popovers, dropdowns, and tooltips

Do not claim formal WCAG compliance in MVP.

## Internationalization

Use English only for MVP.

Do not add an i18n framework yet. Centralize reusable labels/options where natural, but avoid translation boilerplate.

## Realtime And Offline

No realtime UX in MVP.

Keep query keys and mutation invalidation clean so Supabase Realtime invalidation can be added later.

No offline/PWA support in MVP. The app requires network access.

## Analytics, Monitoring, And Flags

No product analytics initially.

No external error monitoring initially. Sentry free tier is the first likely upgrade once outside testers use the app.

No feature flag service initially. Use simple config/constants or environment-gated flags only.

## Transactional Email

Use Supabase Auth built-in emails initially.

Defer Resend or another email provider until custom campaign invitation email UX is needed.

## AI Product Features

Do not include a runtime AI product stack in MVP.

Design only for future compatibility by keeping the data model clean:

- rich text JSON
- derived `body_text`
- structured sections
- entity relationships
- activity metadata

Do not add AI SDK dependencies, AI provider environment variables, AI tables, or AI jobs until a real feature requires them.

## Deferred Stack Areas

Deferred unless explicitly promoted:

- payments and billing
- admin tooling
- native mobile
- background jobs and queues
- external file attachments beyond MVP images
- expanded observability
- formal security audit/compliance
- external search
- private media
- realtime collaboration
- Storybook

## Agent Rules Summary

Future AI agents working on this project should follow these rules:

- Do not enable SSR unless the rendering decision is revisited.
- Do not call Supabase directly from components.
- Put server content in TanStack Query, not Pinia.
- Put shared app/UI state in Pinia.
- Route all server mutations through feature mutation composables.
- Use Supabase migrations for database changes.
- Use RPCs for multi-table, visibility-sensitive, or versioned writes.
- Keep UI dense, compact, and consistent with Yife design tokens.
- Use Nuxt UI through Yife wrappers where patterns repeat.
- Store image bucket/path, not public URLs as source of truth.
- Warn that MVP image files are public by URL.
- Keep runtime vendors and paid services out of MVP unless explicitly approved.
