# Yife.app Requirements

## Purpose

Yife.app is a responsive web application for managing tabletop roleplaying game campaigns. It should help a single user run campaigns as a Game Master and participate in campaigns as a player, with campaign information organized around characters, sessions, quests, NPCs, locations, factions, plot arcs, encounters, timeline events, and notes.

The initial product should prioritize structured campaign knowledge management over live automation. The app should make it fast to capture, browse, cross-reference, and update campaign information before and after play sessions, with lightweight note-taking support during sessions.

Yife should be system-agnostic in its core model, with D&D-friendly defaults where helpful. Generic TTRPG terms should be preferred unless a specific rules-system feature is intentionally added.

## Product Goals

- Let users create and own campaigns.
- Let campaign owners invite other users to participate by email.
- Let users participate in campaigns as players, Game Masters, or both.
- Keep campaign information organized under one campaign container.
- Provide different capabilities and visibility depending on whether the user is acting as a player or Game Master.
- Support dense, efficient workflows suitable for use during a game session.
- Provide reusable entity patterns, especially shared notes across multiple entity types.
- Support light and dark themes.

## Non-Goals For Initial Requirements

- Full virtual tabletop functionality.
- Character-sheet rules automation.
- Dice rolling automation.
- Encounter combat tracking.
- AI-generated campaign content.
- Mobile native apps.
- Public campaign publishing.
- Marketplace or shared content library.
- Complex subscription or billing flows.

These may be revisited later, but they should not define the initial requirements unless explicitly promoted into MVP scope.

## Target Users

### Solo Developer / Primary User

The first target user is the product owner using the app to manage campaigns. Requirements should assume fast iteration, pragmatic defaults, and low operational overhead.

### Game Master

A Game Master owns or helps run a campaign. They manage world information, NPCs, sessions, plot arcs, encounters, hidden notes, quest details, and player participation.

### Player

A player participates in a campaign through one or more player characters. They need access to shared campaign information, their character details, session notes, NPC directories, quests, party information, and player-visible notes.

## Core Concepts

### Common Entity Requirements

Most campaign entities should share common display and referencing behavior.

Requirements:

- Major campaign records should share a stable cross-system campaign entity identity.
- Major campaign entity types should include characters, NPCs, parties, factions, locations, quests, sessions, plot arcs, encounters, and timeline events.
- Notes are first-class records, but they are not campaign entities.
- Entity types should be configurable/data-driven by the app, with seeded system entity types for MVP.
- Campaign entities should have a `ListCaption` field.
- `ListCaption` should default sensibly from the entity's primary name, title, or equivalent label.
- Users should be able to edit `ListCaption`.
- Lists, pickers, relationship controls, and inline reference suggestions should display `ListCaption` as the primary user-facing label.
- Entity reference UI may include secondary context in addition to `ListCaption` when needed to distinguish similar records.
- Campaign entities should support archiving and soft deletion where appropriate.
- Normal campaign views should exclude soft-deleted entities.
- Deleted or inaccessible entity references should degrade gracefully rather than breaking layouts, relationships, mentions, pins, or tabs.

### User

A registered person using the app. A user is distinct from a character.

Requirements:

- A user must be able to create an account.
- A user must be able to sign in and sign out.
- A user must have a profile suitable for display in campaign membership and session attendance.
- A user may own campaigns.
- A user may be invited to campaigns.
- A user may be a member of multiple campaigns.
- A user may own or play multiple characters across campaigns.

### Campaign

The top-level container for most app data.

Requirements:

- A user must be able to create a campaign.
- A campaign must have an owner.
- A campaign must support multiple members.
- A campaign must support members with different roles.
- A campaign must include:
  - Name.
  - Description.
  - Campaign photo or image.
  - Start date.
  - End date, optional while active.
  - Status, such as planned, active, paused, completed, or archived.
- A campaign must contain related entities, including characters, NPCs, parties, factions, locations, quests, sessions, plot arcs, encounters, timeline events, and notes.
- A campaign must provide different views and capabilities for Game Masters and players.

### Campaign Membership

Membership defines who can access a campaign and what they can do.

Requirements:

- A campaign owner must be able to invite users by email.
- An invited user must be able to accept or decline an invitation.
- A campaign owner must be able to view pending invitations.
- A campaign owner must be able to remove campaign members.
- Duplicate active invitations to the same campaign and email should be prevented or handled cleanly.
- Invitations may expire or be revoked.
- Accepting an invitation must create the correct campaign membership and assigned roles together.
- A campaign member must have one or more roles.
- Initial roles should include:
  - Owner.
  - Game Master.
  - Player.
- A user may act as both Game Master and player in the same campaign.
- A campaign may have multiple Game Masters.
- Game Master-only visibility must be granted to any member with the Game Master role.
- Campaign ownership is canonical on the campaign record.
- The owner should also have owner role membership for permission and UI consistency.

### Character

A player character in a campaign.

Requirements:

- A campaign must support multiple player characters.
- A character must belong to exactly one campaign.
- A character is created by a Game Master and assigned to one controlling user.
- A character should include:
  - Name.
  - Notes.
  - Backstory.
  - Status.
  - Player or controlling user.
  - Optional portrait/image.
- A player must be able to view characters in campaigns they belong to.
- A player must be able to manage their own characters, subject to campaign permissions.
- A Game Master must be able to view and manage campaign characters.
- Temporary session-by-session handling of an absent player's character does not change character ownership in MVP.

### NPC

A non-player character in a campaign.

Requirements:

- A campaign must support an NPC directory.
- An NPC should include:
  - Name.
  - Description.
  - Apparent status, such as alive, dead, missing, unknown, or inactive.
  - Real status, such as alive, dead, missing, unknown, or inactive.
  - Relationship to the party or characters.
  - Faction association.
  - Notes.
  - Optional image.
  - Optional Game Master-only stat block.
- NPC data must support player-visible and Game Master-only information.
- NPC records should support separate canonical Game Master-managed details, private Game Master-only details, and player-contributed details.
- Game Master-managed details may include core description, image, motivations, secrets, stat blocks, and authoritative campaign information.
- Player-contributed details may include notes, nicknames, theories, relationship impressions, and other player-maintained observations.
- Real status is Game Master-only.
- Apparent status is player-visible.
- Apparent status should default to real status when real status is changed, unless the Game Master intentionally overrides apparent status.
- Game Masters must be able to create, update, archive, and delete NPCs.
- Players must be able to view player-visible NPC information and contribute to player-editable fields where permitted.

### Party

A group of characters within a campaign.

Requirements:

- A campaign may contain one or more parties.
- A party should include:
  - Name.
  - Member characters.
  - Notes.
  - Party resources.
  - Party funds.
- Party funds and resources should be available to players and Game Masters unless marked otherwise.
- The app should not assume every campaign has only one party.
- Party funds and resources are in MVP as simple shared campaign-management records.
- MVP party funds/resources should track what the party has, not provide full accounting, item rarity rules, encumbrance, or audit history.
- Initial funds and resources should be owned by parties or characters.
- Currency definitions should be campaign-specific.
- New campaigns should auto-seed D&D-friendly default currencies in MVP.
- Gold should be the standard currency in the default currency set.
- Currency customization UI is included in MVP.
- Fund balances should represent owner-only balances and should not track holder or custodian history in MVP.
- Resources should distinguish between the owner/controller and the optional current holder.
- A party-owned resource held by a character should be representable.
- Resource value should use the campaign's standard-currency equivalent.
- Resource descriptions should remain simple in MVP. Substantial resource notes or attachments are post-MVP.

### Faction

An in-world group that may include NPCs, player characters, or other entities.

Requirements:

- A campaign must support factions.
- A faction should include:
  - Name.
  - Description.
  - Notes.
  - Relationship to party.
  - Known members.
  - Optional parent faction.
  - Optional status.
- Faction information must support player-visible and Game Master-only details.

### Location

A place in the campaign world. Locations may form a loose hierarchy.

Requirements:

- A campaign must support locations.
- A location should include:
  - Name.
  - Location type.
  - Description.
  - Notes.
  - Parent location.
  - Status.
  - Optional image or map.
