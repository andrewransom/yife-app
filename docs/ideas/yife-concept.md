# Concept Document for Yife.app

## Intro

I want to build a tool that's going to make it easy for me to both participate in and TTRPG (tabletop roleplaying games) like Dungeons & Dragons.

## Terminology

- TTRPG: tabletop roleplaying game
- GM: Game Master
- DM: Dungeon Master - use synonymously with GM
- D&D: Dungeons & Dragons TTRPG
- DnD: synonym for D&D

## Core Features


Users must be able to start their own campaigns and own them. They can also be members in a campaign. Each user can have one or more characters that they are playing in a campaign. Campaign owners can invite users to participate in a campaign that they own and run. Invitations will be done by email. 

### Key Entities

- User: user of the Yife app, different from character
- Campaign: umbrella entity for most features
- NPC: part of the 'dramatis personae' for campaign
- Character : player character owned by a User
- Party: a group of characters
  - Party Resources
  - Party funds
- Faction: an in-world group of characters, could be NPCs, or Characters
- Location: a ragged hierarchy of location. Can be part of a parent/broader location.
- Quest: a task for the player characters, can be major or minor, also hierarchical.
- Session: a gameplay session. 
- Plot Arc: a container for quests, npcs, locations, encounters, etc. For the GM
- Encounter: something planned by the game master, either roleplaying, exploration, or combat



---

Either a player or a game master can create a campaign. Campaigns should have:
- a name
- a description
- a photo that captures the essence of their campaign
- a start date
- an end date

Campaigns are the main container for both running and participating as players. Several of the information lists, including quest logs, NPC lists, sessions, etc., will have different views and capabilities depending on whether or not the user is using the app as a player or a game master. 

Each campaign can have multiple sessions. A session should include:
- a date
- a title
- a list of players who attended
- notes
We'll tack on a whole bunch of other features as we flesh this out.

Each campaign will have a list of characters
- name
- notes
- backstory

Each campaign will have an NPC directory
- name
- description
- status (alive, dead)
- relationship
- faction
- notes
- statblocks (GM-only)

Note on 'Notes': We'll have just one table of notes with a field that indicates to which entity or aspect of the system the note applies. Fields should include:
- Author
- the note
- create date
- update date

### Players

For players, each campaign will have:
- Quest Log: list of quests. 

### Game Masters



## App Design
This will be a responsive web app, With very high information density. Styling should factor that in with minimal padding and no rounded corners, etc. CTAs Should default to small icons with descriptive tool texts. 

Most of the UI components will be fairly simple, and I want them to be as reusable as possible. For example, if I am looking at a quest log, then any notes related to that can use a Common Notes component. The same would apply if I'm looking for notes on an NPC. 

Need a basic light and dark theme.


### Settings


## Tech Stack

WebApp: Vue+Pinia (for state). Need recommendation on CSS framework given info density.
Backend: supabase
Hosting: probably Vercel


-----

# ChatGPT Recommendation

## Recommended GM Tool Scope

Build the tool around **campaign memory, prep, live tracking, and selective sharing**, rather than rules automation or VTT features.

### Core Concepts

| Concept               | Purpose                                                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------- |
| **Campaign**          | Top-level container for everything                                                                       |
| **Sessions**          | Prep notes, live notes, recap, outcomes                                                                  |
| **NPCs**              | Characters with relationships, secrets, locations, and group memberships                                 |
| **Factions / Groups** | Organizations, villain groups, families, cults, governments, crews, guilds, or any collective with goals |
| **Locations**         | Places, regions, settlements, dungeons, shops, landmarks                                                 |
| **Quests / Threads**  | Active objectives, mysteries, unresolved promises, consequences                                          |
| **Items / Rewards**   | Important loot, artifacts, clues, favors, documents                                                      |
| **Handouts / Links**  | Player-facing files, map links, images, letters, props                                                   |
| **Player Characters** | Party info, backstory hooks, goals, relationships, spotlight notes                                       |

## Highest-Priority Features

### 1. Campaign Dashboard

A GM home screen showing:

* Current session
* Party location
* Active quests
* Important NPCs
* Relevant factions/groups
* Open threads
* Upcoming deadlines or consequences

### 2. Session Prep and Notes

Support a lightweight session workflow:

```text
Before session: prep outline, likely scenes, NPCs, locations, clues
During session: fast notes, decisions, improvised details
After session: recap, consequences, updated threads
```

Key feature: turn live notes into structured entries like NPCs, quests, locations, or faction updates.

### 3. NPC and Relationship Tracking

NPCs should track:

* Role
* Personality
* Secrets
* Goals
* Current location
* Relationship to party
* Connected quests
* Group memberships
* Session appearances

### 4. Factions / Groups

Use this as the home for villains, organizations, and collective agendas.

Track:

* Name
* Type
* Public purpose
* Secret purpose
* Goals
* Resources
* Members
* Rivals/allies
* Current plans
* Progress clocks or milestones
* Relationship to party

Example:

```text
Faction: The Ashen Hand
Goal: Open the sealed gate beneath the capital
Members: Magistrate Vell, Red Oracle, temple infiltrators
Progress: Stole temple map, acquired royal blood, still needs moon-priest
Status toward party: Hostile, now aware of them
```

### 5. Quest and Plot Thread Tracker

Use this to manage what the party knows and what is actually true.

Track:

* Status
* Hook
* Objective
* Known clues
* Hidden truth
* Related NPCs
* Related factions
* Related locations
* Consequences if ignored
* Resolution

### 6. Player-Facing Portal

Allow GMs to reveal selected information.

Useful visibility states:

* Private GM-only
* Shared with all players
* Shared with selected players
* Revealed after a condition

Shareable content should include recaps, known NPCs, known factions, quests, handouts, links, maps, and campaign lore.

## Deprioritize for Now

Do **not** prioritize:

* Rules reference
* Random roll tables
* Built-in battlemaps
* Deep combat automation
* Full VTT functionality

For battlemaps, support simple **external links and attachments** only.

## Best MVP

The strongest first version would include:

1. **Campaign dashboard**
2. **Session prep/live notes/recap workflow**
3. **NPC manager**
4. **Factions/groups with goals and members**
5. **Quest/thread tracker**
6. **Location manager**
7. **Player character tracker**
8. **Handouts and external map links**
9. **Visibility controls for player-facing content**

## Main Design Principle

Make it a **structured campaign memory system**.

The GM should be able to connect everything:

```text
NPC belongs to faction
Faction pursues goal
Goal creates quest
Quest points to location
Location contains handout
Session changes faction progress
Recap reveals selected facts to players
```

That interconnected memory is the main value.


