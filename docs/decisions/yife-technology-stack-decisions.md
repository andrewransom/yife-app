# Yife Technology Stack Decisions

This file records the settled technology stack decisions from the initial stack design session.

Implementation guidance lives in `docs/dev/yife-tech-stack.md`.

## 1. Frontend Framework

Decision: Use Nuxt 4 with Vue 3 and TypeScript.

Decision: Run Nuxt in SPA mode with `ssr: false`.

Rationale: Yife is primarily an authenticated, client-heavy campaign workbench. Nuxt provides useful structure while disabling SSR avoids auth, hydration, and server/client boundary complications during MVP.

## 2. Hosting

Decision: Use Vercel Hobby for hosting.

Decision: Early workflow is local dev/test, then deploy live when ready. Vercel previews are deferred as a regular workflow.

Rationale: Vercel gives useful deployment experience and good Nuxt support. The app should avoid Vercel Functions unless a concrete need appears.

## 3. Backend

Decision: Use Supabase-first backend architecture.

Included services:

- Supabase Postgres
- Supabase Auth
- Supabase Storage
- RLS
- RPCs
- views
- generated TypeScript database types

Rationale: Existing Yife data model decisions already assume Supabase and PostgreSQL. Supabase keeps the MVP low-cost and keeps permissions close to the data.

## 4. Database And Query Layer

Decision: Use Supabase SQL migrations, generated TypeScript types, and `supabase-js`.

Decision: Do not use Prisma, Drizzle, Kysely, or another ORM for MVP.

Rationale: Yife relies heavily on RLS, views, and RPCs. An ORM would add abstraction without solving the hard permission and transactional problems.

## 5. Supabase Local Development

Decision: Use Supabase local development for schema, migrations, RLS, views, and RPCs.

Decision: Use one remote free Supabase project for MVP deployments until separate environments are justified.

Decision: Required seed data covers system defaults only.

Rationale: Local migrations keep database work repeatable and safer for AI-assisted development. One remote project minimizes cost and environment overhead.

## 6. App/API Boundary

Decision: Use Supabase RPCs and views for data-critical logic.

Decision: Use Nuxt client code and composables for UI orchestration.

Rationale: Multi-table writes, version checks, visibility-safe reads, and role-sensitive behavior belong close to Postgres/RLS.

## 7. Nuxt Supabase Integration

Decision: Use `@nuxtjs/supabase` plus Yife-owned wrappers and query/mutation composables.

Decision: Components must not call Supabase directly.

Rationale: The module provides Nuxt integration, while wrappers preserve app-level consistency and prevent scattered data access.

## 8. State Management

Decision: Use TanStack Query Vue for server content and server-state cache.

Decision: Use Pinia for shared app/UI state.

Decision: Do not duplicate server content in both TanStack Query and Pinia.

Rationale: TanStack Query handles fetched data, mutation state, caching, optimistic updates, and invalidation. Pinia remains focused on selected campaign, role/view mode, layout, tabs, and other app state.

## 9. UI Framework

Decision: Use Tailwind CSS and Nuxt UI.

Decision: Treat Nuxt UI as accessible primitives, with Yife wrapper components for repeated controls and dense app patterns.

Rationale: Tailwind supports compact UI well. Nuxt UI accelerates accessible component work, but Yife needs its own dense visual conventions.

## 10. Design Tokens

Decision: Use a small explicit design token source mapped into Tailwind and Nuxt UI configuration.

Rationale: Explicit tokens help maintain UI consistency and give AI agents clear constraints for future design work.

## 11. Icons

Decision: Use Lucide as the standard icon set.

Rationale: Lucide is broad, consistent, and well-suited to compact icon-button UI.

## 12. Forms And Validation

Decision: Use Zod and VeeValidate.

Rationale: Zod provides strong TypeScript-friendly schemas. VeeValidate is Vue-native. Client validation improves UX, while database constraints and RPC validation remain authoritative.

## 13. Rich Text

Decision: Use Tiptap Vue 3.

Decision: Keep MVP rich text extensions narrow.

Rationale: Tiptap aligns with the existing ProseMirror-style JSON storage decision and supports future entity mentions.

## 14. Auth

Decision: Use Supabase Auth with email/password and magic link.

Rationale: This is low-cost, native to Supabase, and compatible with RLS and invitation workflows.

## 15. Media And Images

Decision: Use Supabase Storage public bucket files, Postgres metadata, and client-generated variants.

Decision: Store bucket/path as source of truth and derive public URLs in the app.

Decision: Use campaign-scoped media metadata where relevant.

Decision: Keep original image retention optional and off by default.

Decision: Private media is deferred.

Decision: Cropped variant generation must support a user-selected 3x3 anchor point, defaulting to center.

Rationale: This approach minimizes cost, avoids paid image transformations, supports dense thumbnails, and remains upgradeable. Public images require explicit user warning because anyone with the URL can access the file.

## 16. Dense Lists And Tables

Decision: Build custom dense list components first.

Decision: Add TanStack Table only when a view needs true table behavior.

Rationale: Most Yife entity directories are dense application lists, not generic admin tables.