- A location may belong inside another location.
- The location hierarchy should be flexible and not require every location to have a parent.
- Location information must support player-visible and Game Master-only details.
- Location type should use a seeded option list with default options.
- Default location types should include world, continent, country, region, town, city, wilderness area, district, landmark, building, room, dungeon, plane, and other.

### Timeline Event

A dated event in campaign history, world history, or campaign play.

Requirements:

- A campaign must support timeline events.
- Timeline events should describe historical events in the campaign world and more granular events that occur during the campaign.
- A timeline event should include:
  - Title.
  - ListCaption.
  - Date expression.
  - Optional sort key.
  - Event type.
  - Description.
  - Notes.
  - Visibility.
  - Related session, optional.
  - Related entities.
- Timeline events may link to sessions when they represent events that occurred during play.
- Timeline events may link to characters, NPCs, parties, factions, locations, quests, sessions, plot arcs, encounters, notes, and other timeline events.
- Timeline events are manually created in MVP.
- Timeline events may optionally be linked to sessions.
- MVP does not require automatic timeline event generation from sessions or other records.
- Future enhancements may include creating a timeline event from a session.
- Future AI-assisted enhancements may derive suggested timeline events from session notes or other campaign text.
- Timeline dates should use a human-readable freeform date expression.
- Timeline events should support an optional sort key for chronological ordering when the date expression is not directly sortable.
- MVP does not require a custom fantasy calendar engine.
- Timeline event type should use a seeded option list with default options.
- Default timeline event types should include world history, campaign event, session event, character event, faction event, location event, quest event, omen/prophecy, and other.
- Timeline events should support shared, Game Master-only, and private visibility.
- Shared timeline events are player-visible.
- Game Master-only timeline events are visible to campaign members with the Game Master role.
- Private timeline events are visible only to their author.
- Timeline events should be searchable and filterable.

### Quest

A task, objective, mystery, or open thread for the campaign.

Requirements:

- A campaign must support a quest log.
- A quest should include:
  - Title.
  - Description.
  - Status.
  - Priority or importance.
  - Major/minor classification.
  - Parent quest.
  - Related NPCs.
  - Related locations.
  - Related factions.
  - Related sessions.
  - Notes.
- Quests may be hierarchical.
- Players must have a player-facing quest log.
- Game Masters must have access to additional private quest information.
- Quest statuses should support at least open, in progress, completed, failed, abandoned, and hidden.

### Session

A gameplay session in a campaign.

Requirements:

- A campaign must support multiple sessions.
- A session should include:
  - Date.
  - Title.
  - Attending players.
  - Attending characters.
  - Notes.
  - Summary.
  - Related quests.
  - Related NPCs.
  - Related locations.
  - Related encounters.
- Game Masters must be able to create and update sessions.
- Players should be able to view sessions visible to them.
- The app should support note-taking before, during, and after a session.
- Session attendance should track attending users and attending characters as separate facts.
- The app should not assume that every attending user maps directly to one attending character.
- The app should support cases where a character is present while the controlling user is absent.

### Plot Arc

A Game Master-facing container for organizing campaign planning.

Requirements:

- A campaign must support plot arcs.
- A plot arc should include:
  - Title.
  - Description.
  - Status.
  - Related quests.
  - Related NPCs.
  - Related locations.
  - Related encounters.
  - Notes.
- Plot arcs are Game Master-only by default.
- Plot arcs may be used to group campaign planning information without exposing it to players.

### Encounter

A planned gameplay situation, including roleplaying, exploration, or combat.

Requirements:

- A campaign must support encounters.
- An encounter should include:
  - Title.
  - Type, such as roleplay, exploration, combat, puzzle, travel, or mixed.
  - Description.
  - Status.
  - Related session.
  - Related plot arc.
  - Related NPCs.
  - Related locations.
  - Notes.
- Encounters are Game Master-only by default.
- Encounter records may include player-visible outcomes after they occur.

### Note

A reusable note attached to one or more parts of the system.

Requirements:

- The app should use a shared notes model rather than separate note systems for every entity.
- A note must include:
  - Author.
  - Body.
  - Body preview.
  - Created date.
  - Updated date.
  - Visibility.
- A note must be attachable to supported entity types.
- Supported note targets should include campaigns, characters, NPCs, parties, factions, locations, quests, sessions, plot arcs, encounters, and timeline events.
- Notes may be attached to more than one entity.
- Notes should be discoverable from attached entities and from backlinks.
- Notes should support shared, Game Master-only, and private visibility.
- Users should be able to create, edit, and delete notes according to permissions.
- Notes should support soft delete.
- Notes should display through a common notes component wherever attached entities are shown.
- Shared notes are visible to campaign members who can view the attached entity.
- Game Master-only notes are visible to campaign members with the Game Master role.
- Private notes are visible only to their author.
- Notes and long-form entity text should support rich text editing in MVP.
- Rich text should support inline references to other campaign entities using an `@` mention-style interaction.
- Inline entity references should create durable links to the referenced entity, not only plain text.
- Notes should protect against stale overwrites when the same note has changed since the user began editing.

### Entity Sections

Reusable sections hold substantial long-form content for campaign entities.

Requirements:

- Substantial prose should live in entity sections rather than type-specific structured fields.
- Entity sections should support rich text content.
- Entity sections should include derived plain text and preview text for search, summaries, and dense list display.
- Entity sections should support visibility and edit policy controls.
- Entity sections should protect against stale overwrites when the same section has changed since the user began editing.
- MVP should seed default section definitions per entity type.
- Section definitions may vary by entity type, but the permission model should remain consistent.
- Typical sections should include:
  - Player-facing summaries.
  - Canonical descriptions.
  - Game Master-private details.
  - Player observations or contributions.
  - Backstories.
  - Session summaries.
  - Quest details.
  - Location descriptions.
  - Encounter notes.
- Example NPC sections should include player summary, Game Master details, and player observations.
- Example quest sections should include player summary, Game Master details, and player observations.
- Example session sections should include summary, Game Master prep, and Game Master private notes.
- Custom section definition UI is post-MVP.

## Cross-Entity Relationships

The app should let users connect campaign entities without duplicating information.

Requirements:

- A quest may reference NPCs, locations, factions, sessions, plot arcs, timeline events, and notes.
- An NPC may reference factions, locations, quests, sessions, encounters, timeline events, and notes.
- A location may reference NPCs, factions, quests, sessions, encounters, timeline events, and notes.
- A session may reference attendees, quests, NPCs, locations, encounters, timeline events, and notes.
- A plot arc may reference quests, NPCs, locations, encounters, timeline events, and notes.
- An encounter may reference NPCs, locations, quests, plot arcs, sessions, timeline events, and notes.
- A timeline event may reference characters, NPCs, parties, factions, locations, quests, sessions, plot arcs, encounters, notes, and other timeline events.
- Relationship display should be bidirectional where useful; for example, an NPC page should show related quests, and a quest page should show related NPCs.
- Rich text references should contribute to entity relationships where practical.
- Related-record UI should combine explicit relationships, structural links, and rich text mentions where useful.
- Structural links should include typed relationships such as parent locations, parent quests, parent factions, encounter-session links, encounter-plot-arc links, and timeline-event session links.
- Structural links should not be treated as user-managed explicit relationships.
- Related-record UI should be able to distinguish whether a related record came from an explicit relationship, structural link, or mention.
- Users should be able to reference campaign entities inline from rich text fields, such as notes, descriptions, summaries, and planning text.
- Inline rich text references should create durable links and backlinks.
- A referenced entity should be able to show where it is mentioned, such as notes, sessions, quests, or other rich text content.
- Inline `@` references target campaign entities only in MVP.
- Inline `@` references do not target notes in MVP.
- Mention indexes should be rebuildable from the rich text source content.
- Inline references do not require users to classify the relationship type.
- Explicit typed relationships between entities are a separate feature from inline rich text references.
- Users should be able to create and manage explicit relationships between entities independently of rich text mentions.
- MVP should support explicit typed relationships using a seeded system type list.
- Custom relationship types are not required in MVP.
- Relationship types should be configurable/data-driven by the app, with seeded system relationship types for MVP.
- Campaign-scoped custom relationship types should remain possible later.
- Explicit relationship types may be directional or undirected.
- Relationship type defaults should determine whether direction matters, so users do not need to configure direction for every relationship.
- Explicit relationships should support relationship-level visibility.
- MVP relationship visibility options should be shared and Game Master-only.
- Game Master-only relationships must not be visible to players even when both related entities are player-visible.

