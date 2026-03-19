# Prostheti Innovations Campaign - Implementation Guide

## Overview
This document tracks all assets, code, maps, and sprites needed to implement the Prostheti Innovations campaign in Lobotomy Corp 13.

---

## Reusable Systems

### "Broken Fate" — Party Wipe Reset System

A reusable system attached to mission instances. Monitors all participants — when every player is dead or downed, triggers a cinematic game-over screen and **sends players back to the hub map**. The away z-level is NOT destroyed — it is reset in place (all mobs qdel'd and respawned from landmarks) so that when players re-enter, they teleport back to the same z-level without needing to load a new map. This avoids duplicate z-levels and expensive map loading/unloading.

Can be toggled on/off for scripted moments where dying is intentional (e.g., the Ch2 boss fight where players are supposed to lose and the Zwei intervene).

**Wipe Detection:**
- The mission datum registers `COMSIG_LIVING_DEATH` and `COMSIG_MOB_STATCHANGE` on each participant
- On each death/stat change, `CheckForWipe()` checks if ALL participants have `stat >= UNCONSCIOUS` (covers both downed and dead)
- `var/wipe_enabled = TRUE` — toggle flag. When `FALSE`, all-dead state is ignored. Controlled via `SetWipeEnabled(enabled)`
- A short grace period (~3 seconds) starts before confirming the wipe — if any player is revived during this window (e.g., by an in-mission mechanic), the wipe is cancelled

**Broken Fate Screen:**
- Applied to each participant using the fullscreen overlay system (`code/_onclick/hud/fullscreen.dm`), NOT the ordeal blurb approach, because players may be dead and need `show_when_dead = TRUE` to see the overlay
- Step 1: Black fullscreen overlay via `overlay_fullscreen("broken_fate_bg", /atom/movable/screen/fullscreen/broken_fate_bg)` — custom fullscreen type with `show_when_dead = TRUE`, full black screen, `plane = SPLASHSCREEN_PLANE` (above all other fullscreens)
- Step 2: Text overlay added to each participant's `client.screen` using the `ShowOrdealBlurb` maptext pattern (`code/modules/ordeals/_ordeal.dm`, lines 138-159) — "Broken Fate" in large Baskerville font, centered, white text on the black background
- Both layers hold for ~4 seconds
- Then both fade out via `animate()` alpha to 0, then removed

**Reset Sequence (after fade-out):**
1. All participants are revived: `revive(full_heal = TRUE)` — restores full health, clears all damage/status/CC
2. All participants are `forceMove`'d back to their `return_turfs` on the hub map (stored when they were teleported into the away mission)
3. Penny's companion mob (if present) is qdel'd
4. **Z-level reset in place** — the away z-level is NOT destroyed. Instead:
   a. All hostile mobs on the z-level are qdel'd
   b. Fresh copies are respawned at their mob spawn landmarks (see below)
   c. All UI NPC companions on the z-level are qdel'd (they will be respawned when players re-enter)
   d. Any chapter-specific event state on the z-level is reset (doors, triggers, etc.) via `OnBrokenFate()`
   e. The z-level now looks exactly like it did when it was first loaded — ready for a fresh attempt
5. `OnBrokenFate()` is called — chapter-specific subtypes override this for custom reset logic on the z-level and hub-side cleanup
6. `mission_state = MISSION_READY` — the mission datum stays alive with the z-level intact, ready for re-entry
7. `wipe_enabled` is re-set to `TRUE`
8. Fullscreen overlays are cleared: `clear_fullscreen("broken_fate_bg")`

**Mob Spawn Landmarks:**
- Each hostile mob on the away mission map is placed via a persistent spawn landmark instead of placing mobs directly in the map editor
- Landmark type: `/obj/effect/landmark/mission_mob_spawn`
- Each landmark defines: `var/mob_type` (the mob path to spawn, e.g., `/mob/living/simple_animal/hostile/factory_worker`)
- On mission load, each landmark spawns its mob at its turf and registers itself with the mission datum. The landmark does NOT qdel — it persists as the respawn point for resets.
- On Broken Fate reset, the mission datum iterates all landmarks on the z-level: any existing mob from that landmark is qdel'd, then a fresh copy is spawned at the landmark turf. Always a clean delete and respawn.
- Map authors place these landmarks in the map editor — the landmarks handle both initial spawning and respawning on reset.

**After Reset — Back on the Hub:**
- Players are alive and fully healed on the hub map, standing where they were before they entered the mission
- The NPC who triggered the away mission (e.g., Hector for Ch2) still has the mission trigger dialogue available — players can talk to him and choose to re-enter
- **Re-entering reuses the existing z-level** — the mission datum still holds a reference to `factory_level`. Players are `forceMove`'d to the spawn landmarks on the same z-level. Penny's companion mob is respawned fresh. No new `load_new_z()` call is needed.
- Players are never stuck in an unbeatable mission. They can always regroup on the hub, talk to NPCs, and decide when to try again.
- The z-level is only destroyed when the mission is completed successfully OR when the chapter is abandoned (e.g., round ends, players leave via bus).

**Generalized Architecture:**

The Broken Fate system is built into the base mission datum, not tied to any specific chapter. The common flow (detection → cinematic → revive → teleport to hub → reset z-level in place) is handled by the base type. Chapter-specific reset logic lives in override procs on subtypes.

- **Base mission datum:** `/datum/prostheti_mission` — parent type for ALL campaign missions (Ch2 factory, Ch3 truck confrontation, Ch4 shop raid, etc.). Contains the full Broken Fate system.
- **Chapter-specific subtypes:** `/datum/prostheti_mission/factory_infiltration`, `/datum/prostheti_mission/roadside_rush`, etc. — each subtype defines its own mission setup and overrides `OnBrokenFate()` for unique reset logic.

**Override Proc — `OnBrokenFate()`:**
- Called during the reset sequence AFTER mobs are respawned on the z-level and players are teleported back to the hub, but BEFORE the black screen fades out
- The base proc handles the generic reset (qdel mobs, respawn from landmarks, qdel companions). Subtypes override it to handle chapter-specific state.
- **Example — Ch2 Factory:** `/datum/prostheti_mission/factory_infiltration/OnBrokenFate()` would: reset the office door to its pre-trap state, clear the "trap triggered" flag, re-arm the director's scripted entrance, reset `npc_vars.mission_started` to `FALSE` so Hector's dialogue trigger works again, and move Penny's Chapter 1 `ui_npc` back from nullspace to the Training Yard.

**Variables and Procs on `/datum/prostheti_mission`:**

| Variable/Proc | Type | Purpose |
|---------------|------|---------|
| `wipe_enabled` | `var/bool` | Toggle — `FALSE` during scripted death moments |
| `wipe_in_progress` | `var/bool` | Prevents double-triggering during cinematic |
| `return_turfs` | `var/list` | Assoc list mapping each participant mob → their hub turf before teleport |
| `factory_level` | `/datum/space_level` | The loaded away z-level — persists across Broken Fate resets, reused on re-entry |
| `mob_landmarks` | `var/list/obj/effect/landmark` | All `/obj/effect/landmark/mission_mob_spawn` on the z-level — used for respawning mobs on reset |
| `spawn_turfs` | `var/list/turf` | Player spawn turfs on the away z-level — used for both initial entry and re-entry |
| `mission_state` | define | `MISSION_SIGNUP`, `MISSION_LOADING`, `MISSION_ACTIVE`, `MISSION_COMPLETE`, `MISSION_READY` (reset, awaiting re-entry) |
| `CheckForWipe()` | proc | Called on participant death/statchange, checks all-dead condition |
| `TriggerBrokenFate()` | proc | Runs cinematic → revive → teleport to hub → reset z-level in place → calls `OnBrokenFate()` |
| `OnBrokenFate()` | proc | Empty in base type — overridden by chapter subtypes for chapter-specific reset logic |
| `SetWipeEnabled(enabled)` | proc | Toggle for scripted moments |
| `ReenterMission()` | proc | Called when players choose to re-enter from hub — `forceMove`'s them to `spawn_turfs`, respawns companion, sets `mission_state = MISSION_ACTIVE` |

---

## Campaign Architecture

### Accessing the Campaign — Bus Ticket

The Prostheti Innovations factory hub is loaded via the existing bus ticket system in `ModularLobotomy/associations/machines.dm`. Players insert a ticket into the ticker reader (`/obj/structure/maploader`), which loads the factory map as a new z-level via `load_new_z_level()` and adds it to the bus console's destinations.

**Ticket type:** `/obj/item/quest_ticket/prostheti_innovations`

```
/obj/item/quest_ticket/prostheti_innovations
	name = "'Prostheti Innovations' ticket"
	desc = "A small sheet of paper with a barcode. Could be given to a ticket reader to access to a new area."
	map = "_maps/Quests/prostheti_innovations.dmm"
	map_name = "prostheti_innovations_floor"
	ticket_name = "Prostheti Innovations"
```

Once loaded, the bus can travel to the Prostheti factory z-level. Players ride the bus there and disembark onto the factory map. The **chapter select landmark** (`/obj/structure/prostheti_chapter_select`) is placed near the bus stop/entrance on the factory map — this is the first thing players encounter when they arrive.

**Flow:**
1. Someone finds or is given the Prostheti Innovations ticket
2. Ticket is inserted into the ticker reader → factory .dmm loads as a new z-level
3. Bus console is updated with the "Prostheti Innovations" destination
4. Players ride the bus to the factory
5. On arrival, players see the chapter select landmark near the entrance
6. If they have completed chapters in previous rounds, they can select which chapter to start from. Otherwise, Chapter 1 starts automatically.

### Factory Hub Map

The Prostheti Innovations factory map is the **persistent hub** for the entire campaign. It is loaded as a z-level via the bus ticket system (see above). All chapter content either happens directly on this map (Chapter 1) or is triggered FROM this map by loading additional z-levels for away missions (Chapters 2-7).

The hub layout stays the same across all chapters. What changes between chapters is the **NPC set** — which NPCs are on the map, what their dialogue says, and which one triggers the away mission.

### Away Missions as Z-Levels

Every chapter that involves leaving the factory hub loads its content as a separate z-level via `map_template.load_new_z()` (`code/modules/mapping/map_template.dm`, lines 108-125). The hub map stays loaded — players are teleported to the new z-level and teleported back when done.

**Pattern (established for Ch2 factory infiltration):**
1. An NPC's `proc_callback` creates a `/datum/prostheti_mission/[chapter]` mission datum
2. The mission datum creates a `map_template` pointing to the chapter's .dmm file
3. Calls `template.load_new_z()` → new z-level allocated via `SSmapping.add_new_zlevel()`
4. Players `forceMove`'d to spawn landmarks on the new z-level
5. Mission plays out on the z-level (Broken Fate system active)
6. On completion, players `forceMove`'d back to the hub
7. Z-level cleaned up (all mobs/objects qdel'd)

**Chapter away mission maps:**

| Chapter | Away Map | Z-Level Content |
|---------|----------|-----------------|
| 1 | None — all content on the hub map | Training duels, minigame, all on factory z-level |
| 2 | `competitor_factory.dmm` | Competitor factory infiltration, boss fight, Zwei rescue |
| 3 | `roadside.dmm` | Truck ambush road, combat encounter, investigation |
| 4 | `insurgence_shop.dmm` | Augment shop, RP section, boss encounter |
| 5 | `clan_warehouse.dmm` | Warehouse infiltration, capture, Simon boss fight |
| 6 | `transport_ship.dmm` | Great Lake ship, stealth/combat, rescue |
| 7 | TBD | Final chapter — may use hub map or a new z-level |

Each away map has its own `/datum/prostheti_mission/[chapter]` subtype that inherits the Broken Fate system (see Reusable Systems above) and manages that chapter's segments, mob landmarks, and custom reset logic.

### Independent Chapter Loading

**Key principle:** Each chapter is INDEPENDENT. Loading Chapter 3 does NOT require replaying the state of Chapters 1 and 2. The hub setup for any chapter is self-contained — no cumulative state chains.

Each chapter has its own set of **NPC variants** — subtypes of the base `ui_npc` mobs with chapter-specific dialogue, `npc_vars`, and `proc_callback` triggers. When a chapter is loaded, the campaign controller qdels any existing chapter NPCs and spawns the new chapter's NPC set. Each NPC variant handles its own setup in `Initialize()` (dialogue scenes, door states, etc.).

**Clyde always has a variant per chapter** (his dialogue and demeanor evolve with the story), but he is NOT always the NPC who triggers the away mission. Different chapters have different NPCs driving the action.

**Clyde Variants:**

| Chapter | Clyde Variant | Clyde's Role |
|---------|---------------|--------------|
| 1 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch1` | Boss giving you work, distant father |
| 2 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch2` | Post-confrontation, cold and justified |
| 3 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch3` | Gives players the truck intercept job |
| 4 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch4` | Sends players to investigate the shop address |
| 5 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch5` | Sends players to the warehouse |
| 6 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch6` | Identifies the ship, sends players via submarine |
| 7 | `/mob/living/simple_animal/hostile/ui_npc/clyde_wells/ch7` | TBD |

**Which NPC triggers the away mission z-level load:**

| Chapter | Trigger NPC | How |
|---------|-------------|-----|
| 1 | None | No away mission — all content on hub map |
| 2 | **Hector** (Ch2 variant) | Hector's proposal dialogue → "We're ready" action → factory z-level loads |
| 3 | **Clyde** (Ch3 variant) | Clyde gives the job → triggers roadside z-level load |
| 4 | Clyde or players directly | Address from Ch3 evidence → shop z-level loads |
| 5 | TBD | Warehouse z-level loads |
| 6 | **Clyde** (Ch6 variant) | Clyde identifies the ship → submarine z-level loads |
| 7 | TBD | TBD |

Other NPCs (Penny, Hector) also have per-chapter variants where needed. For example, Chapter 2 spawns Hector's Ch2 variant (with the proposal cutscene and mission briefing) alongside Clyde's Ch2 variant.

### Campaign Controller

**Type:** `/datum/campaign_controller/prostheti` — manages chapter state for the round.

**Variables:**

| Variable | Type | Purpose |
|----------|------|---------|
| `current_chapter` | `var/int` | The active chapter number |
| `current_npcs` | `var/list/mob` | NPC mob refs currently on the hub for this chapter |
| `chapter_selected` | `var/bool` | `TRUE` once a chapter has been chosen this round — prevents re-selection |

**Procs:**

| Proc | Purpose |
|------|---------|
| `InitializeAtChapter(chapter_number)` | Qdels all NPCs in `current_npcs`, spawns the correct NPC variants for the given chapter at their landmark positions |
| `CompleteChapter(chapter_number)` | Saves progress, plays transition blurb, cleans up away z-level, returns players to hub, calls `InitializeAtChapter(chapter_number + 1)` |
| `SpawnChapterNPCs(chapter_number)` | Called by `InitializeAtChapter()` — contains a switch/map that knows which NPC variant subtypes to spawn per chapter |

### Cross-Round Chapter Progression

Players who complete chapters in one round can skip ahead in future rounds.

**Persistence — `data/ProsthetiProgress.json`:**

Follows the same pattern as `data/ClearedCores.json` in `SSpersistence` (`code/controllers/subsystem/persistence.dm`). Stores per-ckey progress:

```json
{
  "player_ckey_1": { "highest_chapter": 3 },
  "player_ckey_2": { "highest_chapter": 1 }
}
```

`highest_chapter` = the highest chapter number this player has COMPLETED. A player with `highest_chapter = 2` can start rounds at Chapter 1, 2, or 3.

**SSpersistence integration:**
- New var: `var/list/prostheti_progress` on `SSpersistence`
- `LoadProsthetiProgress()` — called during `Initialize()`, reads from JSON
- `UpdateProsthetiProgress(ckey, chapter_number)` — called when a player completes a chapter. Only updates if `chapter_number > existing highest_chapter`
- `CollectProsthetiProgress()` — called during `CollectData()`, writes back to JSON

**Chapter Select Landmark:**

| Type Path | Zone | Count | Purpose |
|-----------|------|-------|---------|
| `/obj/structure/prostheti_chapter_select` | Near bus stop / Factory Entrance | 1 | Chapter select — first thing players see when they arrive via bus |

**Interaction flow:**
1. Player clicks the landmark
2. Checks `SSpersistence.prostheti_progress[player.ckey]` for `highest_chapter`
3. If `highest_chapter >= 1`, a TGUI window opens showing chapters 1 through `highest_chapter + 1` with titles and subtitles
4. If no entry (new player), nothing happens — Chapter 1 starts automatically
5. Player selects a chapter → the landmark calls `campaign_controller.InitializeAtChapter(N)`
6. The landmark becomes non-interactable for the rest of the round (`chapter_selected = TRUE`)

**Who can select:** Any player at the landmark can select for the group. The selected chapter becomes the starting chapter for ALL players this round. Only one selection per round. The landmark shows chapters unlocked by the INTERACTING player's progress.

**TGUI Mockup — Chapter Select Window:**

```
┌─────────────────────────────────────────────────┐
│              PROSTHETI INNOVATIONS               │
│             Campaign Chapter Select              │
│                                                  │
│  Selecting a chapter will set the starting       │
│  point for all players this round.               │
├─────────────────────────────────────────────────┤
│  Available Chapters                              │
│ ┌───────────────────────────────────────────┐    │
│ │        ┌──────────────────────────┐       │    │
│ │   1    │  Polished Surfaces       │ [Select]   │
│ │        │  The Job                 │       │    │
│ │        │  Begin your employment   │       │    │
│ │        │  at Prostheti.           │       │    │
│ │        └──────────────────────────┘       │    │
│ │  gold accent bar ═══════════════          │    │
│ ├───────────────────────────────────────────┤    │
│ │        ┌──────────────────────────┐       │    │
│ │   2    │  Paper Walls        NEW  │ [Select]   │
│ │        │  The Test                │       │    │
│ │        │  Hector proposes a       │       │    │
│ │        │  dangerous test.         │       │    │
│ │        └──────────────────────────┘       │    │
│ │  silver accent bar ══════════════         │    │
│ ├───────────────────────────────────────────┤    │
│ │        ┌──────────────────────────┐       │    │
│ │   3    │  Dead Letters            │  🔒   │    │
│ │        │  (locked)                │       │    │
│ │        └──────────────────────────┘       │    │
│ │  (dimmed, non-interactable)               │    │
│ ├───────────────────────────────────────────┤    │
│ │   4    │  Old Debts               │  🔒   │    │
│ │   5    │  Boiling Point           │  🔒   │    │
│ │   6    │  Still Water             │  🔒   │    │
│ │   7    │  Ash and Iron            │  🔒   │    │
│ │  (remaining chapters dimmed/collapsed)    │    │
│ └───────────────────────────────────────────┘    │
│                                                  │
│  Progress for: PlayerName                        │
│  (Completed through Chapter 1)                   │
└─────────────────────────────────────────────────┘
```

**Visual Notes:**
- Each chapter card has a **colored left accent bar** matching the chapter's theme color (gold, silver, dark red, etc.)
- Unlocked chapters show title, subtitle (in the chapter color), and a short description. A `[Select]` button on the right.
- The highest NEW chapter shows a colored `NEW` badge next to the title.
- Locked chapters are **dimmed to ~35% opacity** — title visible but no description, no button, just a lock icon. Collapsed to save space.
- Footer shows the interacting player's name and progress.
- Window size: ~480x560px. Uses `Baskerville` font for the header and subtitles to match the chapter transition blurbs.
- After selection, the window closes and the landmark becomes non-interactable. If someone else opens it after a selection, the window shows a centered message: "A chapter has already been selected this round."

### Chapter Completion Flow

When a chapter's objectives are met:
1. Mission datum (or campaign controller for hub-only chapters) calls `CompleteChapter(chapter_number)`
2. `CompleteChapter()`:
   a. Saves progress: `SSpersistence.UpdateProsthetiProgress(player.ckey, chapter_number)` for each participant
   b. Plays the chapter transition blurb (see Chapter Transition System below)
   c. Cleans up the away z-level if one exists
   d. Returns players to the hub
   e. Calls `InitializeAtChapter(chapter_number + 1)` — qdels current NPCs, spawns the next chapter's NPC set

---

## Chapter 1: Polished Surfaces

### Map

The Chapter 1 map is the Prostheti Innovations factory, split into three connected zones:

**1. Design Floor** — The main workspace. Contains the augment design minigame terminal(s). This is where players spend most of their time. Clyde's office is adjacent or overlooking this area — he's always nearby but not hovering. Players are here doing their job.

**2. Factory Floor / Corridor** — The connecting area between the design floor and the back side. Factory machinery, conveyor belts, storage. Penny's patrol path runs through here — she walks from the back side through the corridor into the design floor, stays for a bit, then walks back. This is a transition space, not a gameplay space.

**3. Training Yard** — The "other side of the factory." An outdoor back area or cleared-out section where Hector waits. Contains the training duel landmarks (`player_spawn` and `fixer_spawn`). Players don't know this area exists until Penny takes them there. Could be gated by a door that's locked until Penny opens it during the introduction scene.

**Map-Placed Objects and Mobs:**

All custom types that need to be placed in the map editor for Chapter 1:

| Type Path | Zone | Count | Purpose |
|-----------|------|-------|---------|
| `/mob/living/simple_animal/hostile/ui_npc/clyde_wells` | Design Floor | 1 | Clyde's NPC, stationed in/near his office |
| `/mob/living/simple_animal/hostile/ui_npc/penny_wells` | Design Floor | 1 | Penny's NPC, starts here then wanders via waypoints |
| `/mob/living/simple_animal/hostile/ui_npc/hector` | Nullspace | 1 | Hector's NPC, starts off-map — moved to Training Yard during introduction scene |
| `/obj/effect/landmark/penny_waypoint` | Design Floor + Factory Floor | 5-8 | Waypoints for Penny's wandering loop. Each adds its turf to `GLOB.penny_waypoints` and qdels |
| `/obj/effect/landmark/training_duel/player_spawn` | Training Yard | 1 | Player teleport destination for training sparring |
| `/obj/effect/landmark/training_duel/fixer_spawn` | Training Yard | 1 | Training mob spawn point for training sparring |
| `/obj/effect/landmark/hector_spawn` | Training Yard | 1 | Turf where Hector is forceMove'd during introduction scene |
| `/obj/effect/landmark/penny_yard_destination` | Training Yard | 1 | Turf Penny patrols to during the introduction scene (`yard_turf`) |
| `/obj/machinery/door/training_yard_door` | Between Factory Floor and Training Yard | 1 | Locked door — Penny unlocks it during the introduction cutscene |
| `/obj/machinery/computer/augment_minigame` | Design Floor | 1+ | Terminal(s) for the augment design minigame |

**Notes:**
- Penny is placed on the Design Floor in the map editor but wanders to any `penny_waypoint` landmark on the Design Floor or Factory Floor. Do NOT place any `penny_waypoint` landmarks in the Training Yard.
- Hector is placed directly in the map editor but starts in nullspace (moved off-map in `Initialize()`). The `/obj/effect/landmark/hector_spawn` marks where he gets forceMove'd to when Penny's introduction scene fires.
- The `training_yard_door` starts locked and impassable. Penny's `proc_callback` unlocks and opens it — after that, players can walk through freely.

### Mobs

**Shared Dialogue State:** All UI NPCs in this campaign use **shared dialogue state** — not per-player. When any player opens an NPC's dialogue window, every player sees the same conversation progress, the same scene, and the same available actions. If one player advances the conversation, it advances for everyone. This is controlled by using `npc_vars` (shared scope) instead of `dialog` (per-player scope) for all conversation tracking in the scene manager. The `ui_data()` proc returns the same scene/text/actions regardless of which player is viewing. Per-player resolvers (`dialog_resolvers`) are not used — all state lives on the NPC itself via `npc_vars`.

**Why shared state:** This is a campaign with a group of players experiencing the story together. Dialogue should feel like a group conversation, not a private one. When Clyde tells the crew something, everyone hears it. When Penny offers to show the crew something, the whole group follows.

#### Clyde Wells — UI NPC

Standard `ui_npc` with `SpeakingNpc` TGUI, shared dialogue state. Needs 192x192 portrait. Stationed in/near his office on the Design Floor. Standard branching dialogue — no special code systems beyond what ui_npc already provides.

**Variables to track (npc_vars):** `asked_about_penny`, `asked_about_company`, `asked_about_family` — referenced in later chapters.

#### Penny Wells — UI NPC

Standard `ui_npc` with `SpeakingNpc` TGUI, shared dialogue state. Needs 192x192 portrait.

**1. Factory Wandering (waypoint patrol system)**

Penny wanders through the indoor areas of the factory (Design Floor and Factory Floor), stopping at various points for about a minute before moving on. She does NOT wander into the outdoor Training Yard on her own — that area is gated behind the introduction scene.

**Waypoint Landmarks:**
- New custom landmark type: `/obj/effect/landmark/penny_waypoint` — placed across the Design Floor and Factory Floor in the map editor
- On `Initialize()`, each landmark adds its turf to a new `GLOB.penny_waypoints` list and qdels itself (completely separate from `department_centers`)
- Place 5-8 waypoints to give variety — near workstations, by the corridor entrance, beside Clyde's office window, at the factory floor machinery, etc.

**Wandering Loop:**
- On `Initialize()`, Penny starts her first wander after a short delay: `addtimer(CALLBACK(src, PROC_REF(pick_new_waypoint)), rand(5 SECONDS, 15 SECONDS))`
- `pick_new_waypoint()` selects a random turf from `GLOB.penny_waypoints` (excluding current turf), then calls `patrol_to(target_waypoint)`. If pathfinding fails, retry with a different waypoint
- When Penny arrives at the waypoint (check via override of `patrol_reset()` or a turf-proximity timer), she sets `stop_automated_movement = TRUE` and starts a dwell timer: `dwell_timer_id = addtimer(CALLBACK(src, PROC_REF(pick_new_waypoint)), rand(45 SECONDS, 75 SECONDS), TIMER_STOPPABLE)`
- The cycle repeats: arrive → dwell ~1 min → pick new waypoint → patrol → arrive → dwell...

**Dialogue Pause:**
- When a player talks to Penny (dialogue opens), set `stop_automated_movement = TRUE` and delete any active `dwell_timer_id` via `deltimer(dwell_timer_id)`
- When dialogue closes, restart the cycle: `pick_new_waypoint()` after a short delay (5-10 seconds)
- This means Penny never walks away mid-conversation

**Permanent Stop (Training Yard):**
- `var/settled_in_yard = FALSE` — set to `TRUE` after the introduction scene completes (Section 3)
- All wandering procs check `if(settled_in_yard) return` at the top
- Once Penny enters the Training Yard via the introduction scene, she never wanders again — she stays there for the rest of the chapter

**Wandering Variables on Penny's mob:**
- `var/list/waypoints` — populated from `GLOB.penny_waypoints` in `Initialize()`
- `var/dwell_timer_id` — stoppable timer for the dwell-at-waypoint pause
- `var/settled_in_yard = FALSE` — permanent wandering kill switch
- `var/turf/current_waypoint` — tracks where she currently is/heading to (to exclude from random selection)

**2. Fixer Knowledge Trigger**

The player shares fixer knowledge with Penny through dialogue. The gate is tied to the augment minigame — after the player has designed augments for Fixer-type clients (Zwei, Cinq, etc.), a `player.fixer_designs` counter increments. When `player.fixer_designs >= X`, a new dialogue action appears on Penny's NPC:

- Something like: "I've been building augments for Fixers — the Zwei squads want defense, the Cinq duelists want raw damage..."
- Penny gets excited — this is practical knowledge about how Fixers actually use their gear.
- The dialogue action's `visibility_expression` checks `player.fixer_designs >= X`.

**3. Introduction Scene (proc_callback + say() cutscene)**

When the player selects the fixer knowledge dialogue option, Penny responds with "Come with me — there's something I want to show you." This triggers a `proc_callback` chain:

1. `in_cutscene = TRUE` on both Penny and Hector — all open TGUI sessions on Penny are force-closed via `active_tgui_sessions` loop, and no player can reopen dialogue on either NPC until the cutscene ends
2. Penny's wandering is killed: `deltimer(dwell_timer_id)`, `settled_in_yard = TRUE`
3. The locked door between Factory Floor and Training Yard unlocks (Penny holds a `var/obj/machinery/door/training_door` reference, calls unlock/open)
4. Penny says aloud: `say("Follow me — there's someone you should meet.")`
5. Penny patrols to the Training Yard: `patrol_to(yard_turf)`
6. Player follows on foot through the now-open corridor
7. When Penny arrives at the Training Yard, Hector is moved from nullspace onto the map: `hector_npc.forceMove(hector_spawn_turf)`
8. **Spoken cutscene begins** — Penny and Hector have a back-and-forth using `say()` procs with `SLEEP_CHECK_DEATH` delays between lines. This plays out in the world chat so all nearby players witness it, not through the TGUI window:

```
Penny: "Hector! It's been a while."
  (2 second pause)
Hector: "Penny. You look well. Still dragging strangers to meet me, I see."
  (2 second pause)
Penny: "They're not strangers — they're my father's new designers. And they've been building gear for Fixers."
  (2 second pause)
Hector: "Is that so."
  (1.5 second pause)
Penny: "Real combat augments. Zwei patrol loadouts, Cinq dueling rigs — the kind of work that matters."
  (2 second pause)
Hector: "Hmm. Designing for Fixers is one thing. Knowing what a Fixer actually needs is another."
  (2 second pause)
Penny: "That's why I brought them here. Hector used to run jobs — real ones. If anyone can show you what your augments need to survive, it's him."
  (2.5 second pause)
Hector: "I don't run jobs anymore. But I can still swing a blade. If your designers want to learn what their work feels like from the other side — I'm here."
```

9. Sets `npc_vars.introduced_hector = TRUE`
10. From this point on, both Penny and Hector offer training sparring via their dialogue windows. Penny stays in the Training Yard permanently (wandering disabled by `settled_in_yard`)

**Cutscene Implementation:**
- The entire back-and-forth runs in a single proc: `proc/IntroductionCutscene()` called via `INVOKE_ASYNC` from the `proc_callback`
- Uses `say()` on Penny's mob and Hector's mob alternately, with `SLEEP_CHECK_DEATH(20)` (~2 seconds) between lines
- No TGUI window is open during the cutscene — it's purely world-visible speech bubbles and chat messages
- If any player is in the Training Yard when the cutscene starts, they see it. If they arrive late, they see whatever lines are still being spoken. The dialogue is short enough (~20 seconds total) that most players will catch it while following Penny through the corridor

**Cutscene Dialogue Lock:**
- Both Penny and Hector have a `var/in_cutscene = FALSE` flag. Set to `TRUE` at the start of `IntroductionCutscene()`, set back to `FALSE` at the end.
- `ui_interact()` override on both NPCs checks `if(in_cutscene) return` — blocks any player from opening the dialogue window while the cutscene is running
- At the start of `IntroductionCutscene()`, all currently open TGUI sessions on Penny are force-closed: loop through `active_tgui_sessions` and call `close()` on each. This handles the case where a player already has Penny's dialogue open when the cutscene triggers (e.g. the player who selected the fixer knowledge option — their window closes, and the cutscene plays out in world chat instead)
- Hector's sessions don't need closing since he just arrived from nullspace and no one could have his window open yet
- The lock is released at the end of the cutscene when `in_cutscene = FALSE` is set, at the same time as `introduced_hector = TRUE`. After this point, both NPCs become interactable normally

**References needed on Penny's mob:**
- `var/mob/living/hector_npc` — reference to Hector, found by type in `Initialize()`
- `var/obj/machinery/door/training_door` — the locked door, found by landmark or type in `Initialize()`
- `var/turf/yard_turf` — Training Yard destination for the introduction scene, set via landmark in `Initialize()`

**4. Training Sparring (duel system)**

After introduction, Penny and Hector both gain a "Let's train!" dialogue option. Uses the Echo Office duel pattern from `echo_office_npcs.dm`:

- **Landmarks:** `/obj/effect/landmark/training_duel/player_spawn` and `/training_duel/fixer_spawn` in the Training Yard.
- **Flow:** `proc_callback` → `StartTraining()` → player teleported to player_spawn → training mob spawned at fixer_spawn.
- **Training mob:** Simple hostile mob, weaker than Echo fixers. Type/gimmicks TBD.
- **Signals:** `RegisterSignal` on player for `COMSIG_MOB_STATCHANGE` (downed = loss), on mob for `COMSIG_LIVING_DEATH` (killed = win).
- **End:** `EndTraining()` teleports player back to design floor, fully heals. No gear rewards.
- **Win tracking:** `player.training_wins` increments on win. Gates later dialogue.

**Variables to track (npc_vars, shared across all players):**
- `fixer_designs` — incremented by the minigame when designing for Fixer clients. Gates the introduction trigger.
- `introduced_hector` — cross-NPC, set after the say() cutscene completes
- `training_wins` — cross-NPC, gates later dialogue on both Penny and Hector

#### Hector — UI NPC

Standard `ui_npc` with `SpeakingNpc` TGUI, shared dialogue state. Needs 192x192 portrait. Starts in nullspace until Penny's introduction scene places him in the Training Yard.

Can offer training sparring (same landmarks/system as Penny's `StartTraining()`). Standard branching dialogue otherwise. Dialogue window is blocked until `introduced_hector = TRUE` (the say() cutscene must finish first).

**Variables to track (npc_vars):** `hector_conversations` — how many times the crew has talked to him. Referenced in later chapters for dramatic weight.

### Hazards

### Sprites Required — Chapter 1

#### NPC World Sprites (32x32, all need N/S/E/W directionals)

| Sprite | Description | Notes |
|--------|-------------|-------|
| **Clyde Wells** | Middle-aged man in a corporate suit. Dark hair, cigarette optional. Stern, composed posture. | Stationed near his office — mostly static. Should read as "boss." |
| **Penny Wells** | Young woman, energetic. Casual-professional clothing — she works here but isn't the CEO. | Wanders the factory floor. Needs a walk animation. |
| **Hector** | Fixer build. Hexagonal armor motifs or orange accents referencing the Clan aesthetic. Blade at his side. | Appears from nullspace into the Training Yard. Should look combat-capable but approachable. |
| **Training Mob** | A sparring dummy or generic fixer silhouette for training duels. | Type/look TBD. Simple combat opponent. Needs attack animation. |

#### NPC Portraits (192x192, TGUI dialogue)

| Portrait | Description | Notes |
|----------|-------------|-------|
| **Clyde Wells** | Close-up. Sharp features, dark eyes, hint of grey at the temples. Wearing a collared shirt/tie. Corporate but human. | Used in `SpeakingNpc` TGUI window. |
| **Penny Wells** | Close-up. Bright, expressive. Should contrast with Clyde's severity. Young and optimistic. | Used in `SpeakingNpc` TGUI window. |
| **Hector** | Close-up. Warm eyes in a weathered face. Orange glow or hexagonal pattern somewhere on his armor/collar. Friendly but dangerous. | Used in `SpeakingNpc` TGUI window. |

#### Objects & Environment (32x32)

| Sprite | Description | Notes |
|--------|-------------|-------|
| **Augment Design Terminal** | Computer/terminal on the Design Floor. Industrial-corporate look — a workstation, not a military console. | `/obj/machinery/computer/augment_minigame`. Players interact with this for the minigame. |
| **Chapter Select Landmark** | An interactable object near the bus stop/factory entrance. Could be a signpost, a terminal, or a Prostheti Innovations logo plaque. | `/obj/structure/prostheti_chapter_select`. First thing players see. Should be visually distinct. |
| **Bus Ticket** | Small item sprite. Paper ticket with a barcode and "Prostheti Innovations" text. | `/obj/item/quest_ticket/prostheti_innovations`. In-hand sprite optional. |
| **Training Yard Door** | Locked door between Factory Floor and Training Yard. | May be able to reuse existing door sprites with a Prostheti color scheme. |

---

### Extra Gameplay

#### Augment Design Minigame

Loosely based on the augment fabricator system in `ModularLobotomy/associations/augments.dm`. Instead of designing augments for combat use, the player is designing augments **for profit** — matching client needs while managing material costs. Inspired by the **Dispatch** game's pentagon stat comparison system.

**Core Concept:** Each round, the player reads a client's description to figure out what attributes they need, builds an augment by selecting effects that shape a **pentagon stat chart**, then submits to see how well their augment's pentagon overlaps the client's hidden pentagon. Better overlap = higher profit.

**Reference from existing system:**
- Effects have `ahn_cost` (material cost) and `ep_cost` (complexity/slots used)
- Forms have `base_cost` and `base_ep` (slot budget)
- Rank does NOT increase attributes — rank controls the EP budget: Rank 1 = 2 EP, Rank 2 = 4 EP, ... Rank 5 = 10 EP
- Higher rank = more effects = bigger pentagon, but higher material cost
- Negative effects (negative `ep_cost`) give back EP slots but add drawbacks
- Market system already exists: 20% of effects go on sale (25/33/40/66% off), 10% get marked up (25/33/40% more)

##### The 5 Core Attributes (Pentagon Vertices)

Every augment has 5 core attributes visualized as a **pentagon radar chart**:

- **Lethality** (top) — Kill power, damage output
- **Endurance** (upper-right) — Survivability, toughness, defense
- **Agility** (lower-right) — Speed, dodge, reaction time
- **Control** (lower-left) — Precision, accuracy, crowd control
- **Efficiency** (upper-left) — Resource use, reliability, cost-effectiveness

##### Base Attributes

All attributes start at **1** (baseline minimum). The chosen **Form** adds bonuses:
- **Prosthetic**: +1 Lethality, +1 Endurance → starts at L:2, En:2, Ag:1, C:1, Ef:1
- **Tattoo**: +1 Agility, +1 Control → starts at L:1, En:1, Ag:2, C:2, Ef:1

##### Effects Modify Attributes

Each effect has an `attributes` field — modifiers to the 5 stats:
- `Stalwart Form` → Endurance +4, Agility -3 | tags: [defensive]
- `Backstabber` → Lethality +2, Agility +2, Endurance -2 | tags: [bleed, offensive]
- `Regeneration` → Endurance +2, Efficiency +1 | tags: [healing]

Most effects touch 2-3 attributes with values ranging from -3 to +4. This creates trade-offs — boosting one stat usually costs another.

##### Special/Conditional Effects (~5-8 total)

Some effects have a **special** — a conditional bonus that activates when an attribute exceeds a threshold:

Example: `Inner Ardor` → Lethality +2, Efficiency -1 | **Special**: While Lethality > 8, grant +2 Control | tags: [offensive, overheat]

##### Hidden Client Pentagon (Dispatch Style)

**Key mechanic: Players do NOT see the client's pentagon during design.**

Each client has a **hidden set of attribute values** (their ideal pentagon). Instead of showing these numbers, clients provide **flavor text hints** that imply what they value. Each client also has 1-2 **required tags** (shown explicitly).

**Client Types:**

| Client | Hint Text | Required Tags | Hidden Pentagon (L/En/Ag/C/Ef) |
|--------|-----------|---------------|-------------------------------|
| Zwei Patrol | "We need augments that keep our officers standing through long patrols. Endurance is everything — and they need to maintain formation." | defensive | 3/9/3/6/4 |
| Backstreets Brawler | "Speed is everything in the Backstreets. If you can't dodge, you're dead. And when you do hit, make it count." | offensive | 7/3/8/2/3 |
| Seven Investigator | "Precision. Control. Our operatives don't need brute force — they need to incapacitate without collateral." | tremor | 2/4/3/9/6 |
| Budget Freelancer | "Look, I can't afford anything fancy. Just give me something reliable that won't drain my account." | (none) | 3/3/3/3/9 |
| Cinq Duelist | "One strike. Maximum lethality, maximum speed — leave defense to the amateurs." | offensive | 10/2/8/4/2 |
| Hana Intern | "Our field medics need augments that keep them alive while they work. Survivability first." | healing | 2/8/3/4/7 |
| Dieci Bounty Hunter | "My targets don't stand still. Hit hard and chase them down. Don't care about the rest." | on-kill | 9/3/7/3/3 |
| Workshop Artisan | "I'm not a fighter. I need precision tools — fine motor control, energy efficiency." | support | 1/3/3/8/9 |

##### Scoring: Pentagon Overlap

When the player submits a design, the **client's white pentagon** is revealed overlaid on the **player's orange pentagon** (Dispatch style).

**Per-attribute scoring:**
```
if player_value >= client_value:
    axis_score = 1.0 + (excess × 0.03)    // +3% per point above, capped at +15%
else:
    axis_score = player_value / client_value  // proportional (0.0 to 0.99)
```

**Overall overlap** = average of 5 axis scores → **sell price multiplier**:
- 1.0 (100% coverage) = full sell value
- \>1.0 = bonus sell value (player exceeded all)
- <1.0 = reduced sell value proportionally

**Additional modifiers:**
- **Required tags**: Each present = +8% bonus. Each missing = -15% penalty.
- **Trending tags**: +8% per matching tag
- **Oversaturated tags**: -6% per matching tag
- **Rank mismatch**: -25% if outside client's preferred rank range.

**Profit** = (base sell value × overlap multiplier × tag modifiers) − material cost

##### Effect Tag System (Secondary Role)

Each effect gets 1-2 tags: `defensive`, `offensive`, `healing`, `bleed`, `overheat`, `tremor`, `on-kill`, `support`, `risky`

Tags influence profit secondarily. The primary purpose of required tags is to force trade-offs — adding "defensive" effects to meet a client's tag requirement might tank your Agility, requiring other effects to compensate.

##### The Core Design Puzzle

1. Read the client's hint text → deduce which 2-3 attributes they value most
2. Pick effects with required tags even though they cause trade-offs
3. Patch attribute holes with complementary effects
4. Submit and see how well your pentagon overlaps the client's revealed pentagon

##### Minigame Flow

1. **Morning Briefing** — Client introduction with hint text, required tags, trending/oversaturated tags, price changes. No pentagon shown.
2. **Design Phase** — Player builds augments with a **live pentagon chart** showing their current attribute profile. Each effect shows attribute modifiers alongside tags. 4 designs per day.
3. **End-of-Day Results** — Each design's pentagon compared to client's revealed pentagon. Shows overlap visualization, per-attribute breakdown, and profit.
4. **Final Score** — Total profit across 3 days, ranking, fixer design count.

**Code Requirements:**

- **Attribute system** — Each effect has an `attributes` assoc list. Calculation sums form base + effect modifiers + conditional specials.
- **Pentagon chart component** — SVG radar chart in TGUI with overlay support for dual pentagon comparison.
- **Hidden client attributes** — Client types store full attribute pentagons server-side, only sent to UI during Results phase.
- **Overlap calculator** — Per-axis coverage → average → sell price multiplier.
- **Tag system** — Kept, demoted to secondary role. Required tags replace wants/doesnt_want.
- **Market Board / Round Controller** — Existing, with reduced trending/oversaturated percentages.
- **Effect pricing** — Existing sale/markup system reused directly.

**TGUI Mockup — Design Phase (with Pentagon Chart):**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Augment Design Terminal                    Day 1 of 3    Design 2 of 4    │
├───────────────────────────┬─────────────────────────────────────────────────┤
│                           │                                                 │
│   AUGMENT PROFILE         │  Form: [Prosthetic ▼]    Rank: [◄ 3 ►]         │
│                           │  EP: 2 remaining         Cost: 252 ahn         │
│         Lethality         │  Required: [defensive] ✓                        │
│            6              │                                                 │
│            △              │  AVAILABLE EFFECTS                              │
│           ╱ ╲             │  ─────────────────────────────────────────────   │
│    Eff   ╱   ╲   End     │  [Search...]   [All] [def] [off] [heal] ...     │
│     3   ╱ ╱─╲ ╲   8     │                                                 │
│        ╱╱    ╲╲        │  Name             Attributes   Tags    Cost  +   │
│       ●╱      ╲●       │  ───────────────────────────────────────────────  │
│        ╲      ╱         │  ES Shield       En+3 Ag-1   [def]    30   [+]  │
│         ╲╲  ╱╱          │  Strong Arms     Le+3 Ef-1   [off]    35   [+]  │
│          ╲╲╱╱           │  Backstabber     Le+2 Ag+2   [bld]    25   [+]  │
│           ╲╱             │                  En-2        [off]              │
│    Con ───┼─── Agi      │  Regeneration    En+2 Ef+1   [heal]   27   [+]  │
│     4          2        │                               SALE -33%         │
│                           │  ★ Inner Ardor  Le+2 Ef-1   [off]    45   [+]  │
│   ┌─ CLIENT ───────────┐ │                  Le>8 → C+2  [over]             │
│   │ Zwei Patrol Squad   │ │  Def Prep       Co+2 Ef+1   [def]    38   [+]  │
│   │ Req: [defensive] ✓  │ │                              [sup]   SALE -25% │
│   │ Trending: sup, heal │ │                                                 │
│   │ Oversat:  risky     │ │                                                 │
│   └─────────────────────┘ │                                                 │
│                           │  YOUR DESIGN                                    │
│                           │  ─────────────────────────────────────────────   │
│                           │  Stalwart Form     En+4 Ag-3  [def]  45a  [-]  │
│                           │  Regeneration      En+2 Ef+1  [heal] 27a  [-]  │
│                           │  Def Prep          Co+2 Ef+1  [def]  38a  [-]  │
│                           │                                                 │
│                           │                   [ Submit Design ]             │
├───────────────────────────┴─────────────────────────────────────────────────┤
│  Prostheti Innovations — Employee Design Terminal                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Visual Notes — Design Phase:**
- **Left panel** features a **live pentagon chart** (SVG) that updates in real-time as effects are added/removed. Orange filled polygon inside a grey reference pentagon grid. Concentric rings at 25%/50%/75%/100%.
- Attribute names and current values shown at each vertex.
- **Client reference** condensed below the pentagon: client name, required tags (with ✓/✗), trending, oversaturated.
- **Right panel** has form/rank selectors at top, effect browser in the middle, selected effects at the bottom.
- Effects show **attribute modifiers** as compact colored text (green for +, red for -). Special effects marked with ★ and condition tooltip.
- **No client pentagon shown** during design — only the player's own.
- Sale/markup indicators shown inline next to affected effect costs.

**TGUI Mockup — End-of-Day Results (with Pentagon Overlay):**

After all designs are submitted, the results screen reveals the client's pentagon.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Augment Design Terminal — Day 1 Results                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─ DESIGN 1: Prosthetic Rank 3 ──────────────────────────────────────────┐ │
│  │                                                                        │ │
│  │          Lethality                                                     │ │
│  │             6/3                    ATTRIBUTE OVERLAP                   │ │
│  │            △                    ─────────────────────                 │ │
│  │           ╱░░╲                    Lethality:   6 / 3  ✓ Covered +3    │ │
│  │    Eff   ╱░░░░╲   End             Endurance:   8 / 9  ✗ Gap -1        │ │
│  │    3/4  ╱░░╱╲░░╲   8/9            Agility:     2 / 3  ✗ Gap -1        │ │
│  │        ╱░╱    ╲░╲                  Control:     4 / 6  ✗ Gap -2       │ │
│  │       ●╱        ╲●                 Efficiency:  3 / 4  ✗ Gap -1       │ │
│  │        ╲░░░░░░░░╱                                                      │ │
│  │         ╲░░░░░░╱                   ● = Your design (orange)            │ │
│  │          ╲░░░░╱                    ○ = Client wanted (white)           │ │
│  │     Con ──╲╱── Agi                                                     │ │
│  │      4/6      2/3                  Overall Overlap: 78%                │ │
│  │                                                                        │ │
│  │  ┌─ PROFIT BREAKDOWN ──────────────────────────────────────────────┐   │ │
│  │  │  Material Cost:        -252 ahn                                 │   │ │
│  │  │  Base Sell Value:       378 ahn                                 │   │ │
│  │  │  Overlap Modifier:      ×0.78  →  295 ahn                       │   │ │
│  │  │  Required Tag [def]:   +8%     →  +24 ahn                       │   │ │
│  │  │  Trending [heal]:      +8%     →  +24 ahn                       │   │ │
│  │  │  ──────────────────────────────────────                         │   │ │
│  │  │  PROFIT:                +91 ahn                                 │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ╔═════════════════════════════════════════════════════════╗                │
│  ║  DAY 1 TOTAL PROFIT:   +255 ahn                         ║                │
│  ╚═════════════════════════════════════════════════════════╝                │
│                                                                             │
│                          [ Continue to Day 2 ]                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Visual Notes — Results Phase:**
- Each design card shows a **dual pentagon overlay**: client's pentagon as a white outline, player's as an orange fill. Where orange extends beyond white = excess (green). Where white extends beyond orange = gap (red tint).
- Per-attribute breakdown beside the pentagon: `yours / theirs` with ✓ (covered) or ✗ (gap).
- **Overall overlap percentage** prominently displayed — this is the primary sell price multiplier.
- Profit breakdown in a clean table: material cost, base sell, overlap modifier, tag bonuses.
- Day total in a highlighted box at the bottom.
- `[Continue to Day 2]` advances; final day shows `[View Final Score]`.
- Multiple design cards stack vertically (scrollable).

**TGUI Mockup — Final Score Screen:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Augment Design Terminal — Performance Review                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                       ╔═══════════════════════════╗                         │
│                       ║   EMPLOYEE OF THE MONTH   ║                         │
│                       ╚═══════════════════════════╝                         │
│                                                                             │
│               "Your designs consistently matched client                     │
│                needs. Prostheti Innovations is proud                        │
│                to have you on the team."                                    │
│                                                                             │
│     ┌───────────────────────────────────────────────────┐                   │
│     │  Day 1:  Zwei Patrol Squad          +255 ahn      │                   │
│     │  Day 2:  Cinq Duelist               +410 ahn      │                   │
│     │  Day 3:  Budget Freelancer          +180 ahn      │                   │
│     │  ─────────────────────────────────────────────    │                   │
│     │  TOTAL PROFIT:                      +845 ahn      │                   │
│     └───────────────────────────────────────────────────┘                   │
│                                                                             │
│     Rankings:                                                               │
│      S: 3000+   "Master Artificer"                                          │
│      A: 2000+   "Expert Designer"                                           │
│      B: 1200+   "Competent Worker"       ◄── YOU                            │
│      C: 600+    "Adequate"                                                  │
│      D: 0+      "Break Even"                                                │
│      F: <0      "Net Loss"                                                  │
│                                                                             │
│     Fixer designs completed: 4                                              │
│                                                                             │
│                           [ Close Terminal ]                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Visual Notes — Final Score:**
- Centered ranking title in a decorative box. Corporate performance review tone.
- Flavor quote below ranking changes per tier.
- Day-by-day summary table with client name and profit.
- Ranking thresholds shown so the player sees where they landed.
- Fixer design count shown (gates Penny's introduction).
- `[Close Terminal]` closes the window.

**TGUI Mockup — Morning Briefing:**

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Augment Design Terminal — Morning Briefing                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                   ┌─────────────────────────────┐                       │
│                   │      TODAY'S CLIENT          │                       │
│                   │                              │                       │
│                   │   ╔══════════════════════╗   │                       │
│                   │   ║  ZWEI PATROL SQUAD   ║   │                       │
│                   │   ╚══════════════════════╝   │                       │
│                   │                              │                       │
│                   │   "We need augments that     │                       │
│                   │    keep our officers standing │                       │
│                   │    through long patrols.     │                       │
│                   │    Endurance is everything   │                       │
│                   │    — and they need to        │                       │
│                   │    maintain formation."      │                       │
│                   │                              │                       │
│                   │   Preferred Rank: 3-4        │                       │
│                   │   Required: [defensive]      │                       │
│                   └─────────────────────────────┘                       │
│                                                                         │
│    ┌─ TRENDING ─────────────┐  ┌─ OVERSATURATED ────────┐              │
│    │  ▲ SUPPORT      +8%    │  │  ▼ RISKY        -6%    │              │
│    │  ▲ HEALING      +8%    │  │  ▼ ON-KILL      -6%    │              │
│    └────────────────────────┘  └─────────────────────────┘              │
│                                                                         │
│    Price Changes Today:                                                 │
│    ● Regeneration ........... SALE -33% (27 ahn, was 40)                │
│    ● Defensive Prep ......... SALE -25% (38 ahn, was 50)                │
│    ● Blood Rush ............. MARKUP +40% (56 ahn, was 40)              │
│                                                                         │
│    Designs required today: 4                                            │
│                                                                         │
│                      [ Begin Designing ]                                │
└──────────────────────────────────────────────────────────────────────────┘
```

**Visual Notes — Morning Briefing:**
- First screen each work day. Player reads the client's **hint text** to deduce what attributes they need.
- Client name in a highlighted box with hint text (flavor description of needs), rank range, and required tags.
- **No pentagon shown** — the client's attribute pentagon is hidden until the Results phase.
- **Trending** and **Oversaturated** panels with reduced percentages (+8%/-6%).
- Required tags shown explicitly (e.g., "Required: [defensive]").
- `[Begin Designing]` transitions to the design workspace with live pentagon chart.

---

## Chapter Transition System

When players complete a chapter's objectives, the transition to the next chapter is announced using a screen blurb system modeled on the ordeal reveal in `code/modules/ordeals/_ordeal.dm` (`ShowOrdealBlurb`, lines 138-159). This gives the transition a cinematic weight — the screen darkens, text fades in, and players know something has changed.

**Trigger:** Each chapter defines a completion condition. When the condition is met, the campaign controller calls `CompleteChapter(chapter_number)` (see **Campaign Architecture** above), which plays this blurb as part of the transition.

**Chapter 1 Completion:** The chapter ends after the players have completed enough training duels with Penny and Hector. Tracked by `npc_vars.training_wins` — once it reaches a threshold (e.g., `training_wins >= 5`), the next time a duel ends, the transition fires. This means the chapter's pacing is driven by the training sparring, not the minigame — the augment design work is the day job, but the training is what moves the story forward.

**Blurb Display (per `ShowOrdealBlurb` pattern):**
1. For each player in `GLOB.player_list` with an active client:
   - A **black background overlay** (`obj/effect/overlay/ordeal`-style, icon `"black"` from `icons/hud/screen_gen.dmi`) is added to `client.screen`, covering a horizontal band across the center of the screen. Starts at `alpha = 0`, animates to `alpha = 175` over 10 ticks.
   - A **text overlay** (`obj/effect/overlay`) is added above the background, also starting at `alpha = 0` and animating to `alpha = 255` over 10 ticks. Uses `maptext` with styled spans:
     - **Line 1** (12pt, Baskerville): Campaign name — `"Prostheti Innovations"`
     - **Line 2** (14pt, Baskerville, bold): Chapter title — e.g., `"Paper Walls"`
     - **Line 3** (10pt, Baskerville): Chapter subtitle — e.g., `"The Test"`
   - Text color matches the chapter's tone (e.g., warm gold for Chapter 1, cold grey for Chapter 3)
   - A **transition sound** plays locally to each player via `playsound_local()`
2. After a duration (~4 seconds), both overlays fade out over `fade_time` ticks using `fade_blurb()` from `code/__HELPERS/unsorted.dm` (lines 1525-1529), which animates alpha to 0, sleeps, removes from screen, and qdels.

**After the Blurb:**
- The campaign controller calls `InitializeAtChapter(next_chapter)` (see **Campaign Architecture**):
  - All current chapter NPCs are qdel'd
  - The next chapter's NPC variants are spawned at their landmark positions
  - Each NPC variant's `Initialize()` handles its own setup (dialogue, doors, etc.)
- Players remain on the hub map — they are NOT teleported. The hub is the same map, just with new NPCs.
- The new chapter's opening dialogue or event begins (driven by the new NPC variants)

**Chapter Data:**
Each chapter stores its blurb info in the campaign controller:

| Chapter | Title | Subtitle | Text Color |
|---------|-------|----------|------------|
| 1 | Polished Surfaces | The Job | `"#FFD700"` (gold) |
| 2 | Paper Walls | The Test | `"#C0C0C0"` (silver) |
| 3 | Dead Letters | Roadside Rush | `"#8B0000"` (dark red) |
| 4 | Old Debts | The Shop | TBD |
| 5 | Boiling Point | TBD | TBD |
| 6 | Still Water | TBD | TBD |
| 7 | Ash and Iron | TBD | TBD |

**Fullscreen Mockup — Chapter Transition Blurb:**

This is NOT a TGUI window — it's a fullscreen overlay added directly to `client.screen`, using the same system as ordeal announcements. Players see this on top of the game world.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                          (game world dimmed)                            │
│                                                                         │
│                                                                         │
│   ███████████████████████████████████████████████████████████████████    │
│   █                                                                 █   │
│   █                                                                 █   │
│   █                     Prostheti Innovations                       █   │
│   █                          (12pt, Baskerville, chapter color)     █   │
│   █                                                                 █   │
│   █                        PAPER WALLS                              █   │
│   █                          (14pt, Baskerville, bold, white)       █   │
│   █                                                                 █   │
│   █                         The Test                                █   │
│   █                          (10pt, Baskerville, chapter color)     █   │
│   █                                                                 █   │
│   █                                                                 █   │
│   ███████████████████████████████████████████████████████████████████    │
│          (semi-transparent black band, alpha ~175)                      │
│                                                                         │
│                          (game world dimmed)                            │
│                                                                         │
└──────────────────────────────────────────────────────────────────────────┘
```

**Visual Notes — Chapter Blurb:**
- The black band covers a horizontal stripe across the center of the screen (~25% of screen height). The rest of the game world is still visible but feels "paused."
- Text fades in over ~1 second (10 ticks), holds for ~4 seconds, then fades out over ~1 second.
- Campaign name in the chapter's theme color (gold, silver, dark red, etc.). Chapter title in white, bold, larger. Subtitle in the chapter's theme color, smaller.
- A subtle transition sound plays (a low tone or chime) at the moment the text appears.
- All text is centered horizontally within the band.
- This overlay uses `SPLASHSCREEN_PLANE` to appear above all other HUD elements and fullscreens.

**Fullscreen Mockup — Broken Fate Wipe Screen:**

When all players die and the wipe triggers, this fullscreen overlay covers everything.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│                                                                          │
│                                                                          │
│                                                                          │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████                                      ██████████████████   │
│   ████████████         B R O K E N  F A T E         ██████████████████   │
│   ████████████                                      ██████████████████   │
│   ████████████    (large, white, Baskerville font)  ██████████████████   │
│   ████████████                                      ██████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│   ████████████████████████████████████████████████████████████████████   │
│                                                                          │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

**Visual Notes — Broken Fate:**
- **Full black screen** — no game world visible. Uses `show_when_dead = TRUE` so dead players see it too.
- "BROKEN FATE" text in large white Baskerville font, centered, letter-spaced. Appears over the black background.
- Both layers fade in simultaneously (alpha 0 → 255 over ~0.5 seconds).
- Holds for ~4 seconds, then fades out.
- After fade-out, players find themselves alive and fully healed back on the hub map.
- Uses `SPLASHSCREEN_PLANE` — above everything, including other fullscreens.

**Code Requirements:**
- `/datum/campaign_controller/prostheti` — defined in **Campaign Architecture** above. Manages chapter state, NPC variants, persistence, and chapter transitions
- `proc/ShowChapterBlurb(client/C, chapter_number)` — The blurb display proc, following the same overlay + animate + fade_blurb pattern as `ShowOrdealBlurb`. Called by `CompleteChapter()` during transitions.

---

## Chapter 2: Paper Walls

### Map

### Mobs

#### Hector — UI NPC (Chapter 2 Pre-Mission)

Hector is still in the Training Yard from Chapter 1. After the chapter transition blurb plays, Hector's dialogue gains a new scene gated behind a `npc_vars` flag set by the chapter controller (e.g., `npc_vars.chapter_2_started = TRUE`). This scene is where he proposes "the test."

**1. The Proposal (say() cutscene)**

When any player selects the new dialogue option on Hector (something like "What's on your mind?"), a say() cutscene triggers between Hector and Penny. This follows the same pattern as the Chapter 1 introduction cutscene:

- `in_cutscene = TRUE` on both Hector and Penny — all open TGUI sessions on both NPCs are force-closed, and no player can reopen dialogue on either until the cutscene ends
- Hector and Penny speak aloud via `say()` with `SLEEP_CHECK_DEATH` delays between lines
- Penny must be within range for the cutscene to trigger. Since she's permanently in the Training Yard after Chapter 1's introduction scene (`settled_in_yard = TRUE`), she's already nearby. If for some reason she isn't on the same z-level, the dialogue option should not appear.

**Cutscene Script (approximate):**
```
Hector: "Penny. You too — all of you. I need to talk to you about something."
  (2 second pause)
Hector: "You've been training hard. All of you have. But training only gets you so far."
  (2 second pause)
Hector: "There's a factory on the other side of the district. A competitor of your father's — they're developing a new augment line."
  (2 second pause)
Hector: "I want you to break in and destroy the blueprints."
  (2.5 second pause)
Penny: "You... you want us to break into a building?"
  (1.5 second pause)
Hector: "If you're serious about being a Fixer, you need to prove you can handle a real job. Not sparring in a yard."
  (2 second pause)
Penny: "That's not — Fixers take contracts. They don't just break into places."
  (2 second pause)
Hector: "And how do you think those contracts start? Someone needs something done. I'm telling you what needs doing. It has to be today."
  (2 second pause)
Penny: "...Alright. I'll do it."
```

- `in_cutscene = FALSE` on both NPCs after the script finishes

**2. Post-Cutscene Dialogue (TGUI)**

After the cutscene, both NPCs revert to standard TGUI dialogue with new scenes available:

**Hector's dialogue** gains a "mission briefing" scene with details about the competitor factory — where it is, how to get in, what they're looking for. Standard `SpeakingNpc` branching dialogue. Players can ask questions. At the bottom of the briefing, a dialogue action: **"We're ready. Let's go."** — this is the trigger that starts the mission.

**Penny's dialogue** gains a scene reflecting her nerves. She's committed but uneasy. Players can talk to her about it. She does NOT have a mission-start trigger — only Hector does, since it's his operation.

**3. Mission Start (proc_callback)**

When a player selects "We're ready" on Hector's dialogue:

1. `in_cutscene = TRUE` on both Hector and Penny — TGUI sessions force-closed on both
2. Short say() exchange:
```
Hector: "Good. Penny — you know the way. I'll stay here. This is your test, not mine."
  (2 second pause)
Penny: "You're not coming?"
  (1.5 second pause)
Hector: "You don't need me for this. Go."
```
3. `in_cutscene = FALSE`
4. The mission signup phase begins (see **Factory Mission Instance** below)
5. Hector stays behind in the Training Yard — he is NOT present during the infiltration. Narratively, this is when he secretly alerts Clyde.

**Variables:**
- `npc_vars.chapter_2_started` — set by chapter controller, gates the proposal dialogue option
- `npc_vars.proposal_complete` — set after the proposal cutscene, gates the mission briefing dialogue and Penny's nervous dialogue
- `npc_vars.mission_started` — set when "We're ready" is selected, prevents re-triggering

#### Factory Mission Instance

The competitor factory infiltration is handled by a mission instance datum that manages player signup, map loading, teleportation, and participant tracking. This system uses the existing map template loader (`code/modules/mapping/map_template.dm` — `load_new_z()`) and z-level manager (`code/modules/mapping/space_management/zlevel_manager.dm`).

**Mission Datum:** `/datum/prostheti_mission/factory_infiltration` — created when the "We're ready" cutscene ends.

**1. Signup Phase**

After the cutscene, a signup window opens before the map loads. Players must opt in — they are not forced into the mission.

- A rally point object spawns in the Training Yard: `/obj/structure/mission_rally/factory_infiltration`. This is a visible, interactable object (e.g., a marker or Penny standing at the exit with a "Follow Penny" click action).
- When a player clicks the rally point, they are added to the mission datum's `participants` list. The rally point shows a message: `"[player.name] is joining the mission. ([current]/4)"`
- **Max 4 players.** Once 4 players have signed up, the rally point stops accepting new entries and displays `"The team is full."`
- A **30-second timer** starts when the first player signs up. When it expires, signup closes regardless of how many players joined (minimum 1). Alternatively, the first player who signed up can click the rally point again to select `"Everyone's here"` to close signup early.
- Players who don't sign up stay on the Prostheti Innovations map — they can still use the augment minigame, talk to Clyde, etc. They are spectators to this chapter's action.
- The rally point is qdel'd after signup closes.

**2. Map Loading**

After signup closes, the mission datum loads the competitor factory map:

- Creates a `/datum/map_template` pointing to the factory .dmm file (path TBD, e.g., `_maps/templates/prostheti_campaign/competitor_factory.dmm`)
- Calls `template.load_new_z()` — this allocates a new z-level via `SSmapping.add_new_zlevel(name, list(ZTRAIT_AWAY = TRUE))`, loads the .dmm file onto it, and initializes all atoms
- Stores the returned `/datum/space_level` reference in `factory_level`

**Map-Placed Landmarks on the Factory Map:**

| Type Path | Count | Purpose |
|-----------|-------|---------|
| `/obj/effect/landmark/factory_mission/player_spawn` | 4 | One per player slot — players are assigned to spawns in signup order |
| `/obj/effect/landmark/factory_mission/penny_spawn` | 1 | Where Penny's companion mob spawns |

Each landmark adds its turf to a list on the mission datum and qdels, same pattern as `penny_waypoint`.

**3. Teleportation**

Once the map is loaded and landmarks are resolved:

- Each participant's current turf is stored: `return_turfs[player_mob] = get_turf(player_mob)`
- Each participant is `forceMove`'d to the next available `player_spawn` turf (assigned in signup order, so the first player to sign up gets spawn 1, etc.)
- **Penny's companion mob** is spawned and `forceMove`'d to `penny_spawn` (see below)
- The Chapter 2 transition blurb plays for all participants during the teleport

**4. Penny as Combat Companion**

Penny's `ui_npc` mob (the dialogue NPC from Chapter 1) is NOT teleported into the factory. Instead, a separate combat-capable companion mob is used, following the same pattern as the Elliot/Joshua NPC in `code/modules/mob/living/simple_animal/friendly/elliot_npc.dm`:

- **Type:** `/mob/living/simple_animal/hostile/ui_npc/penny_companion` — a `ui_npc` subtype that is ALSO hostile. This means she has both TGUI dialogue AND combat AI, just like Elliot.
- Spawned by the mission datum on the factory map at `penny_spawn`. This is a completely separate mob from Chapter 1's Penny — different type path, different dialogue scenes, different stats. Penny's Chapter 1 `ui_npc` mob is moved to nullspace for the duration of the mission.
- The companion mob is qdel'd when the mission ends and players are returned.

**Combat/Dialogue Toggle (per Elliot pattern):**
- In `Life()`: when `!target` (no enemy to fight), calls `speaking_on()` to enable TGUI dialogue and sets `density = TRUE`. Players can click her to talk.
- In `Life()`: when `target` exists (in combat), calls `speaking_off()` to disable TGUI dialogue and sets `density = FALSE`. Players cannot open her dialogue mid-fight.
- This means Penny is interactable between encounters but fully focused on combat during fights.

**Following Players:**
- `var/mob/living/Leader` — reference to the player she follows, set to the first participant by default
- When `!target` and `Leader` exists, uses `step_to(src, Leader)` to follow them (same as Elliot's `follow_leader()`)
- If Leader is out of vision range, teleports nearby (Elliot's `TeleportToSomeone()` pattern) to avoid getting stuck behind closed doors or across the map

**Dialogue Scenes (TGUI):**
- Shared dialogue state (same as all campaign NPCs). Scenes change based on mission progress — different dialogue before the trap, different after.
- Players can talk to Penny during quiet moments between encounters to get her reactions, hear her nerves, ask about the factory. This makes her feel like a real companion, not just a combat bot.
- Key scenes gated behind `npc_vars` flags set by the mission datum as segments progress (e.g., `npc_vars.entered_office = TRUE` unlocks new dialogue about the trap)

**Downed System (instead of death):**
- Penny does NOT die during the infiltration — she uses a downed system like Elliot's `Downed()` / `Unstun()` procs
- When health reaches 0: `can_act = FALSE`, `status_flags |= GODMODE`, icon switches to a downed sprite, she says a downed line. She does NOT actually die.
- Players can revive her by interacting (help intent click + `do_after()` timer), same as Elliot's `attack_hand()` revive pattern
- During the boss fight, her downed state is scripted — when the Factory Director drops to 400 HP, his `ExecutePenny()` proc dashes to Penny and force-calls her `Downed()`. She cannot be revived by players during this sequence. This is the story beat where she's nearly killed before the Zwei intervene (see **Factory Director — Phase Transition** under Hazards).

**Scripted Say() Lines:**
- Penny has contextual `say()` lines triggered by the mission datum at key moments (entering new areas, spotting enemies, the trap reveal). These fire via `INVOKE_ASYNC` from the mission datum, not from dialogue.

**5. Participant Tracking & Broken Fate**

The mission datum tracks all participants throughout the mission:

- `var/list/mob/living/participants` — the player mobs inside the factory (max 4)
- If a player disconnects, their mob stays in the instance — they can reconnect and resume
- If a player dies/is downed during the mission, they stay on the factory z-level. No automatic extraction until the Zwei arrive (this is a story beat — the players are supposed to feel trapped)
- The mission datum registers signals on each participant for `COMSIG_MOB_STATCHANGE` to track downed players and trigger scripted events (e.g., Penny getting caught happens when enough players are downed)

**Broken Fate integration:** `/datum/prostheti_mission/factory_infiltration` inherits the Broken Fate system from the base `/datum/prostheti_mission` (see **Reusable Systems** section above). If all players die during the infiltration, the "Broken Fate" screen plays, the z-level is reset in place (all mobs qdel'd and respawned from landmarks), and players are revived and teleported back to the hub. The z-level stays loaded — players can talk to Hector again and re-enter, teleporting back to the same z-level without reloading the map. During the boss fight, `SetWipeEnabled(FALSE)` is called because the players are supposed to lose — the Zwei rescue is the scripted outcome, not a reset. The `OnBrokenFate()` override on this subtype handles: resetting the office door/trap state on the z-level, resetting `npc_vars.mission_started` so Hector's trigger works again, and moving Penny's Chapter 1 `ui_npc` back from nullspace.

**Mission Datum Variables:**

| Variable | Type | Purpose |
|----------|------|---------|
| `participants` | `list/mob/living` | Signed-up players, max length 4 |
| `return_turfs` | assoc list | Maps each participant mob → their original turf before teleport |
| `factory_level` | `/datum/space_level` | The loaded factory z-level |
| `factory_template` | `/datum/map_template` | The factory map template |
| `penny_companion` | `/mob/living/simple_animal/hostile/ui_npc/penny_companion` | Penny's combat + dialogue companion mob |
| `mission_state` | define | `MISSION_SIGNUP`, `MISSION_LOADING`, `MISSION_ACTIVE`, `MISSION_COMPLETE` |
| `spawn_turfs` | `list/turf` | Player spawn turfs from landmarks |
| `penny_spawn_turf` | `turf` | Penny's companion spawn turf from landmark |

### Hazards

#### Factory Mobs — Tremor-Themed Enemies

**File:** `ModularLobotomy/campaigns/prostheti/mobs/factory_mobs.dm`

**Design Philosophy:** Melee attacks on ALL factory mobs build tremor stacks but use an impossibly high burst threshold (999) so they NEVER trigger TremorBurst on their own. Only the heavy variant's and director's AoE abilities use real burst thresholds (25+) that CAN detonate accumulated stacks. The base worker has no abilities — it's pure melee accumulation, dangerous in groups because multiple workers stacking tremor on a player set up the heavy/boss to detonate.

**Tremor Reference:** `apply_lc_tremor(stacks, tremorburst_threshold)` — each stack = 10% movespeed slowdown. TremorBurst at threshold = Knockdown (humans) or 5×stacks brute (mobs). From `code/datums/status_effects/debuffs.dm`.

---

**1. Factory Worker (Base)** — `/mob/living/simple_animal/hostile/prostheti/factory_worker`

| Stat | Value |
|------|-------|
| Health | 150 |
| Melee Damage | 8-12 RED_DAMAGE |
| Speed | `move_to_delay = 4` (moderate) |
| Tremor on Hit | `apply_lc_tremor(2, 999)` — 2 stacks per punch, never bursts |
| Faction | `list("prostheti_competitor")` |
| Damage Coefficients | RED 1.0, WHITE 1.2, BLACK 0.5, PALE 2.0 |

- **No special abilities.** Simple melee mob.
- Resistant to BLACK (augmented for tremor), weak to WHITE and PALE.
- Dangerous in groups — 3 workers hitting the same player build tremor fast, setting up the heavy's slam or the director's abilities to detonate.
- Flavor: Basic augmented factory workers, "walking product demonstrations" of the competitor's hardware. Augmented arms deliver tremor on every hit.

---

**2. Factory Worker (Heavy Variant)** — `/mob/living/simple_animal/hostile/prostheti/factory_worker/heavy`

| Stat | Value |
|------|-------|
| Health | 250 |
| Melee Damage | 12-18 RED_DAMAGE |
| Speed | `move_to_delay = 6` (slow) |
| Tremor on Hit | `apply_lc_tremor(3, 999)` — 3 stacks per hit, never bursts |
| Faction | `list("prostheti_competitor")` |
| Damage Coefficients | RED 0.8, WHITE 1.2, BLACK 0.5, PALE 2.0 |

- **Special Ability — Ground Slam:** `OpenFire()` → `GroundSlam()` proc
  - Cooldown: 12 seconds
  - Range check: only triggers if target within 3 tiles
  - AoE: 2 tile radius around self
  - Effect: 15 RED_DAMAGE + `apply_lc_tremor(5, 25)` to all non-faction mobs in AoE — 5 stacks with burst threshold 25. If players have accumulated 25+ tremor from melee hits, this detonates them.
  - Animation: pixel_y raise + slam back down, visual effect on ground tiles, sound effect
  - `can_act = FALSE` during animation, re-enabled after
- Tougher than base worker (RED 0.8 — augments absorb physical hits).
- Flavor: Foremen or heavy-duty workers with industrial-grade augments. Slower but hit harder, bigger AoE slam.

---

**3. Factory Director (Boss)** — `/mob/living/simple_animal/hostile/prostheti/factory_director`

| Stat | Value |
|------|-------|
| Health | 2400 |
| Melee Damage | 15-22 BLACK_DAMAGE |
| Speed | `move_to_delay = 3` (fast for a boss) |
| Tremor on Hit | `apply_lc_tremor(4, 999)` — 4 stacks per hit, never bursts |
| Faction | `list("prostheti_competitor")` |
| Damage Coefficients | RED 0.8, WHITE 1.0, BLACK 0.3, PALE 1.5 |

Uses BLACK_DAMAGE instead of RED — his augments are the company's top-line. Very resistant to BLACK (0.3), moderately tough otherwise.

**Ability 1 — Seismic Dash:** `OpenFire()` → `SeismicDash()` proc
- Cooldown: 8 seconds
- Range: 3-7 tiles from target
- Dashes along a line to target (`forceMove` along `getline` turfs), deals 20 RED_DAMAGE + `apply_lc_tremor(6, 25)` to all mobs on the path and at landing point within 1 tile AoE
- Burst threshold 25 — this is the director's primary tremor detonator. If a player has accumulated 25+ tremor from melee hits, the dash detonates them.
- Animation: pixel_y jump up, dash along line, slam down at target
- `can_act = FALSE` during dash

**Ability 2 — Seismic Eruption:** Separate cooldown proc
- Cooldown: 15 seconds
- **Targeting:** Picks 3-4 random turfs within `view(5)` around the director, PLUS 3-4 random turfs within 2 tiles of each enemy (non-faction mob) he can see. This creates danger zones both near the boss and near every player.
- **Warning phase:** A temporary warning visual (`/obj/effect/temp_visual`) is placed on each selected turf — a visible ground marker (e.g., a glowing crack or tremor ripple sprite) that lasts 1.5 seconds. Players can see these and move off them.
- **Detonation phase:** After 1.5 seconds, each warning turf is checked. For each mob standing on a warning turf:
  1. The mob is launched into the air: `animate(victim, pixel_y = victim.base_pixel_y + 32, time = 3)` then `animate(pixel_y = victim.base_pixel_y, time = 3)` — up 32 pixels then back down
  2. After landing (6 ticks total), their tremor is forcibly burst: find their `/datum/status_effect/stacking/lc_tremor` and call `TremorBurst()` on it. If they have no tremor stacks, the launch still happens but no burst occurs.
  3. Small RED_DAMAGE (10) on landing regardless of tremor state
- Say line: `"The ground remembers every step."` before placing warnings
- `can_act = FALSE` during the full sequence (warning placement → detonation)
- This is the director's signature ability — telegraphed and dodgeable (move off the warning tiles), but if players don't react in 1.5 seconds, their accumulated tremor gets forcibly detonated. The turfs around each enemy mean you can't just stay away from the boss — he targets the ground under your feet too.

**Phase Transition — Execute Penny (at 400 HP):**

The director tracks his health via `COMSIG_MOB_AFTER_APPLY_DAMGE`. When his health drops to 400 or below, `var/execution_triggered = FALSE` flips to `TRUE` and the execution sequence begins. This only fires once — further damage below 400 does not re-trigger.

- **Step 1 — Director seizes Penny:**
  - The director's `execution_triggered` flag stops all normal combat behavior (his `AttackingTarget()`, `OpenFire()`, and ability procs all check `if(execution_triggered) return`)
  - The director dashes to Penny's location (same `forceMove` along `getline` pattern as Seismic Dash, but targeting `penny_companion` specifically)
  - On arrival, the director grabs Penny: Penny is force-downed via her `Downed()` proc (`status_flags |= GODMODE`, downed icon). She CANNOT be revived by players during this sequence.
  - The director says: `"You brought children into my factory. Let me show you what happens to trespassers."`

- **Step 2 — Execution windup:**
  - The director plays a windup animation (e.g., arm raised, pixel_y shift, charging visual effect) — this lasts ~3 seconds, giving players a visible "he's about to kill her" moment
  - Penny says a downed line: `"Run... just run!"`
  - Players can still attack the director during the windup, but it does NOT cancel the execution — the director has `status_flags |= GODMODE` during this phase. The fight is meant to be unwinnable at this point.

- **Step 3 — Zwei Breach (cutscene, handled by mission datum):**
  - The mission datum detects the execution trigger via `COMSIG_DIRECTOR_EXECUTION` and calls `SetWipeEnabled(FALSE)` — Broken Fate is disabled from this point on
  - After the 3-second windup completes, instead of Penny dying, the Zwei rescue cutscene fires. All players are frozen via `ADD_TRAIT(player, TRAIT_IMMOBILIZED, "zwei_cutscene")` for the duration — this is a watch-only moment.

  **3a — Door Breach:**
  - The office door that trapped the players inside (locked by the director when the ambush triggered) is smashed open from the outside. The door object is force-opened and visually destroyed: `door.open()` followed by replacing it with a broken/debris state or qdel + `/obj/effect/temp_visual/smash_effect` for debris. A loud breach sound plays via `playsound()`.
  - The director's execution animation is interrupted — his windup stops, he staggers back from Penny (`animate(director, pixel_x = pixel_x - 16, time = 2)` — knocked sideways).
  - The director says: `"What—?!"`

  **3b — Zwei Squad Spawns:**
  - 4 Zwei Fixer mobs spawn at the doorway, walking into the room in sequence with short `SLEEP_CHECK_DEATH(3)` delays between each:
    - **Lead Fixer** — `/mob/living/simple_animal/hostile/prostheti/zwei_lead` — uses a Zwei Director sprite (`icon_state` referencing the Zwei Director look). Stronger than the others — this is the one who kills the director.
    - **3 Zwei Fixers** — `/mob/living/simple_animal/hostile/prostheti/zwei_fixer` — uses a standard Zwei Fixer sprite (`icon_state` referencing the Zwei shield look). Their job is to clean up remaining factory workers.
  - All Zwei mobs have `faction = list("zwei", "neutral")` — hostile to `"prostheti_competitor"` faction, not hostile to players.
  - The lead Fixer says as she enters: `"Zwei Association — contract fulfilled. Area secured."`

  **3c — Cleanup (parallel actions):**
  - The 3 standard Zwei Fixers spread out and engage any remaining factory workers still alive in the office. They are significantly overpowered compared to the workers — each Zwei Fixer has high HP (500+), heavy melee damage, and the workers die in 2-3 hits. This is intentionally one-sided. The players just struggled through these same enemies — the Zwei tear through them effortlessly. This is the moment that makes "the gap between Penny's training and real Fixer work painfully clear."
  - While the squad cleans up, the lead Fixer walks toward the director. The director is still staggered from the door being smashed in — his `execution_triggered` flag keeps him in the non-combat scripted state. He does not fight back.

  **3d — Execution:**
  - The lead Fixer stops adjacent to the director.
  - The director says: `"This is my factory. You have no authority—"`
  - The lead Fixer says: `"Contract says otherwise."`
  - A brief pause (`SLEEP_CHECK_DEATH(10)` — 1 second).
  - The lead Fixer executes the director: a single shotgun blast — `playsound()` for the gunshot, a screen shake via `shake_camera()` on all participants, and the director is killed (`director.death()`). The director's mob is qdel'd after a short delay.
  - This is blunt and efficient. No dramatic duel, no drawn-out fight. One line of dialogue, one shot. The Zwei are professionals — this is a job, not a battle.

  **3e — Aftermath & Extraction:**
  - Once all factory workers are dead and the director is executed, the Zwei Fixers stop fighting and stand in place.
  - The lead Fixer walks to Penny. Penny is still downed on the ground.
  - The lead Fixer says: `"Target secured. Get her up."`
  - One of the standard Zwei Fixers revives Penny — calls `penny_companion.Unstun()` to bring her back to her feet. GODMODE removed, icon returned to normal.
  - Penny says: `"I... we had it under control."`
  - The lead Fixer says nothing. She turns and walks back toward the doorway.
  - A brief pause (`SLEEP_CHECK_DEATH(20)` — 2 seconds).
  - Players regain movement (`REMOVE_TRAIT(player, TRAIT_IMMOBILIZED, "zwei_cutscene")`).
  - The mission datum sets `npc_vars.zwei_rescued = TRUE` — this gates new dialogue on Penny's companion mob if players talk to her before extraction.
  - Penny's companion dialogue (if opened) has a short scene: she's shaken, defensive, trying to process what just happened. She insists they should leave.
  - **Extraction:** After a short window for players to talk to Penny (~30 seconds, or triggered early if a player clicks the now-open doorway), the mission datum starts the extraction sequence:

  **Fade to Black:**
  1. All participants get a black fullscreen overlay: `overlay_fullscreen("extraction", /atom/movable/screen/fullscreen/cinematic_backdrop)` — full black, `show_when_dead = TRUE`
  2. Hold black for ~3 seconds (`SLEEP_CHECK_DEATH(30)`)

  **Factory Cleanup (while screen is black):**
  3. All Zwei Fixer mobs are qdel'd
  4. Penny companion mob is qdel'd
  5. The factory z-level is cleaned up (all remaining mobs/objects qdel'd, z-level freed)

  **Medical Wing Setup (while screen is still black):**
  6. Players are `forceMove`'d to the Prostheti Innovations medical wing — a section of the Chapter 1 map with medical beds. Each player is placed on a bed turf and force-buckled: `bed.buckle_mob(player, force = TRUE)`. Buckled players are lying down and cannot move until unbuckled.
  7. Players are fully healed: `revive(full_heal = TRUE)` — clears all damage, status effects, tremor stacks, everything from the factory fight.
  8. Penny's Chapter 1 `ui_npc` mob is moved from nullspace to a medical bed in the same room and force-buckled: `bed.buckle_mob(penny_npc, force = TRUE)`. She is visible to the players, lying in a bed near them.
  9. Clyde's `ui_npc` mob is moved from his office to the medical wing — standing beside Penny's bed, not buckled. He's been waiting.

  **Fade In — Wake Up:**
  10. Black overlay fades out: `clear_fullscreen("extraction", animated = 15)` — slow fade over ~1.5 seconds. Players "wake up" in the medical wing, buckled to beds, and see Penny in a nearby bed with Clyde standing over her.
  11. Players remain buckled and `TRAIT_IMMOBILIZED` remains active — they can look around but cannot move or interact. They are forced witnesses to what comes next.

  **Clyde Confrontation (say() cutscene — players overhear):**
  12. After a brief pause (~2 seconds), Clyde and Penny's confrontation plays out as a `say()` cutscene. Players are in the room but not part of the conversation — they're injured employees in beds, overhearing a father tear apart his daughter's trust.

  ```
  Clyde: "You're awake. Good."
    (2 second pause)
  Penny: "Dad? What... where are we?"
    (1.5 second pause)
  Clyde: "The medical wing. The Zwei brought you back. All of you."
    (2 second pause)
  Penny: "How did you know where we—"
    (1.5 second pause)
  Clyde: "I've known about Hector since the first letter."
    (3 second pause — this lands hard)
  Penny: "...What?"
    (1.5 second pause)
  Clyde: "Every letter you sent. Every letter he sent back. I've been reading them for over a year."
    (2 second pause)
  Penny: "You... you read my letters?"
    (2 second pause)
  Clyde: "I intercepted them. Copied them. Put them back before you noticed. The training, the combat drills, the fixer talk — I knew all of it."
    (2.5 second pause)
  Penny: "Then why didn't you stop me?!"
    (2 second pause)
  Clyde: "Because combat skills are useful for a CEO. And because I hoped you'd come to your senses on your own."
    (2 second pause)
  Penny: "You let me think I had a secret. You let me think I was doing something on my own for once in my life."
    (2 second pause)
  Clyde: "You were never in danger until today. The moment I learned you entered that factory, I deployed the Zwei. That deployment cost more Ahn than most Backstreets workers see in a year. I spent it without hesitation."
    (2 second pause)
  Penny: "I didn't ask you to do that."
    (1.5 second pause)
  Clyde: "You didn't have to."
    (3 second pause)
  Penny: "A year. A whole year you could have just... talked to me."
    (2 second pause)
  Clyde: "..."
    (3 second pause — Clyde has no answer for this)
  ```

  13. After the last line, a long pause (~4 seconds of silence). Clyde turns and walks out of the medical wing. He does not look back.
  14. Penny says nothing. She's still in the bed.
  15. Players are unbuckled: `bed.unbuckle_all_mobs()` on each bed, and `REMOVE_TRAIT(player, TRAIT_IMMOBILIZED, "zwei_cutscene")`. They can now move freely.
  16. Penny's `ui_npc` becomes interactable again — `in_cutscene = FALSE`. If players talk to her now, she has a short post-confrontation dialogue scene. She's devastated. She doesn't cry — she's just hollow. She says something like: `"He knew. The whole time, he knew."` The dialogue has no branching — just a few lines of Penny processing. Players cannot fix this.

  **State Updates:**
  17. `npc_vars.clyde_confrontation_complete = TRUE` — gates new dialogue on Clyde, Penny, and Hector
  18. `mission_state = MISSION_COMPLETE`
  19. Clyde returns to his office (walks back or `forceMove`). His dialogue is updated — he's cold, matter-of-fact. He believes he did the right thing. He will never apologize for the surveillance, only for not stopping her sooner.
  20. Hector is still in the Training Yard. His dialogue is updated — he's concerned, supportive, warm. Everything a father should have been. This is by design — his manipulation depends on the contrast.

  **Map-Placed Objects for Medical Wing (added to Chapter 1 map):**

  | Type Path | Zone | Count | Purpose |
  |-----------|------|-------|---------|
  | `/obj/structure/bed/medical_wing` | Medical Wing | 4 | One per player slot — players are buckled here after extraction |
  | `/obj/structure/bed/medical_wing/penny_bed` | Medical Wing | 1 | Penny's bed — she's buckled here for the confrontation |
  | `/obj/effect/landmark/medical_wing/player_bed` | Medical Wing | 4 | Marks which bed each player is assigned to (signup order) |
  | `/obj/effect/landmark/medical_wing/penny_bed` | Medical Wing | 1 | Marks Penny's bed position |
  | `/obj/effect/landmark/medical_wing/clyde_stand` | Medical Wing | 1 | Where Clyde stands during the confrontation (beside Penny's bed) |

**Zwei Mob Types (spawned by cutscene, not by spawn landmarks):**

These mobs are NOT placed on the map via spawn landmarks — they are created by the mission datum's cutscene proc and only exist for the rescue sequence.

| Type Path | Count | Stats | Purpose |
|-----------|-------|-------|---------|
| `/mob/living/simple_animal/hostile/prostheti/zwei_lead` | 1 | 800 HP, high damage, Zwei Director sprite | Executes the director |
| `/mob/living/simple_animal/hostile/prostheti/zwei_fixer` | 3 | 500 HP, moderate damage, Zwei Fixer sprite | Clean up remaining workers |

Both types: `faction = list("zwei", "neutral")`, hostile to `"prostheti_competitor"`. They do NOT attack players. They are qdel'd during extraction.

- **Implementation:** The director's mob holds a `var/mob/living/penny_ref` reference to the Penny companion, set by the mission datum when the boss fight segment begins. The `COMSIG_MOB_AFTER_APPLY_DAMGE` handler checks `if(health <= 400 && !execution_triggered)` and calls `ExecutePenny()`. The mission datum registers on the director for `COMSIG_DIRECTOR_EXECUTION` — when received, it runs the full Zwei rescue cutscene as a single async proc (`ZweiRescue()`) via `INVOKE_ASYNC`.

**Fight Dynamic:** The director has 2400 HP and two ways to detonate tremor — his dash (burst threshold 25, requires closing distance) and Seismic Eruption (telegraphed ground markers that forcibly burst tremor on anyone standing on them after 1.5 seconds). The dash is fast and direct; the eruption is dodgeable but covers a wide area around both the boss and every player. Players need to stay mobile to dodge eruption tiles, manage their tremor decay between engagements, and avoid clustering (his dash hits in a line). The 25-stack threshold on the dash means players have a window to react to melee tremor buildup, while the eruption punishes anyone who stops moving regardless of stack count.

At 400 HP, the fight shifts from combat to cutscene — the director seizes Penny and attempts to execute her, triggering the Zwei rescue. Players are meant to fight the director down from 2400 to 400 (dealing 2000 damage total), but the last 400 HP is never actually depleted by them — the Zwei handle the rest. This gives players agency in the fight (they're genuinely fighting and making progress) while ensuring the scripted rescue always happens at the right moment.

---

**Mob Spawn Landmarks (placed on factory mission map):**

| Type Path | Count | Purpose |
|-----------|-------|---------|
| `/obj/effect/landmark/mission_mob_spawn` (mob_type = factory_worker) | 6-8 | Base workers across infiltration floors |
| `/obj/effect/landmark/mission_mob_spawn` (mob_type = factory_worker/heavy) | 2-3 | Heavy workers at key chokepoints |
| `/obj/effect/landmark/mission_mob_spawn` (mob_type = factory_director) | 1 | Boss — spawns in the director's office for the trap segment |

These use the persistent landmark system from **Reusable Systems** — each landmark spawns its mob on mission load, persists for respawning on Broken Fate reset, and defines which segment it belongs to.

### Extra Gameplay

### Sprites Required — Chapter 2

#### NPC World Sprites (32x32)

| Sprite | Description | Notes |
|--------|-------------|-------|
| **Penny Companion (Combat)** | Penny in combat gear — lighter armor, maybe a jacket with Prostheti branding. Should be recognizably Penny but geared up. | `/mob/living/simple_animal/hostile/ui_npc/penny_companion`. Separate mob from Ch1 Penny. Needs attack animation + **downed sprite** (lying on ground). |
| **Penny Companion (Downed)** | Penny collapsed/lying down. Clear visual that she's incapacitated but not dead. | Used when `Downed()` is called. Players see this during the execution sequence. |

#### NPC Portraits (192x192, TGUI dialogue)

| Portrait | Description | Notes |
|----------|-------------|-------|
| **Penny Companion** | Same as Ch1 Penny portrait, OR a variant showing her in combat gear / slightly more determined expression. | Used for companion dialogue during the mission. Could reuse Ch1 portrait. |

#### Enemy Mob Sprites (32x32, all need attack animations)

| Sprite | Description | Notes |
|--------|-------------|-------|
| **Factory Worker (Base)** | Augmented factory worker. Industrial clothing with visible mechanical arm augments (the source of their tremor punches). Generic worker look — these are "walking product demonstrations." | 6-8 placed on the away mission map. Simple melee mob. Needs a punching/melee animation. |
| **Factory Worker (Heavy)** | Bigger, bulkier version of the base worker. Heavier augments, industrial-grade — foreman or heavy-duty look. Visually distinct from the base worker (larger frame, more metal). | 2-3 placed at chokepoints. Needs a **Ground Slam animation** (raised arms → slam down). |
| **Factory Director (Boss)** | The competitor factory's director. Top-line augments — sleek, expensive, BLACK-damage themed. Corporate-executive-meets-combat-cyborg. Imposing, fast-looking despite being a boss. | 1 per mission. Needs: **Seismic Dash animation** (jump up → dash along line → land), **Seismic Eruption windup** (charging pose), **Execution windup** (arm raised, about to strike), **Stagger** (knocked sideways when Zwei smash in the door). |

#### Ally Mob Sprites (32x32)

| Sprite | Description | Notes |
|--------|-------------|-------|
| **Zwei Lead Fixer** | Zwei Director look — professional, armored, efficient. Shotgun visible. Should immediately read as "the adults have arrived." | References existing Zwei Director sprite — may be able to reuse/recolor from `zwei_director` if one exists. 1 spawned during rescue cutscene. |
| **Zwei Standard Fixer** | Zwei shield/patrol look — standard Zwei fixer gear with shield. | References existing Zwei Fixer sprite — may be able to reuse from existing Zwei outfit sprites. 3 spawned during rescue cutscene. |

#### Visual Effects (temp_visuals, animations)

| Sprite | Description | Notes |
|--------|-------------|-------|
| **Ground Slam Impact** | AoE ground effect for the Heavy's Ground Slam. Cracks/shockwave ripple on tiles within 2-tile radius. Brief flash, then fades. | `/obj/effect/temp_visual`. Appears on ground tiles during slam. |
| **Seismic Eruption Warning** | Glowing crack or tremor ripple ground marker. Placed on targeted turfs during the Director's Eruption ability. Must be clearly visible — this is the "move or die" telegraph. Lasts 1.5 seconds. | `/obj/effect/temp_visual`. Bright enough to read in combat. Could pulse or glow. |
| **Seismic Dash Trail** | Optional trail/impact effect along the Director's dash line. Cracked ground or tremor wake. | Could be a series of temp_visuals along `getline()` turfs. |
| **Door Breach Debris** | Debris/dust cloud at the office doorway. The locked door is smashed inward — splinters, metal fragments, dust. Brief visual. | `/obj/effect/temp_visual/smash_effect`. Placed when the Zwei smash the office door during the rescue. |
| **Mission Rally Point** | A visible marker object in the Training Yard for the mission signup phase. Could be a Penny-shaped silhouette at the exit, a glowing beacon, or a simple rally flag. | `/obj/structure/mission_rally/factory_infiltration`. Qdel'd after signup. |

---

## Chapter 3: Dead Letters

### Map

### Mobs

### Hazards

### Extra Gameplay

### Sprites Required — Chapter 3

TBD

---

## Chapter 4: Old Debts

### Map

### Mobs

### Hazards

### Extra Gameplay

### Sprites Required — Chapter 4

TBD

---

## Chapter 5: Boiling Point

### Map

### Mobs

### Hazards

### Extra Gameplay

### Sprites Required — Chapter 5

TBD

---

## Chapter 6: Still Water

### Map

### Mobs

### Hazards

### Extra Gameplay

### Sprites Required — Chapter 6

TBD

---

## Chapter 7: Ash and Iron

### Map

### Mobs

### Hazards

### Extra Gameplay

### Sprites Required — Chapter 7

TBD

---
