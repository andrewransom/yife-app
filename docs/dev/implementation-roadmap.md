# Yife High-Level Implementation Roadmap

This roadmap sequences MVP development for Yife.app using the requirements, technology stack, and content model design in:

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`

The roadmap is intentionally high level. Each milestone gets its own numbered implementation plan with goals, steps, technical details, manual steps, success criteria, review findings, and open decisions.

## Sequencing Principles

- Build foundations before feature surfaces.
- Put Supabase RLS, views, and RPC boundaries in place before relying on client route guards.
- Deliver thin vertical slices before broad entity coverage.
- Keep the authenticated campaign workspace dense and role-aware from the beginning.
- Defer paid vendors, runtime AI, realtime, offline, external search, CI, Storybook, and custom taxonomies unless explicitly promoted.

## Milestones

### 01. Project Foundation

Create the Nuxt 4 SPA application foundation, local developer tooling, project scripts, Tailwind/Nuxt UI setup, design tokens, app shell conventions, and dev-only component workbench route.

This milestone makes the repo ready for repeatable app implementation without introducing database schema.

### 02. Supabase Core Schema And Security Foundation

Create the local Supabase foundation: migrations, generated types workflow, system seed data, core campaign/member/profile tables, entity registry tables, status/option/relationship lookup tables, helper functions, and first RLS policies.

This milestone establishes campaign membership as the primary data boundary.

### 03. Auth, Campaign Home, And Campaign Creation

Implement Supabase Auth integration, public landing entry points, authenticated home, user profile defaults, campaign creation, owner membership creation, campaign switching, and initial campaign summary reads.

This milestone creates the first usable authenticated vertical slice.

### 04. Entity Creation And Directory Baseline

Implement typed entity creation RPCs, default entity sections, campaign entity summaries, reusable dense directory/list components, and first entity detail shells for core entity types.

This milestone proves the hybrid entity model in the UI.

### 05. Notes, Sections, Rich Text, And Mentions

Implement notes, note attachments, entity sections, contribution feeds, Tiptap editor integration, optimistic concurrency RPCs, derived text, entity mention extraction, backlinks, and placeholder-safe mention rendering.

This milestone establishes long-form campaign knowledge capture.

### 06. Role-Aware Visibility And Player/GM Views

Harden role-aware read surfaces, mixed-visibility entity details, NPC real/apparent status separation, private notes, GM-only sections, player contributions, and inaccessible/deleted placeholders.

This milestone makes visibility behavior trustworthy enough for mixed GM/player use.

### 07. Relationships, Timeline, And Context Panels

Implement explicit relationships, structural related-record views, relationship visibility, timeline events, backlinks, right contextual panel widgets, and related-record display across entity details.

This milestone turns isolated records into navigable campaign knowledge.

### 08. Sessions, Quests, Encounters, Plot Arcs, And Activity

Build the session workflow, quest log, lightweight encounters, plot arcs, attendance, role-aware recent activity, session note surfaces, and session-oriented context.

This milestone supports preparation and post-session campaign maintenance.

### 09. Parties, Characters, Resources, Funds, And Currencies

Implement character assignment, parties, party membership, party/character-owned funds, resources, campaign currency definitions, and currency customization UI.

This milestone covers party-management requirements without expanding into full inventory/accounting.

### 10. Media And Image Workflow

Implement Supabase Storage public bucket usage, media metadata, client-side variant generation, 3x3 crop anchor selection, primary images for campaigns/characters/NPCs/locations, and public-media warnings.

This milestone adds visual identity and dense-list thumbnails.

### 11. Workbench Layouts, Command Palette, And Shortcuts

Implement desktop workbench regions/zones/widgets, saved layouts, open tabs, pins, current-session context, layout drafts, command palette, quick create, and fixed keyboard shortcuts.

This milestone creates the intended dense power-user workflow.

### 12. Settings, Invitations, Delete/Restore, And MVP Hardening

Complete settings scope separation, campaign invitations, membership management, soft delete/restore/empty trash, attention cues, mobile simplification, accessibility pass, browser tests, and deployment readiness.

This milestone closes MVP product gaps and prepares the app for real campaign use.

## Deferred Beyond MVP

- SSR for the authenticated app.
- ORM adoption.
- Vercel Functions or Edge Functions.
- Private media.
- Realtime collaboration.
- Offline/PWA support.
- Runtime AI features.
- Product analytics.
- External monitoring.
- Custom transactional email provider.
- Feature flag service.
- External search.
- Payments/billing.
- Native mobile.
- Storybook.
- Full audit history or revision snapshots.
- Import/export.
- Advanced relationship graph visualization.
- Full active-session combat tooling.