Initial explicit relationship types should include:

- Related to.
- Ally of.
- Enemy of.
- Member of.
- Leader of.
- Located in.
- Owns.
- Works for.
- Seeks.
- Protects.
- Threatens.
- Created by.
- Parent of.
- Child of.

## Visibility And Permissions

Information visibility is central to the app.

Requirements:

- Campaign access must be restricted to campaign members.
- Campaign owners must have full access to their campaigns.
- Game Masters must be able to access Game Master-only information.
- Players must not be able to access Game Master-only information.
- Game Master-only information should be explicit, not inferred from entity type alone.
- Some entities may be Game Master-only by default, including plot arcs and encounters.
- Some fields may be Game Master-only, including NPC stat blocks and private quest details.
- Some fields or sections may be player-visible but Game Master-editable only.
- Some fields or sections may be player-visible and player-editable.
- Some fields or sections may be player-contributed, such as NPC nicknames, observations, and theories.
- Some notes may be Game Master-only even when attached to player-visible entities.
- Some notes may be private to their author.
- The UI must clearly indicate when information is private to Game Masters.
- The UI must distinguish authoritative Game Master-maintained information from player-contributed information.
- Entity screens should distinguish Game Master canon, player-visible canon, and player-authored knowledge.
- Game Master canon is authoritative campaign truth visible and editable by Game Masters. It may include spoilers, secrets, true statuses, motivations, hidden relationships, prep notes, and future plans.
- Player-visible canon is authoritative information the Game Master has exposed to players and should be treated as shared campaign truth players can rely on.
- Player-authored knowledge includes observations, theories, nicknames, reminders, and notes contributed by players.
- Player-authored knowledge should be attributed and visually distinct from Game Master-confirmed truth.
- Players should not see Game Master canon unless it has been explicitly exposed.
- Game Masters should be able to promote or copy player-authored knowledge into player-visible canon where useful.
- Player-facing or mixed-visibility record reads must avoid exposing Game Master-only structured fields.
- Sensitive creative content should live in protected sections where practical.
- Some structured Game Master-only fields, such as NPC real status, may remain structured for workflow reasons, but must not be exposed in player-facing views.
- Permissions must be granular enough to support different visibility and editability within the same record.
- MVP permissions should use section-level visibility and editability, not arbitrary field-level rules.
- Common record sections should include:
  - Game Master private.
  - Canonical player-visible.
  - Player contributions.
- Section names and availability may vary by entity type, but the permission model should stay consistent.
- Player-editable information should use a hybrid model:
  - Shared player-editable fields for simple collaboratively maintained values, such as an NPC nickname.
  - Attributed player-contribution entries for observations, theories, reminders, and subjective details.
- The UI should keep Game Master canonical information visually distinct from player-maintained or player-authored information.

## Collaboration Requirements

MVP collaboration is asynchronous. Users can contribute to shared campaign data, but Yife should not behave like a live multiplayer editor yet.

Requirements:

- MVP should support asynchronous collaboration through normal create, edit, and save flows.
- MVP does not require live collaborative editing, live cursors, presence indicators, or real-time co-editing.
- MVP does not require player contribution approval workflows.
- Player contributions to allowed shared or player-contribution sections should be visible immediately.
- Player contributions should be attributed to the contributing user.
- Game Master-authored/canonical content and player-authored contributions should be visually distinct.
- Game Masters should be able to edit, remove, or moderate player contributions where permissions allow.
- Stale-save conflicts should be detected for notes and rich text sections.
- MVP conflict resolution may be simple: notify the user that content changed and require reload before saving.
- Future real-time or collaborative editing should remain possible without replacing the rich text model.

## Primary User Flows

### View Public Landing Page

Requirements:

- An unauthenticated visitor should see a public landing page.
- The public landing page should provide a concise, pleasing introduction to Yife and what the app is for.
- The public landing page should describe Yife as a campaign knowledge-management tool for tabletop roleplaying games.
- The public landing page should provide sign-in and account creation entry points.
- The public landing page should not expose the authenticated campaign navigation shell.
- The public landing page should not imply that the user is working inside a specific campaign.

### View Authenticated Home

Requirements:

- A signed-in user who is not currently inside a campaign should see an authenticated home page.
- The authenticated home page should show the user's campaigns as large cards.
- Each campaign card should show useful summary information, such as campaign name, image, description, role, status, and recent or next session where available.
- Clicking a campaign card should open that campaign's main workbench layout.
- The authenticated home page should provide a clear create-campaign action.
- The authenticated home page should provide access to global user settings.
- The authenticated home page should not show the full campaign workbench shell until a campaign is selected.

### Create A Campaign

Requirements:

- A signed-in user can create a campaign.
- The creator becomes the campaign owner.
- The creator can enter required campaign details.
- The creator can upload or choose a campaign image.
- The creator can invite members by email.
- The creator can start with empty campaign directories.

### Invite Campaign Members

Requirements:

- A campaign owner can invite a user by email.
- The invitee receives an invitation.
- The invitation is linked to the campaign.
- The invitee can accept and become a campaign member.
- The invitee can decline.
- The owner can revoke a pending invite.
- Duplicate pending invites to the same email and campaign should be prevented or handled cleanly.

### Switch Campaign Context

Requirements:

- A user with multiple campaigns can view and switch between them.
- The selected campaign should drive all primary navigation.
- The app should make the current campaign obvious at all times.

### View Campaign Overview

Requirements:

- Each campaign should have an overview view available from campaign navigation.
- The campaign overview should be the default in-campaign landing view.
- The overview should help users orient quickly before using directories, search, or saved workbench layouts.
- The overview should respect role and visibility rules.
- The overview should show campaign basics, including name, image, description, status, user role, and current or next session where available.
- Game Master overview content should emphasize prep and management context, such as upcoming or recent sessions, open quests, recently changed records, pinned or important records, and quick create actions.
- Player overview content should emphasize player-facing context, such as assigned character, party information, current or recent session, visible open quests, known NPCs or locations, and recent visible updates.
- MVP overview can be fixed and role-aware. It does not need deep customization.
- The overview should reuse workbench, list, and detail components where practical.

### Use Player Campaign View

Requirements:

- A player can view player-visible campaign information.
- A player can browse quests, NPCs, party information, locations, sessions, characters, and notes.
- A player can add notes where allowed.
- A player can contribute to player-editable sections of shared records where allowed.
- A player can edit their own character information where allowed.
- A player cannot access Game Master-only data.

### Use Game Master Campaign View

Requirements:

- A Game Master can manage all campaign entities.
- A Game Master can see private and player-visible information.
- A Game Master can create planning entities such as plot arcs and encounters.
- A Game Master can decide what information is visible to players.
- A Game Master can manage campaign members and attendance where allowed.

### Take Session Notes

Requirements:

- A user can open a session record and write notes.
- Notes can be attached to the session.
- Notes can also be attached to related entities where appropriate.
- A Game Master can keep private session notes.
- A player can keep shared or private notes according to note visibility rules.

### New Member Experience

Requirements:

- MVP does not require dedicated new-member or player onboarding flows.
- Newly accepted members may land on the normal authenticated campaign experience.
- Campaign overview, assigned character visibility, party/session/quest access, and normal navigation should be sufficient for MVP.
- Dedicated onboarding, tutorials, guided setup, and first-login checklists are post-MVP unless promoted.

## User Interface Requirements

### General UI

Requirements:

