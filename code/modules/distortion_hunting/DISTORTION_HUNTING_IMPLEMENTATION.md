# Distortion Hunting System - Implementation Plan

---

## 1. Overview

This document outlines the technical implementation roadmap for the Distortion Hunting system in LC13. The system is divided into manageable phases, each building on the previous to create a complete investigation and combat experience.

**Core Components:**
- Investigation datum system
- Evidence clue items with UI
- Investigation Scanner machines
- Portfolio/Dossier TGUI interface
- Clue spawning system
- Progress tracking and rewards
- Distortion encounter maps

---

## 2. File Structure

```
code/modules/distortion_hunting/
├── distortion_investigation.dm          # Core investigation datum
├── distortion_config.dm                 # Base config datum
├── configs/
│   └── another_day_at_work.dm          # Example distortion config
├── items/
│   ├── clue_base.dm                    # Base clue item type
│   └── clues_another_day.dm            # Another Day at Work clues
├── machinery/
│   └── investigation_scanner.dm        # Scanner machine
└── ui/
    └── portfolio.dm                     # Portfolio TGUI interface

code/game/objects/effects/landmarks/
└── clue_spawn.dm                        # Clue spawn landmarks

tgui/packages/tgui/interfaces/
└── DistortionPortfolio.tsx              # React portfolio UI
```

---

## 3. Implementation Phases

### Phase 1: Core Data Structures (Foundation)
**Goal:** Create the fundamental datum systems that store investigation data

**Estimated Time:** 2-3 hours

**Files to Create:**
- `code/modules/distortion_hunting/distortion_config.dm`
- `code/modules/distortion_hunting/distortion_investigation.dm`

**Tasks:**

#### 3.1.1 Create Base Distortion Config Datum
```dm
/datum/distortion_config
    var/distortion_name = "Unknown Distortion"
    var/distortion_category = "uncategorized"
    var/primary_theme = "Unknown theme"

    // Evidence types this distortion can spawn
    var/list/allowed_evidence_types = list()

    // Randomized traits (surface details)
    var/list/randomized_trait_pools = list()

    // Spawn weights for each clue type
    var/list/clue_spawn_weights = list()
```

#### 3.1.2 Create Investigation Datum
```dm
/datum/distortion_investigation
    var/datum/distortion_config/config
    var/list/profile_data = list()           // Stores randomized trait values
    var/list/unlocked_fields = list()        // Which fields player has unlocked
    var/list/spawned_clues = list()          // Track spawned clue objects
    var/investigation_progress = 0           // 0-100% progress
    var/active = FALSE

    /datum/distortion_investigation/New(datum/distortion_config/config_type)
        // Initialize investigation
        // Randomize traits from pools
        // Set up initial state

    /datum/distortion_investigation/proc/RandomizeTraits()
        // Pick random values from config's trait pools
        // Store in profile_data

    /datum/distortion_investigation/proc/UnlockFields(list/fields)
        // Add fields to unlocked_fields
        // Update progress

    /datum/distortion_investigation/proc/IsFieldUnlocked(field_name)
        // Check if player can see this field
```

**Testing Milestone:**
- Can create investigation datum
- Traits randomize correctly
- Field locking/unlocking works

---

### Phase 2: Clue Items & UI (Evidence System)
**Goal:** Create physical clue items that players can find and examine

**Estimated Time:** 3-4 hours

**Files to Create:**
- `code/modules/distortion_hunting/items/clue_base.dm`
- `code/modules/distortion_hunting/items/clues_another_day.dm`

**Tasks:**

#### 3.2.1 Create Base Clue Item
```dm
/obj/item/clue
    name = "evidence"
    desc = "A piece of evidence related to a distortion investigation."
    icon = 'icons/obj/bureaucracy.dmi'
    icon_state = "paper"

    var/clue_type = "generic"
    var/tier_requirement = 0
    var/list/reveals_fields = list()
    var/datum/distortion_investigation/linked_investigation
    var/description_template = "Generic evidence."
    var/scanned = FALSE

    /obj/item/clue/attack_self(mob/user)
        ui_interact(user)

    /obj/item/clue/ui_interact(mob/user)
        // Create datum/browser popup
        // Show evidence description
        // Show scan status
        // Show revealed fields if scanned

    /obj/item/clue/proc/GenerateDescription()
        // Replace [trait_name] placeholders with actual values
        // Return final description string

    /obj/item/clue/examine(mob/user)
        // Show scan status
        // Prompt to click for details
```

