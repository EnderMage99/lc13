# LC13: Distortion Hunting System Design

---

## 1. Overview

A progression system for City of Light that adds repeatable distortion investigation and combat encounters, providing players with engaging content outside of ruins exploration.

### Problem Statement
- Players lack activities in the city beyond ruins exploration
- Most progression is tied to ruins
- Distortions are underutilized despite being a core setting element
- Need for repeatable, engaging content for city-based gameplay

---

## 2. Core Gameplay Loop

1. **Investigation Phase**: Players discover and collect clues about a distortion spawning in the city
2. **Evidence Gathering**: Interact with NPCs and objects to build a case
3. **Progress Tracking**: Each submitted clue adds a percentage to the distortion location progress (0-100%)
4. **Location Discovery**: When progress reaches 100%, create a bus ticket to the distortion's location (loads new map)
5. **Initial Encounter**: Combat encounter with the distortion
6. **Dungeon Dive**: Distortion opens portal to its "Dungeon of the Fandoms" and escapes
7. **Final Battle**: Traverse 5-6 rooms culminating in final distortion encounter

### Additional Notes
<!-- Add refinements to gameplay loop here -->

---

## 3. Investigation System

### 3.1 Progress Tracking
- Each distortion has a **location progress percentage** (0% to 100%)
- Submitting clues increases the progress percentage
- When progress reaches 100%, players can create a bus ticket to the distortion's location
- Players are paid based on the progress percentage they contribute

**Progress Values by Clue Type:**
- Physical Evidence: X% per item
- NPC Information Papers: Y% per submission
- Tape Recordings: Z% per tape
<!-- Define specific percentage values here -->

### 3.2 Physical Evidence
- Random objects spawn throughout the city relating to specific distortions
  - Example: Shriveled ties for "Another Day at Work" distortion
- Players collect and catalog these items
- Each unique physical evidence item submitted adds progress percentage

**Additional Evidence Types:**
<!-- Add new physical evidence ideas here -->

### 3.3 NPC Interactions
- UI NPCs wander the city map
- Players can show collected clues to NPCs
- NPCs provide information papers when shown relevant evidence
- Information quality varies based on NPC knowledge
- Submitting these papers to the investigation adds progress percentage

**NPC Dialogue System:**
<!-- Add dialogue trees, NPC types, or interaction details here -->

### 3.4 Surveillance Mechanics
- Players can use tape recorders
- Place recorders in NPC meeting rooms
- Recorded conversations reveal distortion information
- Tapes can be submitted as evidence, adding progress percentage

**Additional Surveillance Tools:**
<!-- Add other investigation tools here -->

### 3.5 Investigation Minigames
*Organized by implementation difficulty*

---

#### **EASY DIFFICULTY** - Simple TGUI interfaces and basic data tracking

##### 3.5.1 Basic Portfolio/Dossier System
**Implementation Complexity: LOW**

- Players build a simple dossier tracking discovered information
- Basic TGUI interface with text fields and checkboxes
- Simple data structure tracking collected info

**Technical Requirements:**
- Basic TGUI interface (similar to existing paper/PDA UIs)
- Datum to store portfolio data (name, occupation, notes)
- Simple flag system for completed sections
- No complex logic needed

**Portfolio Sections:**
- Personal Information (text fields)
- Collected Physical Evidence (item list)
- Witness Testimonies (paper-style entries)
- Progress tracker for completed sections

**Why It's Easy:**
- Uses existing TGUI patterns
- Simple data storage (lists and strings)
- No complex interactions or validation
- Can reuse existing UI components

---

##### 3.5.2 Simple NPC Interview System
**Implementation Complexity: LOW**

- Basic dialogue options when examining NPCs with evidence
- NPCs give information papers when shown relevant clues
- Simple flag system for NPC states

**Technical Requirements:**
- Extend existing NPC examine/interact code
- Simple dialogue menu (already exists in BYOND)
- Flag system for "already interviewed" state
- Generate paper items with information

**Mechanics:**
- Right-click NPC → "Show Evidence" option
- Select evidence from inventory
- NPC checks if evidence is relevant
- If relevant, spawns information paper

**Why It's Easy:**
- Uses existing interaction systems
- Papers already exist in codebase
- Simple boolean checks for evidence relevance
- No complex state management

---