- The app must be responsive.
- The app should support desktop-first dense information layouts.
- The app must remain usable on mobile.
- Desktop/larger-screen UX should optimize for making campaign information accessible with minimal clicks.
- The design should use high information density.
- Spacing should be compact.
- Rounded corners should be minimal or absent.
- Primary actions should use small icon buttons when the action is familiar.
- Icon buttons must provide descriptive tooltips.
- Complex entities should reuse common components where possible.
- The app must support light and dark themes.

### Desktop Workbench Layout

Requirements:

- Desktop/larger-screen layouts should use a constrained customizable workbench model.
- The major workbench regions should include:
  - Top navigation/action area.
  - Left sidebar/list area.
  - Central main detail area.
  - Collapsible right contextual panel.
- Users should be able to configure which widgets appear in configurable regions.
- Users should be able to save named layouts.
- Saved layouts are per campaign per user in MVP.
- MVP should provide three Game Master default layout modes and two player default layouts.
- Default layouts should include:
  - Game Master campaign development / writing prep.
  - Game Master session prep.
  - Game Master active session placeholder.
  - Player overview.
  - Player session.
- Game Master active session mode is a placeholder in MVP. Full active-session tools are deferred.
- Game Master campaign development / writing prep should prioritize entity-directory access, including NPCs, locations, factions, quests, plot arcs, encounters, timeline, and relationships.
- Game Master session prep should prioritize recent activity, timeline, sessions, encounters, notes, and relevant campaign context.
- Game Master active session placeholder should reserve space for future initiative, encounter, stat block, and key player-character information tools.
- Player overview should prioritize broad campaign lookup, including quests, NPCs, locations, party, notes, and relationships.
- Player session should prioritize current or recent session context, session notes, party information, quests, timeline, and related entities.
- Session-oriented layouts should support a current-session context.
- The current session should default to the nearest upcoming session, falling back to the most recent completed session.
- Users should be able to manually override the current session for a layout.
- Desktop regions and zones should be resizable.
- Resized widths and heights should persist as part of the saved layout.
- Layouts should enforce sensible minimum and maximum sizes so users cannot easily create unusable layouts.

### Zones And Widgets

Requirements:

- A configurable region may contain one or more zones.
- Each zone may contain one or more widgets as tabs.
- Supported MVP widgets should include entity lists, notes, relationships, backlinks, timeline, search results, and entity detail where appropriate.
- Users should be able to choose which widgets appear in a zone.
- Users should be able to split predefined side regions into stacked zones.
- MVP should not require arbitrary nested split panes.
- MVP should not require a fully freeform dashboard builder.
- A UI element, such as a session list or quest list, should be injectable into an allowed zone as a widget.
- Widget state should respect campaign context, selected entity context, role, and visibility permissions.
- Widgets should support basic configurable context modes where relevant.
- MVP widget context modes may include:
  - All records for the current campaign.
  - Records related to the selected entity.
  - Records related to the current session.
  - Pinned records.
  - Recent records.
- MVP should not require query-builder-style widget configuration.

### Main Zone

Requirements:

- The central main zone should show entity-specific detail.
- The main zone should support multiple open entity tabs.
- Selecting an entity from a list zone should open or select an entity tab in the main zone.
- If the selected entity is already open in a main tab, the existing tab should be selected instead of opening a duplicate.
- Users should be able to close entity tabs.
- Open main tabs and the selected tab should persist as part of saved layout state.
- Deleted or inaccessible entities should degrade gracefully when restoring tabs.

### Right Context Panel

Requirements:

- The right panel should be collapsible.
- The right panel should default to contextual widgets for the selected entity.
- Contextual widgets should include notes, explicit relationships, backlinks, and related records.
- Users should be able to pin a widget or specific entity context where useful.
- Pinned right-panel content should not prevent users from returning the panel to selected-entity context.

### Layout Persistence

Requirements:

- Saved layouts should include:
  - Region structure.
  - Zone structure.
  - Widget/tab assignments.
  - Region and zone sizes.
  - Collapsed panel state.
  - Open main entity tabs.
  - Selected main tab.
  - Pinned entities.
- MVP saved layouts should not persist transient filter text or search text.
- Saved layouts should be associated with a user and campaign.
- Layouts should remain valid when campaign data changes, including when entities are deleted, hidden, or no longer accessible.
- Saved layouts should support pinned entities in MVP.
- Pinned entities are per layout.
- Pinned entities should help users keep important session or campaign references close at hand.
- Deleted, hidden, or inaccessible pinned entities should degrade gracefully.

### Fast Access

Requirements:

- MVP should include a command palette / quick switcher.
- The command palette should be available from authenticated areas.
- The command palette should have a visible trigger in the top navigation and a keyboard shortcut.
- The command palette should support:
  - Searching entities by `ListCaption`.
  - Opening entities.
  - Creating common records.
  - Context-aware quick create.
  - Switching campaigns.
  - Switching saved layouts.
  - Jumping to major navigation areas.
- The command palette should scope results to the active campaign by default when the user is inside a campaign.
- Entity search results should default to the active campaign when the user is inside a campaign.
- Campaign switching, global navigation, and global user actions should remain available as separate result groups.
- The command palette should allow campaign switching from any authenticated area.
- The command palette should support grouped result categories, such as entities, actions, navigation, layouts, and campaigns.
- The command palette should show result metadata sufficient to distinguish similarly named records, such as entity type, status, and parent/location context where useful.
- Command palette result rows should show compact metadata rather than a separate preview pane in MVP.
- Useful result metadata may include entity type, status, parent location, faction, visibility marker, and relationship to current context.
- MVP does not require a command palette preview/details pane.
- Selecting an entity result from within a campaign should open or select that entity in the main zone.
- Selecting a create action should use context-aware quick create where context exists.
- The command palette should support keyboard-first interaction.
- Normal command palette search should work without prefixes.
- The command palette should support optional power-user prefixes in MVP.
- Optional prefixes may include:
  - `>` for actions.
  - `@` for entities.
  - `/` for navigation.
  - `+` for create actions.
- Command palette ranking should be deterministic and weighted.
- Ranking should prioritize exact matches, prefix matches, recent entities, pinned entities, selected/current-session context, and current layout relevance where useful.
- MVP does not require user-trained or AI-ranked command palette results.
- Command palette results should respect campaign membership, role, and visibility permissions.
- MVP should include a small fixed keyboard shortcut set.
- MVP keyboard shortcuts should include:
  - Open command palette.
  - Create new note.
  - Create new entity.
  - Focus search.
  - Close current tab.
  - Switch main tabs.
  - Toggle right panel.
- MVP does not require user-customizable keyboard shortcuts.

### Quick Create

Requirements:

- MVP should support context-aware quick create for common records.
- Quick create should use available context to prefill safe defaults.
- Available context may include:
  - Current campaign.
  - Selected entity.
  - Current session.
  - Active layout.
  - Active widget.
- Quick create should support creating notes attached to the selected entity.
- Quick create should support creating records linked to the current session where relevant, such as encounters, notes, or timeline events.
- Quick create must respect role, permissions, and visibility rules.
- MVP does not require full inline creation everywhere.

### Mobile Layout

Requirements:

- Mobile should use a simplified role-aware layout rather than attempting to reproduce desktop saved layouts.
- Mobile should provide campaign navigation, entity lists, entity detail, notes, relationships, and timeline access through stacked views, tabs, or drawers.
- Desktop saved layouts do not need to apply to mobile in MVP.
- Mobile should remain usable, but desktop/larger-screen UX is the primary optimization target for MVP.

### Navigation

Requirements:

- Navigation should have two distinct modes:
  - Public unauthenticated navigation for the landing page.
  - Authenticated app navigation for home and campaign workspaces.
- The unauthenticated landing page should use simple public navigation and should not expose the campaign workbench shell.
- Authenticated home should provide global app navigation, user settings access, and campaign selection.
- Authenticated campaign workspaces should use a campaign-specific navigation shell.
- The campaign should be the main navigation context.
- Users should be able to switch between campaigns.
- Campaign switching should be available from authenticated app navigation and the command palette.
- Top-level authenticated campaign navigation should include:
  - Current campaign identity.
  - Campaign switcher.
  - Current layout selector.
  - Compact directories menu.
  - Command palette trigger.
  - Quick create trigger.
  - User/settings menu.
  - Role/view indicator.