#### 3.2.2 Implement "Another Day at Work" Clues
Create all 7 clue types following the pattern in `EXAMPLE_ANOTHER_DAY_AT_WORK_DATUM.dm`:
- Tier 0: newspaper, briefcase, public_alert
- Tier 1: employee_id, paycheck_stub
- Tier 2: meeting_recording, witness_statement

**Testing Milestone:**
- Spawn clue items in-game
- Click clue to view UI
- Description template replacement works
- Scanned/unscanned states display correctly

---

### Phase 3: Clue Spawning System (World Integration)
**Goal:** Make clues spawn dynamically in the city map

**Estimated Time:** 2-3 hours

**Files to Create:**
- `code/game/objects/effects/landmarks/clue_spawn.dm`

**Tasks:**

#### 3.3.1 Create Clue Spawn Landmarks
```dm
/obj/effect/landmark/clue_spawn
    name = "clue spawn point"
    desc = "A location where investigation clues can spawn."
    icon = 'icons/effects/landmarks_static.dmi'
    icon_state = "x2"

    var/tier_requirement = 0
    var/spawn_weight = 100

    /obj/effect/landmark/clue_spawn/Initialize()
        . = ..()
        GLOB.clue_spawn_landmarks += src

    /obj/effect/landmark/clue_spawn/Destroy()
        GLOB.clue_spawn_landmarks -= src
        return ..()

/obj/effect/landmark/clue_spawn/tier0
    tier_requirement = 0

/obj/effect/landmark/clue_spawn/tier1
    tier_requirement = 1

/obj/effect/landmark/clue_spawn/tier2
    tier_requirement = 2

GLOBAL_LIST_EMPTY(clue_spawn_landmarks)
```

#### 3.3.2 Implement Clue Spawning Logic
```dm
/datum/distortion_investigation/proc/SpawnCluesForTier(tier)
    // Get eligible landmarks for this tier
    // Get eligible clue types for this tier
    // Use spawn weights to pick clue type
    // Spawn clue at random landmark
    // Link clue to this investigation
    // Track spawned clue
```

#### 3.3.3 Map Integration
- Add clue spawn landmarks to city map
- Distribute across different areas
- Test landmark detection

**Testing Milestone:**
- Landmarks appear on map (mappable)
- Global list populates correctly
- Can spawn clues at landmarks
- Tier filtering works

---

### Phase 4: Investigation Scanner Machine (Evidence Processing)
**Goal:** Create machine that scans evidence and unlocks portfolio fields

**Estimated Time:** 3-4 hours

**Files to Create:**
- `code/modules/distortion_hunting/machinery/investigation_scanner.dm`

**Tasks:**

#### 3.4.1 Create Scanner Machine
```dm
/obj/machinery/investigation_scanner
    name = "Investigation Scanner"
    desc = "A machine used to analyze evidence related to distortion investigations."
    icon = 'icons/obj/machines/research.dmi'
    icon_state = "scanner"

    var/obj/item/clue/loaded_clue
    var/scanning = FALSE
    var/scan_time = 3 SECONDS

    /obj/machinery/investigation_scanner/attackby(obj/item/I, mob/user)
        if(istype(I, /obj/item/clue))
            LoadClue(I, user)

    /obj/machinery/investigation_scanner/proc/LoadClue(obj/item/clue/C, mob/user)
        // Check if already scanned
        // Load clue into machine
        // Start scanning process

    /obj/machinery/investigation_scanner/proc/ScanClue()
        // Set clue.scanned = TRUE
        // Unlock fields in investigation datum
        // Calculate payment for user
        // Eject clue
```

#### 3.4.2 Add Payment System
```dm
/datum/distortion_investigation/proc/CalculatePayment(list/newly_unlocked_fields)
    // Base payment per field
    // Bonus for tier completion
    // Return payment amount
```

**Testing Milestone:**
- Can build/spawn scanner machine
- Insert clues into scanner
- Scanning animation/timer works
- Clues marked as scanned
- Fields unlock in investigation datum
- Payment calculated and awarded

---

### Phase 5: Portfolio TGUI Interface (Player Interaction)
**Goal:** Create the portfolio UI where players view and fill investigation data

