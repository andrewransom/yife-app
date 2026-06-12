# Milestones 04-12 Summary Report

## Scope

Detailed implementation plans were written for roadmap milestones 04 through 12:

- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/05-notes-sections-rich-text-and-mentions.md`
- `docs/dev/milestones/06-role-aware-visibility-and-player-gm-views.md`
- `docs/dev/milestones/07-relationships-timeline-and-context-panels.md`
- `docs/dev/milestones/08-sessions-quests-encounters-plot-arcs-and-activity.md`
- `docs/dev/milestones/09-parties-characters-resources-funds-and-currencies.md`
- `docs/dev/milestones/10-media-and-image-workflow.md`
- `docs/dev/milestones/11-workbench-layouts-command-palette-and-shortcuts.md`
- `docs/dev/milestones/12-settings-invitations-delete-restore-and-mvp-hardening.md`

Each milestone received two q-review-plan passes. The review corrections are recorded in each milestone's `Review Notes` section.

## Major Decisions Made

- M04 implements typed creation for all MVP entity types, but only shallow detail shells. Rich text editing waits for M05.
- M04 owns the base `entity_sections` table if M02/M04 implementation has not already created it.
- M05 uses RPC-backed rich text saves with version checks, derived text, and mention rebuilds.
- M05 keeps mention targets to campaign entities only. Notes are not mention targets in MVP.
- M06 keeps author-private content author-only, including from owners/GMs who are not the author.
- M07 keeps structural links in typed columns and exposes related records through a union read surface.
- M07 limits explicit relationship management to owners/GMs for MVP.
- M08 uses derived recent activity, not an append-only audit/event table.
- M09 keeps funds/resources lightweight: balances/resources only, no ledger or inventory system.
- M10 prioritizes campaign, character, NPC, and location primary images. Profile avatar upload remains deferred.
- M11 uses a fixed shortcut set: `Mod+K`, `/`, `N`, `E`, `Alt+W`, `Alt+[`, `Alt+]`, `Mod+\`.
- M12 makes membership security owner-only for MVP. GMs manage workflow data only where specific feature permissions allow it.

## Key Compromises

- Funds/resources visibility: the current content model has no per-row visibility field, so M09 inherits owner entity visibility. Sensitive resource/fund details should live in protected notes/sections unless row-level visibility is promoted.
- Invitation delivery: M12 avoids a custom transactional email provider. If Supabase defaults are insufficient, MVP should use a copyable invite flow before adding a vendor.
- Activity: M08 derived activity is not an audit log. It is for orientation and must avoid hidden-label leakage.
- Media privacy: M10 keeps public bucket files. The app protects metadata and associations, but files are public by URL.
- Mobile: M12 uses simplified role-aware mobile navigation, not desktop saved-layout parity.

## Items To Manually Confirm Before Implementation

- M09: whether funds/resources inheriting owner visibility is acceptable for MVP.
- M11: whether the fixed shortcut chords conflict with Andrew's browser/workflow habits.
- M12: whether owner-only membership security is the desired MVP policy.
- M12: whether copyable invite links are acceptable if Supabase built-in email is not enough.
- M10: Safari/mobile camera upload behavior, HEIC handling, WebP/JPEG fallback, and EXIF orientation.

## Residual Risks

- Safe read surfaces are central. Implementation must resist shortcutting through raw table reads, especially for NPC real status, GM-only sections, private notes, media metadata, relationship visibility, and activity labels.
- Layout JSON needs strict schema/version validation so corrupt or oversized layout state cannot break the workspace.
- Reference resolution must avoid enumeration leaks: arbitrary hidden ids should resolve to coarse unavailable states.
- Public media remains a real privacy tradeoff. Upload UI copy must stay near every upload control.
- Invitation acceptance depends on reliable normalized email from authenticated identity, not caller-provided values.

## Verification Expectation

Before implementation starts on each milestone, rerun a focused plan review against the then-current code and schema. The current milestone docs are implementation-ready planning artifacts, but manual verification of each milestone is still expected before coding, especially for visibility, RLS, and browser behavior.