- Top-level campaign navigation should remain compact and should not compete with the workbench zones.
- The directories menu should provide discoverable access to core campaign directories, such as overview, sessions, quests, characters, NPCs, locations, factions, parties, timeline, and notes.
- The directories menu should show Game Master-only directories, such as plot arcs and encounters, only to users with the Game Master role.
- Selecting a directory should focus an existing matching widget when visible.
- If no matching widget is visible, selecting a directory should open the directory in a sensible location, such as the main zone or an appropriate list zone.
- The directories menu is a discoverability and fallback navigation tool, not the primary power-user workflow.
- Campaign-level navigation should expose core directories such as overview, sessions, quests, characters, NPCs, locations, factions, parties, timeline, and notes.
- Game Master-only navigation should expose plot arcs and encounters.
- The UI should make role/view mode clear.

### Directory Browsing

Requirements:

- Each major campaign entity type should have a directory or list view.
- Directory views should respect role and visibility rules.
- Directory views should use `ListCaption` as the primary label.
- Directory views should support basic filtering and sorting appropriate to the entity type.
- Default directory filters should favor active or relevant records and hide archived or deleted records unless the user chooses otherwise.
- Common filters should include status, type or category where available, related session where relevant, and visibility where permitted.
- Common sorting should include name or `ListCaption`, recently updated, status, relevant date, and manual/default order where useful.
- Directories should support quick open into the main entity detail view.
- Directory list components should be reusable in workbench zones and navigation fallback views.
- MVP does not require saved custom directory views.

### Reusable Components

Requirements:

- Notes should use a common notes component.
- Entity relationship pickers should be reusable.
- Entity list/detail layouts should be consistent.
- Entity lists, pickers, and reference suggestions should use `ListCaption` as the primary display label.
- Image upload/display patterns should be reusable.
- Visibility controls should be reusable.
- Status controls should be reusable where entity statuses exist.
- Rich text editing should be reusable across notes and long-form entity fields.
- Entity reference autocomplete should be reusable across rich text fields.

### Rich Text Editing

Requirements:

- MVP should include a rich text editor for notes and long-form campaign content.
- Rich text source content should be stored in a durable editor document format.
- Derived plain text and preview text should be maintained for rich text content to support search, summaries, and compact previews.
- The editor should support common formatting such as headings, paragraphs, bold, italic, lists, links, and block quotes.
- The editor should support inline `@` references to campaign entities.
- Entity references should display enough context to distinguish similarly named records.
- Entity references must respect campaign membership and visibility permissions.
- Broken or inaccessible references should degrade gracefully in the UI.
- Stale rich text saves should be rejected rather than silently overwriting newer content.
- MVP conflict handling may be simple: tell the user the content changed elsewhere and require reload before saving.
- MVP does not require live collaborative rich text editing.
- Rich text editing should be architected so real-time collaboration can be added later without replacing the editor or stored content model.
- MVP does not require comments, suggestions, track changes, or document-style revision history.

### Themes

Requirements:

- The app must provide a light theme.
- The app must provide a dark theme.
- Theme choice should persist for a user.
- Theme styling should support dense tables, lists, sidebars, and forms.

## Media Requirements

Requirements:

- Campaigns should support a representative image.
- Characters, NPCs, and locations may support images.
- Uploaded images should have alt text where user-facing.
- Uploaded media should track useful metadata such as MIME type, width, and height when available.
- Image storage should support thumbnail display in dense lists.
- The app should avoid large original images in normal list views.
- Campaigns, characters, NPCs, and locations should support primary images for fast list and picker display.
- Generic media attachments to entities, notes, or sections are optional/post-MVP unless promoted.
- MVP images may be stored and served publicly to simplify processing, thumbnail delivery, caching, and cost.
- Image metadata and image associations remain protected by campaign access rules inside the app.
- Users should understand that anyone with a public image URL may be able to access that image.

## Search And Filtering

Requirements:

- Users should be able to search within a campaign.
- MVP search should cover loaded campaign entity summaries and key derived text where available.
- The app should maintain lightweight campaign entity summaries for app-state hydration, command palette search, open tabs, pinned entities, recent records, and dense list widgets.
- Entity summaries should include enough display metadata for fast navigation, such as entity type, `ListCaption`, status, primary image, relevant date, parent entity, related session, update date, and deleted state where useful.
- Derived plain text from notes and entity sections should be preserved to support search and future deep search.
- Entity lists should support filtering by status.
- Quest lists should support filtering by status and importance.
- NPC lists should support filtering by status, relationship, and faction.
- Session lists should support filtering by date.
- Timeline event lists should support filtering by date/date expression, event type, related session, and related entity.
- Search results must respect campaign membership and visibility permissions.
- Deep search, full-text search, and semantic/vector search are post-MVP unless promoted.

## Recent Activity

Recent activity gives users a lightweight way to see what changed in a campaign without requiring full audit history.

Requirements:

- The app should provide a recent campaign activity view or widget.
- Recent activity should respect campaign membership, role, and visibility rules.
- Activity should include meaningful user-facing changes, such as created records, updated records, new notes, updated sections, changed statuses, new relationships, and uploaded media.
- Activity should show who made the change and when, where that information is available.
- Activity should link back to the changed record.
- Player activity views should only show changes the player is allowed to know about.
- Game Master activity views may show Game Master-only changes.
- MVP activity does not need full field-by-field diffs.
- MVP activity does not need immutable audit-log guarantees.
- Activity can be derived from normal record metadata and summary data in MVP.

## Auditability And History

Initial requirements do not mandate full change history. However:

- Records should track creation and update dates.
- Records should track authorship or creator where useful.
- Notes must track author, created date, and updated date.
- User-editable records should track created-by and updated-by users where practical.
- Notes and entity sections should track version numbers or equivalent stale-save protection.
- Future support for revision history should not be made impossible by early data choices.
- Full audit history and historical content snapshots are post-MVP.

## Attention Cue Requirements

MVP should avoid a full notification system while still providing local in-app cues for states that need user attention.

Requirements:

- MVP does not require email notifications, push notifications, notification inboxes, or full notification preferences.
- The app should provide in-app attention cues for important immediate states.
- MVP attention cues should include:
  - Pending campaign invitations.
  - Stale-save conflicts.
  - Unsaved layout changes.
  - Inaccessible, private, or deleted record placeholders.
  - Failed saves.
  - Failed uploads.
  - Permission-denied actions.
- Attention cues should appear in the relevant context rather than requiring a global notification center.
- Attention cues should respect role and visibility rules.
- Future notification support should not be blocked by MVP data choices.

## Delete And Restore Requirements

Requirements:

- Campaign entities should soft delete by default.
- Soft-deleted entities should be hidden from normal lists, search results, pickers, and workbench views.
- Soft delete should preserve typed details, sections, notes, relationships, resources, mentions, and layout references until hard delete.
- Users should be able to restore soft-deleted entities where permitted.
- Related-record UI may show deleted, hidden, or inaccessible placeholders where useful.
- Campaign owners should be able to permanently delete soft-deleted entities through an empty-trash action.
- Empty trash should require confirmation.
- Permanent deletion should cascade dependent data where appropriate.
- Normal active views should prioritize active, open, planned, in-progress, or otherwise current records.
- Completed, resolved, inactive, retired, failed, abandoned, skipped, or archived records should remain available for browsing and search unless deleted or hidden by visibility rules.
- Archived records should be hidden from default active lists but available through explicit filters.
- Restorable deleted records should be available only through a trash/restore flow for users with permission.
- Hard-deleted records are permanently unavailable.
- Record lifecycle state should not override visibility rules. A Game Master-only archived record remains Game Master-only.
- Lifecycle filters should be consistent across directories, widgets, command palette, and relationship pickers where practical.
- MVP does not require complex lifecycle automation.

## Placeholder Requirements

Because Yife has granular visibility and durable references, inaccessible records should degrade clearly instead of producing broken links or generic errors.