**Estimated Time:** 4-6 hours

**Files to Create:**
- `code/modules/distortion_hunting/ui/portfolio.dm`
- `tgui/packages/tgui/interfaces/DistortionPortfolio.tsx`

**Tasks:**

#### 3.5.1 Create Portfolio UI Datum (DM Side)
```dm
/datum/distortion_portfolio_ui
    var/datum/distortion_investigation/investigation

    /datum/distortion_portfolio_ui/ui_interact(mob/user, datum/tgui/ui)
        ui = SStgui.try_update_ui(user, src, ui)
        if(!ui)
            ui = new(user, src, "DistortionPortfolio")
            ui.open()

    /datum/distortion_portfolio_ui/ui_data(mob/user)
        var/list/data = list()
        data["distortionName"] = investigation.config.distortion_name
        data["unlockedFields"] = investigation.unlocked_fields
        data["profileData"] = investigation.profile_data
        data["progress"] = investigation.investigation_progress
        return data

    /datum/distortion_portfolio_ui/ui_static_data(mob/user)
        var/list/data = list()
        // All possible fields and their categories
        return data
```

#### 3.5.2 Create TGUI React Interface
```tsx
// tgui/packages/tgui/interfaces/DistortionPortfolio.tsx
import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Section, LabeledList, ProgressBar } from '../components';

export const DistortionPortfolio = (props, context) => {
  const { act, data } = useBackend(context);

  return (
    <Window width={600} height={700}>
      <Window.Content>
        {/* Distortion name header */}
        {/* Progress bar */}
        {/* Personal Information section */}
        {/* Employment section */}
        {/* Location section */}
        {/* Each field shows locked/unlocked state */}
      </Window.Content>
    </Window>
  );
};
```

#### 3.5.3 Portfolio Item/Access Point
```dm
/obj/item/distortion_portfolio
    name = "distortion investigation portfolio"
    desc = "A digital portfolio for tracking distortion investigations."
    icon = 'icons/obj/bureaucracy.dmi'
    icon_state = "portfolio"

    var/datum/distortion_investigation/linked_investigation

    /obj/item/distortion_portfolio/attack_self(mob/user)
        // Open portfolio TGUI
        var/datum/distortion_portfolio_ui/ui = new
        ui.investigation = linked_investigation
        ui.ui_interact(user)
```

**Testing Milestone:**
- Portfolio UI opens and displays
- Shows locked/unlocked fields correctly
- Progress bar updates
- Data from investigation datum displays
- UI responsive and readable

---

### Phase 6: Investigation Flow & Subsystem (Game Loop)
**Goal:** Tie everything together into a working investigation system

**Estimated Time:** 3-4 hours

**Files to Create/Modify:**
- `code/modules/distortion_hunting/distortion_subsystem.dm`
- `code/modules/distortion_hunting/distortion_investigation.dm` (expand)

**Tasks:**

#### 3.6.1 Create Distortion Hunting Subsystem
```dm
SUBSYSTEM_DEF(distortion_hunting)
    name = "Distortion Hunting"
    flags = SS_BACKGROUND
    wait = 5 SECONDS

    var/list/active_investigations = list()
    var/datum/distortion_investigation/current_investigation

    /datum/controller/subsystem/distortion_hunting/Initialize()
        // Load distortion configs
        return ..()

    /datum/controller/subsystem/distortion_hunting/proc/StartNewInvestigation(config_type)
        // Create new investigation
        // Randomize traits
        // Spawn initial tier 0 clues
        // Give portfolios to players
        // Set as current_investigation

    /datum/controller/subsystem/distortion_hunting/proc/CheckTierProgression(datum/distortion_investigation/inv)
        // Check if tier requirements met
        // If so, spawn next tier clues
        // Announce to players
```

#### 3.6.2 Implement Tier Progression Logic
```dm
/datum/distortion_investigation/proc/CheckTierUnlock()
    // Tier 1 requires: home_district, gender, work_district, job_title unlocked
    // Tier 2 requires: first_name, last_name, company_name, age unlocked
    // Return highest unlocked tier

/datum/distortion_investigation/proc/SpawnTierClues(tier)
    // Get clue types for this tier
    // Spawn appropriate number of clues
    // Announce new evidence available
```