#### **MEDIUM DIFFICULTY** - More complex UI and logic systems

##### 3.5.3 Advanced Interview/Interrogation System
**Implementation Complexity: MEDIUM**

- Full dialogue trees with branching options
- NPC rapport/relationship tracking
- Evidence presentation timing matters
- NPCs remember previous interactions

**Technical Requirements:**
- Custom TGUI dialogue interface
- Relationship tracking datum per NPC
- Dialogue tree data structure (JSON or DM lists)
- State machine for conversation flow
- Memory system for past interactions

**Mechanics:**
- Choose dialogue tone (aggressive, empathetic, professional)
- Present evidence at correct moments in conversation
- Rapport affects information quality
- Some NPCs require multiple visits

**Why It's Medium:**
- Requires custom dialogue system
- Complex state tracking (rapport, conversation history)
- Need to author dialogue trees per distortion
- More TGUI work than basic systems

---

##### 3.5.4 Enhanced Portfolio with Auto-Filling
**Implementation Complexity: MEDIUM**

- Portfolio automatically populates fields when evidence is submitted
- Tracks connections between clues
- Highlights gaps in investigation
- Bonus rewards for complete sections

**Technical Requirements:**
- Enhanced TGUI interface with dynamic updates
- Logic system to parse clue types and auto-populate
- Connection tracking between evidence pieces
- Progress calculation for bonus rewards
- Visual indicators for complete/incomplete sections

**Example Flow:**
1. Find shriveled tie → Auto-fills "Occupation: Office Worker"
2. Interview NPC → Auto-adds entry to "Witnesses" section
3. Complete all sections → Bonus progress percentage

**Why It's Medium:**
- Requires evidence categorization system
- More complex TGUI with dynamic updates
- Logic for determining what info each clue provides
- Bonus calculation system

---

##### 3.5.5 Basic Evidence Analysis Minigames
**Implementation Complexity: MEDIUM**

- Simple forensic minigames for analyzing clues
- Fingerprint matching, simple pattern recognition
- Gives bonus progress if completed successfully

**Examples:**
- **Fingerprint Match**: Match fingerprint to database (simple matching game)
- **Document Analysis**: Find highlighted keywords in text
- **Photo Comparison**: Spot differences between images

**Technical Requirements:**
- Individual TGUI interface per minigame type
- Randomization for replayability
- Success/failure state handling
- Reward calculation

**Why It's Medium:**
- Need multiple mini-UI systems
- Requires art assets (fingerprints, photos, etc.)
- Some client-side interaction logic
- Testing for each minigame type

---

#### **HARD DIFFICULTY** - Complex systems with significant development time

##### 3.5.6 Interactive Evidence Board / Connection System
**Implementation Complexity: HIGH**

- Visual cork board showing all clues
- Drag-and-drop to create connections
- Dynamic connection validation
- Reveals hidden clues when correct connections made

**Technical Requirements:**
- Complex TGUI interface with drag-and-drop
- Visual graph/network system
- Connection validation logic
- Dynamic clue revelation system
- Save/load board state
- Potentially canvas-based rendering

**Connection Types:**
- Person-to-Location: Where they were last seen
- Event-to-Event: Timeline reconstruction
- Item-to-Person: Ownership/relationship
- Cause-to-Effect: What triggered the distortion

**Why It's Hard:**
- Complex interactive UI (drag-and-drop in TGUI)
- Graph/network data structure
- Validation logic for "correct" connections
- Visual representation challenges
- Significant TGUI/React work
- High testing overhead

---

##### 3.5.7 Scene Reconstruction Minigame
**Implementation Complexity: HIGH**

- Visit locations and place evidence in correct positions
- Timeline slider showing scene at different times
- 3D/isometric space interaction
- Validation of correct reconstruction

**Technical Requirements:**
- Custom location viewing system
- Placeable evidence interaction (similar to construction)
- Timeline system changing map state
- Validation logic for correct placements
- Potentially separate map instances
- Visual feedback for correct/incorrect placements

**Example:**
- Visit office where distortion occurred
- Place evidence items in correct locations
- Timeline slider shows office at different times
- Reconstruct final moments before distortion

**Why It's Hard:**
- Complex spatial interaction system
- Timeline/map state management
- Requires multiple map states or dynamic turf changes
- Validation logic for "correct" reconstruction
- Significant art/mapping work
- May require instancing technology