Requirements:

- References to deleted, private, Game Master-only, or otherwise inaccessible records should show clear placeholder states.
- Placeholders should avoid leaking private information to unauthorized users.
- A player who cannot access a referenced record should see a generic unavailable or private placeholder.
- A Game Master or authorized user may see more specific placeholder context, such as deleted, archived, or inaccessible due to role.
- Placeholders should appear consistently in rich text mentions, backlinks, relationships, open tabs, pinned entities, recent activity, command palette results, and saved layouts where relevant.
- If a record was soft-deleted, users with restore permission should have an appropriate restore path.
- Hard-deleted records should remain unavailable and should not break surrounding content.
- Placeholder text should be brief and action-oriented where action is possible.

## Data Requirements

The following data groups are required:

- Users.
- Campaigns.
- Campaign memberships.
- Campaign membership roles.
- Campaign invitations.
- Entity types.
- Characters.
- NPCs.
- Parties.
- Party resources.
- Party funds.
- Campaign currency definitions.
- Factions.
- Locations.
- Quests.
- Sessions.
- Plot arcs.
- Encounters.
- Timeline events.
- Entity sections.
- Entity section definitions.
- Notes.
- Note attachments.
- Entity relationships.
- Relationship types.
- Status definitions.
- Option definitions.
- Media assets.
- Session attending users.
- Session attending characters.
- Campaign entity summaries.

## Status Requirements

MVP should use seeded default statuses per record type. The product should not require custom status management in MVP, but the requirements should allow custom labels or status sets to be added later.

Statuses should be configurable/data-driven by the app, with seeded system statuses for MVP. Campaign-scoped custom statuses should remain possible later, but custom status management UI is post-MVP.

Default statuses:

- Campaign: planned, active, paused, completed, archived.
- Character: active, inactive, dead, retired, missing.
- NPC apparent status and real status: alive, dead, missing, unknown, inactive.
- Quest: open, in progress, completed, failed, abandoned, hidden.
- Session: planned, completed, cancelled.
- Plot arc: planned, active, resolved, abandoned, hidden.
- Encounter: planned, ready, completed, skipped, archived.

## Option List Requirements

Small option lists should be configurable/data-driven by the app, with seeded system defaults for MVP.

Requirements:

- Option lists should support location types, timeline event types, encounter types, quest priority or importance, and similar small lists.
- MVP should provide seeded defaults for required option lists.
- Campaign-scoped custom option values should remain possible later.
- MVP customization UI is required only for campaign currencies.
- Customization UI for location types, timeline event types, encounter types, quest priority/importance, and other non-currency option lists is post-MVP unless promoted.

## Settings Requirements

Settings should be scoped deliberately so personal preferences, campaign rules, and per-campaign workspace state do not blur together.

### User Settings

User settings apply to a user across the whole app.

Requirements:

- User settings should include:
  - Display name.
  - Profile image/avatar.
  - Email/account management entry points.
  - Theme preference.
  - Default landing behavior after sign-in.
  - Default campaign, optional.
  - Accessibility preferences where supported.
  - Notification preferences where notifications exist.
- User settings should not contain campaign-specific layout state.
- User settings should be editable by the signed-in user.

### Campaign Settings

Campaign settings apply to all users within a campaign and are controlled by campaign owners and Game Masters.

Requirements:

- Campaign settings should include:
  - Campaign name.
  - Description.
  - Campaign image.
  - Start date.
  - End date.
  - Campaign status.
  - Campaign membership and invitations.
  - Role assignments.
  - Default visibility preferences for new campaign content by entity type.
  - Seeded option lists for location types, timeline event types, encounter types, and quest priority/importance.
  - Campaign currency definitions.
  - Seeded relationship type list and relationship direction defaults.
  - Default layout availability by role.
  - Campaign-level image/public media policy notice.
- Campaign settings should expose currency customization in MVP.
- Campaign settings may display seeded non-currency option lists in MVP, but editing those lists is post-MVP.
- MVP does not require global reusable user defaults for open lists.
- Campaign settings should expose the seeded system relationship type list as configurable only if custom relationship types are promoted later.
- Campaign settings should allow default visibility to be configured per entity type.
- New records should use the campaign's default visibility for their entity type unless the user overrides it.
- Section-level visibility remains controlled on the record and should not require campaign-wide section default matrices in MVP.
- Campaign settings should not include personal user layout state.
- Campaign settings changes must respect role and permission rules.
- Campaign owners and Game Masters can edit campaign-wide settings in MVP.

### Campaign Member Settings

Campaign member settings apply to a specific user's membership in a campaign.

Requirements:

- Campaign member settings should include:
  - Campaign roles.
  - Assigned player character or characters.
  - Member display state within the campaign, if different from global profile display.
  - Membership status.
  - Invitation status where applicable.
- Campaign owners or authorized Game Masters should manage member roles and assignments.
- Individual users may be able to manage limited membership preferences that do not affect permissions.

### User-Campaign Workspace Settings

User-campaign workspace settings apply to one user in one campaign.

Requirements:

- User-campaign workspace settings should include:
  - Saved layouts.
  - Active selected layout.
  - Region and zone sizes.
  - Widget assignments.
  - Widget tab order.
  - Collapsed panel state.
  - Open main entity tabs.
  - Selected main tab.
  - Pinned entities.
  - Current-session override.
  - Last selected campaign view or route.
  - Recent entities.
- User-campaign workspace settings should not change campaign data visible to other users.
- Recent entities should persist per user-campaign.
- Recent entities are personal workspace state, not shared campaign data.
- Users should be able to reset a saved layout to its default.
- Users should be able to duplicate, rename, and delete custom saved layouts.
- Users should be able to restore default role-based layouts.
- Structural layout edits should use draft changes with explicit save, discard, or reset.
- The UI should provide a subtle visual indicator when the current layout has unsaved structural changes.
- Clicking the unsaved layout indicator should prompt the user to save, discard, or continue editing.
- Low-risk workspace state, such as recent entities, selected tab, and current route, may auto-save.
- Deleted, hidden, or inaccessible entities referenced by workspace settings should degrade gracefully.

### Settings UI

Requirements:

- The app should provide a settings area with clear scope separation.
- Settings UI should distinguish:
  - User settings.
  - Campaign settings.
  - Campaign members.
  - Personal workspace/layout settings for the current campaign.
- Users should not need to understand database scopes to know who a setting affects.
- Settings that affect all campaign members should be clearly labeled as campaign-wide.
- Settings that affect only the current user should be clearly labeled as personal.
- Campaign settings should be accessible from the current campaign context.
- User settings should be accessible globally.
- Layout settings should be manageable from the workbench and from the settings area.
- Settings should have one coherent settings area with scoped sections or tabs.
- The app should provide contextual entry points into the settings area.
- Contextual settings entry points should include:
  - Global user menu to user settings.
  - Campaign menu to campaign settings.
  - Workbench controls to layout/workspace settings.
  - Member list to campaign member settings.
- Contextual settings entry points should open the relevant settings section directly.
- Dangerous or broad-impact settings should require confirmation.
- Settings UI should respect permissions and hide or disable controls the user cannot change.

### Settings Defaults And Reset

Requirements:

- New users should receive sensible user defaults.
- New campaigns should receive sensible campaign defaults.
- New campaign memberships should receive role-appropriate workspace defaults.
- Default role-based layouts should be available for restoration.
- Reset actions should explain what will be reset and what will be preserved.

## Platform Constraints

The app will use:

- Supabase backend.
- Vue front end.
- Pinia for front-end state management.

Hosting is likely Vercel but is not a product requirement.

## Security Requirements

- Users must authenticate before accessing private campaign data.
- Campaign data must be isolated by campaign membership.
- Player users must not be able to access Game Master-only data.
- Invitation acceptance must not grant access to the wrong campaign.
- Email invites must not expose private campaign information unnecessarily.
- Uploaded media metadata and associations must respect campaign visibility decisions.
- MVP uploaded image files may be public by URL; private image storage is not required for MVP.
- Deleting or removing a member must prevent future access to campaign data.