## 17. Search

Decision: Use client-side search for instant navigation over loaded authorized data.

Decision: Use Postgres/Supabase search for deeper body text and larger role-aware search results.

Decision: Do not use an external search service for MVP.

Rationale: Command palette and simple entity lookup should feel instant. Deep note/section search should remain permission-safe and database-backed.

## 18. Dates And Time

Decision: Use native JavaScript date handling and `Intl` initially.

Decision: Store timestamps in UTC with `Z` and convert to local time only for display.

Decision: Add `date-fns` only if date math becomes painful.

Rationale: MVP date needs are simple enough to avoid another dependency.

## 19. Notifications

Decision: Use Nuxt UI toasts through a Yife notification wrapper.

Rationale: This keeps notifications consistent while preserving the option to swap implementations later.

## 20. Route Protection

Decision: Use Nuxt route middleware for authenticated route UX.

Decision: Treat Supabase RLS, views, and RPCs as the real security boundary.

Rationale: In SPA mode, client route protection improves navigation but cannot protect data by itself.

## 21. Testing

Decision: Use Vitest, Vue Test Utils, and Playwright.

Decision: Add Supabase migration/RLS/RPC smoke tests when schema work starts.

Rationale: This covers unit, component, and browser-level behavior without relying only on manual testing.

## 22. Code Quality

Decision: Use TypeScript strict mode, ESLint, and Prettier.

Rationale: These are conventional, agent-friendly, and appropriate for Nuxt/Vue development.

## 23. Package Manager And Runtime

Decision: Use pnpm.

Decision: Use the current Vercel-supported Node.js LTS and pin it in project metadata.

Rationale: pnpm is fast, strict, and compatible with a future monorepo if needed.

## 24. Environment Management

Decision: Use local `.env`, Vercel environment variables, and committed `.env.example`.

Rationale: This is simple and low-cost. Supabase anon keys are public client configuration; RLS protects data.

## 25. Repo Structure

Decision: Use a single repo and single Nuxt app initially, with top-level `app/`, `docs/`, `scripts/`, and `supabase/` folders.

Decision: Do not start with a pnpm monorepo, but keep the repo monorepo-compatible.

Rationale: This avoids premature package boundaries while preserving an easy path to `apps/web` later.

## 26. Browser Support

Decision: Support modern evergreen browsers only.

Decision: Test Safari for image upload, canvas resizing, WebP, and mobile behavior.

Rationale: Old-browser support is not worth the MVP cost.

## 27. Accessibility

Decision: Use a pragmatic WCAG-minded baseline.

Decision: Do not claim formal compliance in MVP.

Rationale: The app should have accessible foundations without adding formal audit overhead yet.

## 28. Internationalization

Decision: English-only MVP with no i18n framework.

Rationale: This keeps iteration fast. Reusable labels may still be centralized where natural.

## 29. Realtime

Decision: No realtime UX in MVP.

Rationale: Realtime collaboration and live invalidation add complexity. The state model should remain compatible with future Supabase Realtime.

## 30. Offline And PWA

Decision: No offline/PWA support in MVP.

Rationale: Offline content sync would complicate auth, RLS expectations, mutations, and rich text conflict handling.

## 31. Analytics

Decision: No product analytics initially.

Rationale: Avoid cost, privacy, and extra vendor setup while the app is early and mostly single-user.

## 32. Error Monitoring

Decision: No external error monitoring initially.

Decision: Sentry free tier is the likely first upgrade once outside testers use the app.

Rationale: Avoid vendor setup until deployed browser error visibility becomes important.

## 33. Transactional Email

Decision: Use Supabase Auth built-in emails initially.

Decision: Defer Resend or another email provider until custom campaign invitation email UX is needed.

Rationale: Keeps MVP low-cost and simple.

## 34. Feature Flags

Decision: No feature flag service for MVP.

Decision: Use simple config/constants or environment-gated flags if needed.

Rationale: A flag service is unnecessary for solo MVP development.

## 35. CI

Decision: Use local scripts only initially.

Decision: Defer GitHub Actions until automated checks become worth the setup.

Rationale: Early solo workflow can rely on local checks. CI remains a likely later addition.

## 36. Git Workflow

Decision: Use feature branches for meaningful work and merge to `main` when ready.

Decision: No mandatory PR workflow initially.

Rationale: This keeps solo development lightweight while preserving safer checkpoints.

## 37. Component Workbench

Decision: Use a dev-only internal UI route instead of Storybook initially.

Rationale: This gives a lightweight place to develop Yife wrappers and dense UI states without Storybook configuration overhead.

## 38. AI Product Features

Decision: Design hooks only through data-model compatibility.

Decision: Do not add runtime AI dependencies, AI provider env vars, AI tables, or AI jobs in MVP.

Rationale: Future AI features benefit from clean rich text, body text, sections, relationships, and metadata. Runtime AI would add cost and scope before a product feature exists.

## 39. Deferred Areas

Decision: Defer the following unless explicitly promoted:

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

Rationale: These are not needed for the initial stack and would increase cost or implementation overhead.