---

##### 3.5.8 Full Forensic Lab System
**Implementation Complexity: VERY HIGH**

- Dedicated forensic lab location with equipment
- Multiple analysis types (DNA, fingerprints, chemical, digital)
- Each machine has its own minigame
- Results feed into portfolio automatically

**Technical Requirements:**
- Multiple machine types with unique interactions
- Individual minigame systems per machine type
- Sample collection and storage system
- Database of forensic profiles
- Integration with portfolio system
- Extensive art and sprite work

**Why It's Very Hard:**
- Essentially multiple medium-difficulty systems combined
- Requires new location/room
- Many unique machine interactions
- Multiple minigames to develop
- Large scope for initial implementation
- Better suited as expansion content

---

### 3.5.9 Recommended Implementation Order

**Phase 1 - MVP (Easy Systems):**
1. Basic Portfolio/Dossier System
2. Simple NPC Interview System
3. Basic progress tracking and rewards

**Phase 2 - Enhanced Features (Medium Systems):**
4. Enhanced Portfolio with Auto-Filling
5. Advanced Interview/Interrogation System
6. Basic Evidence Analysis Minigames

**Phase 3 - Advanced Features (Hard Systems):**
7. Interactive Evidence Board (if desired)
8. Scene Reconstruction (optional, high effort)
9. Full Forensic Lab (future expansion)

**Recommendation:** Start with Phase 1 to get a working system, then iterate based on player feedback and development resources.

---

## 4. Progression & Rewards

### 4.1 Payment System
- Players receive payment when submitting distortion information
- Payment scales based on investigation progress contributed
- Incentivizes thorough investigation and clue discovery

**Payment Calculations:**
<!-- Add payment formulas and scaling here -->

---

## 5. Map Structure & Encounters

### 5.1 City Phase (Investigation)
- Investigation takes place in existing city map
- Clues and NPCs spawn dynamically

**Spawn Rules:**
<!-- Add clue/NPC spawn mechanics here -->

### 5.2 Distortion Location (Initial Encounter)
- New map loads when bus ticket is used
- Initial combat arena

**Map Layout:**
<!-- Describe arena design here -->

### 5.3 Dungeon of the Fandoms (Final Encounter)
- Separate map section accessed via portal
- 5-6 rooms to traverse
- Final boss room at the end

**Room Types:**
<!-- Define room varieties and mechanics here -->

**Dungeon Mechanics:**
<!-- Add environmental hazards, puzzles, etc. here -->

---

## 6. Distortion Types & Encounters

### 6.1 Example Distortion: "Another Day at Work"
**Clues:**
- Shriveled ties

**Behavior:**
<!-- Add combat mechanics here -->

**Loot Table:**
<!-- Add drops here -->

### 6.2 Additional Distortions
<!-- Add new distortion designs here -->

---

## 7. Technical Implementation

### 7.1 Code Structure
<!-- Define subsystems, datums, and code organization here -->

### 7.2 Data Structures
<!-- Define distortion configs, clue databases, etc. here -->

### 7.3 UI Components
<!-- Define TGUI interfaces needed here -->

---

## 8. Replayability Features

### 8.1 Randomization Systems
- Randomization of clues and NPC locations
- Variety in distortion types and encounters
- Varied dungeon layouts (potential future enhancement)

**Randomization Details:**
<!-- Add procedural generation rules here -->

### 8.2 Multiple Active Distortions
<!-- Define multi-distortion system here -->

### 8.3 Competitive Elements
<!-- Add competitive investigation mechanics here -->

---

## 9. Open Questions & Design Decisions

### Critical Questions
- How should the investigation minigame work?
- What percentage value should each clue type contribute?
- How should dungeon difficulty scale with player level?
- How frequently should new distortions spawn?
- What rewards should players receive from completing encounters?

### Additional Considerations
<!-- Add new design questions here -->

---

## 10. Development Roadmap

### Phase 1: Core Systems
<!-- Define MVP features here -->

### Phase 2: Content Expansion
<!-- Define content creation phase here -->

### Phase 3: Polish & Balance
<!-- Define refinement phase here -->

---

## Appendix

### A. Reference Materials
<!-- Add lore references, inspiration sources here -->

### B. Changelog
<!-- Track major design changes here -->