## Accessibility Requirements

- Icon-only controls must have accessible labels.
- Tooltips must not be the only accessible name for a control.
- Keyboard navigation should support primary workflows.
- Text contrast must be sufficient in light and dark themes.
- Dense layouts must still preserve readable font sizes.

## MVP Scope Proposal

The first complete MVP should optimize for campaign knowledge management. Session support should exist for organizing session records and notes, but live-session automation should not drive the initial scope.

The first complete MVP should include:

- Authentication.
- Public unauthenticated landing page.
- Authenticated campaign home page.
- Campaign creation and campaign switching.
- Campaign membership and email invitations.
- Campaign roles: owner, Game Master, player.
- Campaign overview.
- Recent campaign activity.
- Directory browsing and grouping.
- Characters.
- NPC directory.
- Quest log.
- Sessions.
- Locations.
- Factions.
- Parties.
- Simple party funds and resources.
- Campaign currency customization.
- Shared notes system.
- Seeded entity sections for long-form entity content.
- Soft delete and restore for campaign entities.
- Deleted/private/inaccessible placeholders.
- In-app attention cues for immediate states.
- Asynchronous collaboration boundaries.
- Rich text editing with inline entity references.
- Desktop customizable workbench layouts.
- Per-campaign saved layouts.
- Main entity tabs.
- Command palette / quick switcher.
- Fixed MVP keyboard shortcut set.
- Player-visible vs Game Master-only visibility.
- Basic search and filtering.
- Campaign image upload.
- Light and dark themes.
- Plot arcs.
- Lightweight encounters.
- Timeline events.
- User settings.
- Campaign settings.
- Campaign member settings.
- User-campaign workspace settings.

The following should be considered post-MVP unless promoted:

- Advanced party inventory or accounting.
- Rich stat block handling.
- Advanced rich text collaboration features.
- Advanced relationship graph visualization.
- Deep search, full-text search, and semantic/vector search.
- Full audit history.
- Historical content snapshots.
- Import/export.
- AI assistance.
- AI-assisted timeline extraction from session notes.
- Dedicated new-member onboarding flows.
- Full notification system.
- Real-time collaborative editing.
- Offline support.
- Fully freeform dashboard builder.
- Arbitrary nested split panes.
- Custom keyboard shortcuts.
- Desktop layout parity on mobile.
- Full Game Master active-session tooling.
- Custom status taxonomy management.
- Custom relationship type management.
- Custom section definition UI.
- Custom non-currency option list management.
- Global reusable taxonomy defaults.

## Settled Decisions

The following decisions were settled during requirements review.

### MVP Product Shape

Decision: campaign knowledge management first, with lightweight session notes included. Live-session automation is post-MVP unless explicitly promoted later.

### Role Model

Decision: campaign members may have multiple roles. MVP roles are owner, Game Master, and player. A user may be both Game Master and player in the same campaign, and campaigns may have multiple Game Masters.

### Character Ownership

Decision: Game Masters create campaign characters and assign each character to one controlling user. Players may manage assigned characters according to campaign permissions. Temporary handling of an absent player's character during a session does not change ownership in MVP.

### Notes Visibility

Decision: notes support three visibility modes in MVP: shared, Game Master-only, and private. Shared notes are visible to campaign members who can view the attached entity. Game Master-only notes are visible to GMs. Private notes are visible only to their author.

### Player Editing Rights

Decision: shared records may contain a mix of Game Master-only, Game Master-maintained player-visible, and player-editable sections. Players can help maintain directories through explicitly player-editable fields and contributions, while Game Masters retain control of canonical and private information. Player-editable sections use a hybrid model: simple shared fields where appropriate, plus attributed player contributions for observations, theories, and subjective details.

### Entity Visibility Model

Decision: MVP uses section-level permissions. Records can include Game Master private sections, canonical player-visible sections, and player-contribution sections. The app should not require arbitrary field-level permissions in MVP.

### Party Scope

Decision: party tracking is required in MVP, including simple party funds and resources. Funds and resources initially belong to parties or characters. Currency customization is MVP, with D&D-friendly defaults and gold as the standard default currency. This should not become full inventory, encumbrance, or accounting in MVP.

### Plot Arc And Encounter Scope

Decision: plot arcs and encounters are MVP features. Encounters should be lightweight planning records in MVP, not tactical combat management or full live encounter automation.

### Rules System Support

Decision: Yife is system-agnostic with D&D-friendly defaults. Core requirements should use generic TTRPG concepts while allowing D&D-friendly labels, statuses, and optional fields where useful.

### Status Taxonomy

Decision: MVP uses seeded system statuses per record type. Custom status labels or custom status sets are deferred, but should remain possible later.

### Images And Privacy

Decision: MVP image files may be public for simpler and cheaper processing/serving. Campaign metadata and app access remain private. Private media storage may be revisited later if needed.

### Import / Export

Decision: import and export are not required in MVP. They may be considered later, but should not shape the first build.

### Real-Time Collaboration

Decision: MVP does not require real-time collaboration UX. Normal saved records and refresh/reload behavior are acceptable. The data and front-end state model should remain compatible with future Supabase Realtime support.

Future real-time support should be possible for:

- New or updated notes.
- New or updated campaign records.
- Presence indicators.
- Conflict-aware editing flows.

MVP does not need:

- Live collaborative rich-text editing.
- Presence indicators.
- Real-time conflict resolution.
- Real-time updates across all views.

### Text Content Format

Decision: MVP uses rich text editing for notes and long-form campaign content. Rich text should support inline `@` references to campaign entities. This app is also a proving ground for rich text editing patterns that may transfer to a future business app, so rich text is an explicit MVP requirement despite added complexity.

### Entity References

Decision: inline `@` entity references should create durable links and backlinks to campaign entities. They do not target notes in MVP and do not need explicit relationship typing. Explicit typed relationships between entities are a separate feature set.

### Explicit Relationship Types

Decision: MVP includes explicit typed relationships with a seeded system type list. Campaign-scoped custom relationship labels are deferred.

### Relationship Direction

Decision: explicit relationships may be directional or undirected depending on relationship type. Type defaults should determine direction behavior.

### Relationship Visibility

Decision: explicit relationships support relationship-level visibility in MVP. Visibility options are shared and Game Master-only.

### NPC Status Visibility

Decision: NPCs have both apparent status and real status. Real status is Game Master-only. Apparent status is player-visible and defaults to real status when real status changes, unless the Game Master intentionally overrides it.

### Location Types

Decision: locations have a seeded location type list with defaults such as world, continent, country, region, town, city, wilderness area, district, landmark, building, room, dungeon, plane, and other. Editing non-currency option lists is post-MVP unless promoted.

### Timeline

Decision: timeline events are an MVP feature. They support world history and campaign events, can link to sessions, and can relate to other campaign entities.

### Timeline Dating

Decision: timeline events use a human-readable freeform date expression plus an optional sort key for chronological ordering. MVP does not require a custom campaign calendar engine.

### Timeline Event Types

Decision: timeline event type uses a seeded option list with defaults. Default types include world history, campaign event, session event, character event, faction event, location event, quest event, omen/prophecy, and other. Editing non-currency option lists is post-MVP unless promoted.

### Timeline Event Visibility

Decision: timeline events support shared, Game Master-only, and private visibility. Shared events are player-visible.

### Timeline Event Creation

Decision: timeline events are manually created in MVP and may optionally link to sessions. Future enhancements may include creating timeline events from sessions and AI-derived suggested events from session notes.

### ListCaption

Decision: campaign entities have editable `ListCaption` values. Lists, pickers, relationship controls, and inline reference suggestions use `ListCaption` as the primary display label.

### Layout Flexibility

Decision: MVP uses a constrained customizable workbench model rather than a fixed layout or fully freeform layout builder.

### Layout Scope

Decision: saved layouts are per campaign per user in MVP.

### Default Layouts

Decision: MVP provides three Game Master default layout modes and two player default layouts. Game Master defaults are campaign development / writing prep, session prep, and active session placeholder. Player defaults are player overview and player session. Full active-session tooling is deferred.