#### 3.6.3 Admin Controls
```dm
/datum/admins/proc/StartDistortionInvestigation()
    // Admin verb to start investigation
    // Select distortion type
    // Call subsystem to start

/datum/admins/proc/EndDistortionInvestigation()
    // Clean up investigation
    // Remove clues
    // Reset state
```

**Testing Milestone:**
- Can start investigation via admin panel
- Tier 0 clues spawn automatically
- Scanning clues unlocks fields
- Tier 1 unlocks when requirements met
- Tier 2 unlocks when requirements met
- Full investigation loop works

---

### Phase 7: Polish & Balance (Refinement)
**Goal:** Add quality-of-life features and balance the system

**Estimated Time:** 2-3 hours

**Tasks:**

#### 3.7.1 Sound & Visual Effects
- Add sound effects to scanner
- Visual effect when clue spawns
- Notification when new tier unlocks
- Portfolio field unlock animation

#### 3.7.2 Announcements & Feedback
```dm
/datum/distortion_investigation/proc/AnnounceNewTier(tier)
    priority_announce(
        "New evidence has been located. Tier [tier] clues now available.",
        "Hunter's Guild Investigation Update"
    )

/obj/machinery/investigation_scanner/proc/AnnounceScanComplete(mob/user, payment)
    to_chat(user, span_notice("Analysis complete. [payment] credits transferred."))
    playsound(src, 'sound/machines/terminal_success.ogg', 50, FALSE)
```

#### 3.7.3 Balance Tuning
- Adjust payment amounts per field
- Tune scan times
- Balance clue spawn weights
- Set tier unlock requirements

#### 3.7.4 Error Handling
- Handle investigation datum deletion
- Handle clue deletion while in scanner
- Handle multiple scans of same clue
- Handle edge cases

**Testing Milestone:**
- System feels polished
- Clear feedback to players
- No major bugs or edge cases
- Balanced progression

---

### Phase 8: Content Expansion (Future)
**Goal:** Add more distortions and features

**Tasks:**

#### 3.8.1 Additional Distortions
- Create new distortion configs
- Design unique clue sets
- Write story narratives
- Create themed evidence

#### 3.8.2 Advanced Features
- NPC interview system (from design doc)
- Surveillance mechanics (tape recorders)
- Evidence analysis minigames
- Interactive evidence board

#### 3.8.3 Combat Integration
- Design distortion encounter maps
- Implement bus ticket system
- Create initial combat arenas
- Build "Dungeon of the Fandoms" maps

---

## 4. Testing Strategy

### 4.1 Unit Testing (Per Phase)
- Test each component independently
- Verify data structures store correctly
- Check UI interactions work
- Validate randomization

### 4.2 Integration Testing (After Phase 6)
- Full investigation loop test
- Multiple players testing simultaneously
- Edge case testing (missing clues, etc.)
- Performance testing (memory leaks, etc.)

### 4.3 Playtesting (Phase 7+)
- Player engagement metrics
- Time to complete investigation
- Payment balance feedback
- Story comprehension

---

## 5. Code Style Guidelines

### 5.1 Naming Conventions
- Datums: `/datum/distortion_investigation`
- Items: `/obj/item/clue/another_day/newspaper`
- Machines: `/obj/machinery/investigation_scanner`
- Procs: `UnlockFields()`, `SpawnCluesForTier()`

### 5.2 Documentation
```dm
/// Unlocks investigation fields and updates progress
/// Arguments:
/// * fields - List of field names to unlock
/// * scanner - Optional reference to the scanner machine that triggered unlock
/datum/distortion_investigation/proc/UnlockFields(list/fields, obj/machinery/investigation_scanner/scanner)
```

### 5.3 Signal Usage
```dm
// When field unlocked
SEND_SIGNAL(src, COMSIG_INVESTIGATION_FIELD_UNLOCKED, field_name)

// When tier unlocked
SEND_SIGNAL(src, COMSIG_INVESTIGATION_TIER_UNLOCKED, tier)

// When investigation completed
SEND_SIGNAL(src, COMSIG_INVESTIGATION_COMPLETED)
```

---

## 6. Dependencies & Prerequisites

### 6.1 Required Systems
- TGUI framework (already in LC13)
- Subsystem architecture (already in LC13)
- Datum/browser (for clue UI)
- Landmark system (already in LC13)

### 6.2 Required Assets
- Clue item icons (can reuse existing paper/bureaucracy icons)
- Scanner machine sprite (can reuse existing machine sprites)
- Sound effects (can reuse existing terminal/scanner sounds)

