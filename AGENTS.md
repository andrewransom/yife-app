# AGENTS.md

## Project Context

Yife.app is a responsive campaign knowledge-management web app for tabletop roleplaying games. The MVP prioritizes fast, dense, role-aware workflows for capturing, linking, browsing, and updating campaign information.

This is a solo-developer project and AI tools will do much of the implementation. Prefer clear, boring, low-cost choices over clever architecture.

Key references:

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`

## Response Style

- Keep responses brief but clear unless the task needs detail.
- State assumptions and tradeoffs directly.
- When changing code, implement and verify when feasible; do not stop at a proposal.

## Stack Rules

- Use Nuxt 4, Vue 3, TypeScript, and pnpm.
- Keep Nuxt in SPA mode with `ssr: false` unless the rendering decision is explicitly revisited.
- Use Vercel Hobby for hosting.
- Use Supabase-first architecture: Postgres, Auth, Storage, RLS, views, RPCs, and generated TypeScript types.
- Do not add an ORM for MVP.
- Do not add paid/runtime vendors unless explicitly approved.

## Data Access Rules

- Components must not call Supabase directly.
- Read server content through feature query composables.
- Mutate server content through feature mutation composables.
- Use TanStack Query Vue as the authoritative server-content cache.
- Use Pinia for shared app/UI state only.
- Do not duplicate the same server records in both Pinia and TanStack Query.
- Local component state is fine only for highly localized UI behavior.

Use RPCs for:

- typed entity creation
- multi-table mutations
- invitation acceptance
- rich text saves
- note/section/contribution version checks
- mention extraction/rebuilds
- role or visibility-sensitive workflows
- soft delete, restore, and empty trash

Direct table/view calls are acceptable only for simple reads or simple single-row edits where RLS and constraints fully cover the behavior.

## Database Rules

- Use Supabase SQL migrations for schema changes.
- Keep generated DB types in `supabase/types/database.types.ts`.
- Test RLS, views, triggers, and RPCs locally with Supabase CLI when schema work starts.
- Required seed data should cover system defaults only unless demo data is explicitly requested.
- Store timestamps in UTC with `Z`; convert to local time only for display.

## Security And Visibility

- Supabase RLS, views, and RPCs are the real security boundary.
- Client-side route middleware is only for navigation UX.
- Campaign membership is the first access boundary.
- Section-level visibility and editability are the main mechanism for mixed-visibility content.
- Sensitive GM/player-private creative content belongs in protected section/note rows, not player-readable typed columns.
- Player-facing or mixed-visibility reads must use safe views/RPCs.
- Inaccessible references must degrade to generic placeholders without leaking hidden names or details.

## Content Model Rules

- Use the hybrid model: `campaign_entities` registry plus typed detail tables.
- Shared systems reference `campaign_entities.id`.
- Notes are separate records, not campaign entities.
- Long-form prose belongs in `entity_sections`, notes, or contribution rows.
- Rich text source of truth is Tiptap/ProseMirror-style JSON plus derived text.
- Rich text saves must check `version_number`, update derived text, increment version, and rebuild mentions.

## UI Rules

- Use Tailwind CSS and Nuxt UI.
- Treat Nuxt UI as accessible primitives; build Yife wrapper components for repeated controls.
- Use Lucide icons.
- Use the project design tokens and keep Tailwind/Nuxt UI config in sync with them.
- Authenticated app UI must be dense, compact, and optimized for scanning.
- Prefer small icon buttons with tooltips for common commands.
- Keep radius low, spacing tight, row heights stable, and focus states clear.
- Avoid marketing-style layouts, oversized cards, nested cards, and decorative UI inside the campaign workspace.
- Use custom dense list components first; add TanStack Table only when true table behavior is needed.

## Forms, Rich Text, And Media

- Use Zod and VeeValidate for client validation. Database constraints/RPC validation remain authoritative.
- Use Tiptap Vue 3 for rich text.
- Keep MVP rich text extensions narrow unless requirements expand.
- Use Supabase Storage public bucket files plus Postgres metadata for MVP images.
- Store image bucket/path, not public URLs, as source of truth.
- Generate `thumb_160` and `grid_480` variants client-side.
- Cropped variants must support a user-selected 3x3 crop anchor, default center.
- Warn users that MVP image files are public by URL.
- Keep original image retention optional and off by default.

## Search, Realtime, And Offline

- Use client-side search for instant navigation over already-loaded authorized data.
- Use Postgres/Supabase search for deep note/section body search.
- Do not add external search for MVP.
- Do not build realtime UX in MVP, but keep query keys and invalidation clean for future Supabase Realtime.
- Do not build offline/PWA support in MVP.

## Testing And Quality

- Use TypeScript strict mode, ESLint, and Prettier.
- Use Vitest, Vue Test Utils, and Playwright.
- Add Supabase migration/RLS/RPC smoke tests when schema work starts.
- CI is deferred; run local checks before considering work done.
- If tests cannot be run, state that clearly.

## Repo Rules

- Keep a single repo and single Nuxt app initially.
- Use top-level `app/`, `docs/`, `scripts/`, and `supabase/` folders.
- Do not convert to a monorepo unless explicitly requested.
- Use feature branches for meaningful work; keep `main` deployable.

## Deferred Unless Explicitly Promoted

- SSR
- ORM
- Vercel Functions or Edge Functions
- private media
- realtime collaboration
- offline sync/PWA
- product analytics
- external error monitoring
- custom transactional email provider
- feature flag service
- external search
- payments/billing
- native mobile
- Storybook
- runtime AI features