Game Master campaign development / writing prep prioritizes entity-directory access. Game Master session prep prioritizes recent activity, timeline, sessions, encounters, notes, and context. Player overview prioritizes broad campaign lookup. Player session prioritizes current or recent session context.

### Current Session Context

Decision: session-oriented layouts use a current-session context. The app defaults to the nearest upcoming session, then the most recent completed session, with manual user override.

### Zone Model

Decision: each zone can contain one or more widgets as tabs.

### Widget Context

Decision: widgets support basic context modes in MVP, such as all campaign records, selected-entity related, current-session related, pinned, and recent. Query-builder-style widget configuration is deferred.

### Zone Placement

Decision: users can split predefined side regions into stacked zones. MVP does not require arbitrary nested splitting.

### Resizing Behavior

Decision: MVP supports region and zone resizing. Saved layouts persist region and zone sizes.

### Right Panel Purpose

Decision: the right panel is contextual to the selected entity by default, with support for pinned widgets or pinned entity context.

### Main Zone Behavior

Decision: the main zone supports multiple open entity tabs.

### Selection Model

Decision: selecting an entity from a list zone opens or selects an entity tab in the main zone. Existing entity tabs are deduplicated.

### Search / Quick Access

Decision: MVP includes a command palette / quick switcher as the primary fast-access mechanism.

### Command Palette Scope

Decision: the command palette supports entity search, opening entities, common create actions, context-aware quick create, campaign switching, layout switching, and major navigation. Inside a campaign, entity search defaults to the active campaign while campaign switching, global navigation, and global user actions remain available as separate groups.

### Command Palette Modes

Decision: normal command palette search works without prefixes. MVP also supports optional power-user prefixes such as `>` for actions, `@` for entities, `/` for navigation, and `+` for create actions.

### Command Palette Ranking

Decision: command palette results use deterministic weighted ranking. Ranking should prioritize exact matches, prefix matches, recent entities, pinned entities, selected/current-session context, and current layout relevance where useful. User-trained or AI-ranked palette results are not required in MVP.

### Command Palette Result Detail

Decision: MVP command palette uses compact metadata in result rows rather than a separate preview/details pane.

### Public Landing Page

Decision: unauthenticated users see a public landing page with a concise introduction to Yife and sign-in/account creation entry points. The public landing page does not expose the authenticated campaign navigation shell.

### Authenticated Home

Decision: authenticated users who are not inside a campaign see a campaign home page with large campaign cards, campaign summaries, global user settings access, and a create-campaign action. Selecting a campaign opens its main workbench layout.

### Top-Level Navigation

Decision: navigation has distinct public, authenticated home, and authenticated campaign workspace modes. Campaign workspace navigation is compact and includes campaign identity/switcher, layout selector, compact directories menu, command palette trigger, quick create, user/settings menu, and role/view indicator.

### Directories Menu

Decision: campaign workspace top nav includes a compact directories menu for discoverability and fallback navigation. Selecting a directory focuses a visible matching widget when possible, or opens the directory in a sensible location.

### Keyboard Shortcuts

Decision: MVP includes a small fixed keyboard shortcut set. Custom keyboard shortcuts are deferred.

### Quick Create

Decision: MVP includes context-aware quick create. It uses current campaign, selected entity, current session, active layout, and active widget context to prefill safe defaults where relevant.

### Layout Persistence

Decision: saved layouts persist structure, widgets, sizes, collapsed state, open main tabs, selected main tab, and pinned entities. MVP does not persist transient filter/search text.

### Layout Save Behavior

Decision: structural layout edits use draft changes with explicit save, discard, or reset. A subtle visual indicator shows when a layout has unsaved structural changes and opens a save/discard prompt. Low-risk workspace state may auto-save.

### Pinned Entities

Decision: saved layouts support pinned entities in MVP. Pins are per layout and degrade gracefully when entities are deleted, hidden, or inaccessible.

### Mobile UX

Decision: mobile uses a simplified role-aware layout. Desktop saved layouts do not need to apply to mobile in MVP.

### Settings Scopes

Decision: MVP settings are organized into user settings, campaign settings, campaign member settings, and user-campaign workspace settings.

### User Settings

Decision: user settings store global personal preferences and profile details, including theme preference and optional default campaign. User settings do not store campaign-specific layout state.

### Campaign Settings

Decision: campaign settings store campaign-wide configuration such as campaign details, membership, role assignments, default visibility preferences by entity type, seeded option lists, campaign currency definitions, and media policy notice. Campaign owners and Game Masters can edit campaign-wide settings in MVP. Currency customization is MVP; non-currency option-list editing is post-MVP unless promoted.

### Default Visibility Settings

Decision: default visibility is configurable per entity type. New records use the entity-type default unless overridden. Campaign-wide section-level default matrices are not required in MVP.

### Open List Ownership

Decision: option lists use seeded system defaults in MVP, with future campaign-scoped customization allowed by the model. MVP customization UI is required only for currencies. Global reusable user defaults for open lists are deferred.

### Campaign Member Settings

Decision: campaign member settings store role assignments, character assignments, membership status, and limited member-specific campaign preferences.

### User-Campaign Workspace Settings

Decision: user-campaign workspace settings store per-user per-campaign workbench state, including saved layouts, active layout, zone/widget configuration, sizes, open tabs, selected tab, pinned entities, current-session override, and persisted recent entities.

### Recent Entities

Decision: recent entities persist per user-campaign as personal workspace state.

### Settings UI

Decision: settings UI must make scope clear: global user settings, campaign-wide settings, campaign member settings, and personal workspace/layout settings for the current campaign. MVP uses one coherent settings area with contextual entry points from the user menu, campaign menu, workbench controls, and member list.

### Campaign Overview

Decision: each campaign has a role-aware overview as the default in-campaign landing view. It orients users with campaign basics, current or next session context, recent activity, and role-relevant records/actions. MVP overview can be fixed and does not need deep customization.

### Recent Campaign Activity

Decision: MVP includes lightweight recent campaign activity. It respects visibility rules, links to changed records, and can be derived from normal metadata and summaries. It does not require full diffs or immutable audit-log guarantees.

### New Member Onboarding

Decision: dedicated new-member and player onboarding flows are deferred. Newly accepted members can use the normal authenticated campaign experience, campaign overview, and standard navigation.

### Directory Browsing

Decision: major entity types have directory/list views with basic filtering and sorting. Defaults favor active/relevant records, hide archived/deleted records, and reuse list components in workbench zones where practical. Saved custom directory views are not MVP.

### Record Lifecycle

Decision: archived/completed/inactive records remain browseable or searchable but are hidden from default active views where appropriate. Soft-deleted records are hidden from normal views and only available through restore/trash flows. Lifecycle state never overrides visibility rules.

### Notifications And Attention Cues

Decision: MVP does not include a full notification system. It uses local in-app attention cues for pending invitations, stale saves, unsaved layouts, inaccessible/deleted placeholders, failed saves/uploads, and permission-denied actions.

### Collaboration Boundary

Decision: MVP collaboration is asynchronous. Player contributions to allowed shared/player-contribution sections are immediately visible and attributed. No live co-editing, presence, or approval workflow is required in MVP.

### Knowledge Model

Decision: Yife distinguishes Game Master canon, player-visible canon, and player-authored knowledge. Player-authored knowledge is attributed and visually distinct from GM-confirmed truth. GMs can promote or copy player-authored knowledge into player-visible canon where useful.

### Inaccessible Placeholders

Decision: deleted, private, Game Master-only, and inaccessible references show clear placeholders instead of broken links or generic errors. Placeholders avoid leaking private information and offer actions only when the user has permission.

## Recommended Requirement Principles

- Make campaign membership and visibility rules explicit early.
- Keep records structured, but allow notes everywhere.
- Treat Game Master-only information as a first-class product requirement.
- Do not overbuild rules automation until the campaign knowledge workflows are proven.
- Keep MVP dense and functional rather than decorative.
- Design entity relationships to support future linking and search.
- Prefer reusable list/detail/note/visibility patterns across entity types.