### 6.3 Map Changes
- Add clue spawn landmarks to city map
- Create distortion encounter maps (Phase 8)

---

## 7. Estimated Total Time

| Phase | Description | Time |
|-------|-------------|------|
| Phase 1 | Core Data Structures | 2-3 hours |
| Phase 2 | Clue Items & UI | 3-4 hours |
| Phase 3 | Clue Spawning System | 2-3 hours |
| Phase 4 | Investigation Scanner | 3-4 hours |
| Phase 5 | Portfolio TGUI | 4-6 hours |
| Phase 6 | Investigation Flow | 3-4 hours |
| Phase 7 | Polish & Balance | 2-3 hours |
| **Total MVP** | **Phases 1-7** | **19-27 hours** |
| Phase 8 | Content Expansion | Ongoing |

---

## 8. Success Criteria

### 8.1 MVP Success (Phase 1-7 Complete)
- [ ] Players can find clue items in the city
- [ ] Clues can be scanned at Investigation Scanner
- [ ] Portfolio UI displays investigation progress
- [ ] All 10 traits unlock through 7 clues
- [ ] Tier progression works (0 → 1 → 2)
- [ ] Payment system functional
- [ ] "Another Day at Work" distortion fully playable
- [ ] No major bugs or crashes

### 8.2 Content Success (Phase 8+)
- [ ] At least 3 different distortions implemented
- [ ] Advanced investigation features added
- [ ] Combat encounters integrated
- [ ] Positive player feedback
- [ ] Repeatable content loop established

---

## 9. Known Challenges & Solutions

### 9.1 Challenge: Clue Template Replacement
**Issue:** Need to replace `[trait_name]` with actual values without breaking formatting

**Solution:**
```dm
/obj/item/clue/proc/GenerateDescription()
    if(!linked_investigation)
        return description_template

    var/final_desc = description_template
    for(var/trait_name in linked_investigation.profile_data)
        var/value = linked_investigation.profile_data[trait_name]
        final_desc = replacetext(final_desc, "\[[trait_name]\]", value)

    return final_desc
```

### 9.2 Challenge: Multiple Players, One Investigation
**Issue:** How to handle multiple players investigating same distortion

**Solution:**
- Single shared investigation datum
- Multiple portfolio items link to same investigation
- Progress shared across all players
- Payment split or individual based on contribution tracking

### 9.3 Challenge: Clue Respawning
**Issue:** What if player loses/destroys clue

**Solution:**
- Track spawned clues in investigation datum
- Allow admin respawn command
- Consider time-based respawn for lost clues
- Prevent scanning same clue twice

---

## 10. Future Expansion Ideas

### 10.1 Advanced Investigation
- Timeline reconstruction minigame
- Evidence connection board
- Forensic lab with analysis machines
- Multiple simultaneous investigations

### 10.2 Competitive Elements
- Racing to complete investigations
- Bonus for first completion
- Investigation leaderboard
- Team vs team hunting

### 10.3 Dynamic Content
- Procedurally generated distortions
- Randomized dungeon layouts
- Dynamic clue difficulty scaling
- Seasonal distortion events

---

## Appendix A: Quick Start Checklist

For developers starting implementation:

- [ ] Read DISTORTION_HUNTING_DESIGN.md
- [ ] Read PORTFOLIO_SYSTEM_TECHNICAL.md
- [ ] Review EXAMPLE_ANOTHER_DAY_AT_WORK_DATUM.dm
- [ ] Set up file structure (Section 2)
- [ ] Start with Phase 1 (Core Data Structures)
- [ ] Test each phase before moving to next
- [ ] Reference LC13 existing code for patterns
- [ ] Ask questions in dev channel when stuck

---

## Appendix B: Code References

**Similar existing systems to reference:**
- **Paperwork System**: `/obj/item/paper` for clue UI patterns
- **Research System**: Scanner machines for evidence processing
- **Objectives System**: Datum tracking for investigation progress
- **TGUI Examples**: Body fabricator, PDA, computer UIs

**Key LC13/SS13 patterns:**
- Use `GLOB.` for global lists
- Use `LAZYLEN()` for safe list checking
- Use signals for event communication
- Use subsystems for game loop management
- Follow existing TGUI component patterns
