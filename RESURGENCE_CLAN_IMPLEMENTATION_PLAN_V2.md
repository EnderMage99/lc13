# Resurgence Clan Gamemode - Implementation Plan (Revised)

## Overview
This document outlines a phased implementation approach for the Resurgence Clan gamemode. Each phase builds upon the previous one and produces a testable, playable version of the game with increasing complexity.

**Total Estimated Timeline**: 12-16 weeks for full implementation
**Team Size Recommendation**: 2-4 developers

## Phase 1: Core Framework & Basic Systems ✅ (COMPLETED)
**Duration**: 1-2 weeks
**Goal**: Establish the basic gamemode framework with machine players

### Implementation Tasks

#### 1.1 Machine Mob Type
```
Files created:
- /code/modules/mob/living/carbon/human/species_types/resurgence_machine.dm
- /code/modules/surgery/organs/resurgence_core.dm
```
- New species: `/datum/species/resurgence_machine`
- Core organ managing resources
- Basic mechanical traits
- Immunity to biological effects (toxins, diseases)
- Vulnerability to EMPs and electrical damage

#### 1.2 Basic Resource Variables
```
Files created:
- /code/modules/surgery/organs/resurgence_core.dm
```
- Charge variable (0-100, regenerates 1/second)
- Faith variable (0-100, decays slowly)
- Action button to check resource values
- Core organ that manages resources

#### 1.3 Job Definition
```
Files created:
- /code/modules/jobs/job_types/resurgence_clan/machine_civilian.dm
```
- Basic machine civilian job
- Sets species on spawn
- Initializes resources

### Testing Checklist
- [x] Players can join as machines
- [x] Basic movement and interaction works
- [x] Charge regenerates visibly
- [x] Faith decreases visibly
- [x] Resource check action works

### Deliverable
**Minimal Playable**: Players can join as machines with working resource systems that can be tested on any map.

---

## Phase 2: Production Chain Foundation
**Duration**: 2 weeks
**Goal**: Implement the core production loop with scrap processing

### Implementation Tasks

#### 2.1 Scrap Processing Chain
```
Files to create:
- /code/modules/resurgence_clan/production/scrap_processor.dm
- /code/modules/resurgence_clan/production/recycling_furnace.dm
- /code/modules/resurgence_clan/production/component_press.dm
- /code/modules/resurgence_clan/items/materials.dm
```
- Scrap sorting station (manual minigame)
- Recycling furnace (temperature management)
- Component press (timing-based crafting)
- Material items: raw scrap, sorted scrap, metal ingots, components

#### 2.2 Basic Crafting System
```
Files to create:
- /code/modules/resurgence_clan/crafting/crafting_bench.dm
- /code/modules/resurgence_clan/crafting/recipes_basic.dm
```
- Simple crafting bench
- 10-15 basic recipes (tools, simple items)
- Crafting UI using TGUI
- Recipe discovery system

#### 2.3 Energy Generation
```
Files to create:
- /code/modules/resurgence_clan/power/solar_collector.dm
- /code/modules/resurgence_clan/power/battery_bank.dm
- /code/modules/resurgence_clan/power/power_controller.dm
```
- Solar collectors (require cleaning)
- Battery storage system
- Power distribution controller
- Village power grid integration

#### 2.4 Production UI
```
Files to create:
- /tgui/packages/tgui/interfaces/ResurgenceProduction.js
- /tgui/packages/tgui/interfaces/ResurgencePower.js
```
- Production status displays
- Power grid overview
- Resource inventory tracker
- Efficiency meters

### Testing Checklist
- [ ] Scrap can be processed through full chain
- [ ] Each production step requires player interaction
- [ ] Crafting produces correct items
- [ ] Power system affects production speed
- [ ] Multiple players can use different stations simultaneously
- [ ] Production chains work without major bugs
- [ ] UI displays accurate information

### Deliverable
**Basic Production Loop**: Players can process scrap into components and craft basic items while managing power.

---

## Phase 3: Resource Management & Food Systems
**Duration**: 2 weeks
**Goal**: Add faith restoration mechanics and food production

### Implementation Tasks

#### 3.1 Food Production Chain
```
Files to create:
- /code/modules/resurgence_clan/production/nutrient_farm.dm
- /code/modules/resurgence_clan/production/processing_kitchen.dm
- /code/modules/resurgence_clan/production/dining_hall.dm
- /code/modules/resurgence_clan/items/food_items.dm
```
- Nutrient farms with growth cycles
- Kitchen with recipe system
- Communal dining mechanics
- Faith-boosting meal effects

#### 3.2 Faith System Mechanics
```
Files to create:
- /code/modules/resurgence_clan/faith/faith_controller.dm
- /code/modules/resurgence_clan/faith/sermon_system.dm
- /code/modules/resurgence_clan/faith/faith_activities.dm
```
- Faith drain calculations
- Faith restoration activities
- Sermon minigame for Priest role
- Faith effect on player stats

#### 3.3 Charge Ability System
```
Files to create:
- /code/modules/resurgence_clan/abilities/charge_abilities.dm
- /code/modules/resurgence_clan/abilities/ability_controller.dm
```
- Basic charge-based abilities (3-5 to start)
- Ability cooldown system
- Visual effects for ability use
- Charge cost balancing

#### 3.4 Basic Roles
```
Files to create:
- /code/modules/resurgence_clan/jobs/resurgence_jobs.dm
- /code/modules/resurgence_clan/jobs/job_outfits.dm
```
- Priest role (basic implementation)
- Worker roles (generic for now)
- Role selection at round start
- Basic role-specific abilities

### Testing Checklist
- [ ] Food production chain functions end-to-end
- [ ] Meals restore faith when consumed communally
- [ ] Sermons provide faith to attendees
- [ ] Low faith reduces player effectiveness
- [ ] Charge abilities work and consume charge
- [ ] Role selection works at round start
- [ ] 20+ players can engage simultaneously

### Deliverable
**Faith & Sustenance**: Complete resource management with faith restoration through food and sermons.

---

## Phase 4: The Thread System & Social Mechanics
**Duration**: 3 weeks
**Goal**: Implement the Weaver role and thread system

### Implementation Tasks

#### 4.1 Thread System Core
```
Files to create:
- /code/modules/resurgence_clan/threads/thread_controller.dm
- /code/modules/resurgence_clan/threads/thread_datum.dm
- /code/modules/resurgence_clan/threads/thread_calculations.dm
```
- Thread data structure between all players
- Thread strength calculations (0-100)
- Thread change triggers (proximity, activities)
- Production efficiency modifiers from threads

#### 4.2 Weaver Role Implementation
```
Files to create:
- /code/modules/resurgence_clan/jobs/weaver.dm
- /code/modules/resurgence_clan/abilities/weaver_abilities.dm
- /tgui/packages/tgui/interfaces/WeaverLoom.js
```
- Full Weaver role with unique spawn
- Thread visualization UI (Weaver's Loom)
- Weaver abilities:
  - Weaving Ceremony
  - Mend Thread
  - Thread Reading
  - Harmony Decree
- Thread Keeper assistant role

#### 4.3 Thread Effects on Gameplay
```
Files to modify:
- /code/modules/resurgence_clan/production/* (all production files)
```
- Production speed modifiers based on thread strength
- Collaborative bonuses for strong threads
- Penalties for weak threads
- Thread-based work assignments

#### 4.4 Social Activities
```
Files to create:
- /code/modules/resurgence_clan/social/social_activities.dm
- /code/modules/resurgence_clan/social/festivals.dm
- /code/modules/resurgence_clan/social/memory_archive.dm
```
- Shared meal mechanics
- Festival system
- Memory Archive for stories
- Recreational activities

### Testing Checklist
- [ ] Threads form and change based on interactions
- [ ] Weaver can see all threads via UI
- [ ] Weaver abilities affect threads correctly
- [ ] Thread strength affects production efficiency
- [ ] Social activities strengthen threads
- [ ] Conflicts weaken threads appropriately
- [ ] Thread system scales with 20+ players
- [ ] No major performance issues with thread calculations

### Deliverable
**Social Fabric**: Full thread system with Weaver role making relationships mechanically meaningful.

---

## Phase 5: Expedition System
**Duration**: 2 weeks
**Goal**: Add expeditions as supplementary content

### Implementation Tasks

#### 5.1 Expedition Framework
```
Files to create:
- /code/modules/resurgence_clan/expeditions/expedition_controller.dm
- /code/modules/resurgence_clan/expeditions/expedition_sites.dm
- /code/modules/resurgence_clan/expeditions/expedition_scanner.dm
```
- Expedition scanner machine
- Site generation system
- Expedition team formation
- Travel and return mechanics

#### 5.2 Expedition Content
```
Files to create:
- /code/modules/resurgence_clan/expeditions/site_templates/
- /code/modules/resurgence_clan/expeditions/loot_tables.dm
- /code/modules/resurgence_clan/expeditions/expedition_mobs.dm
```
- 5-10 site templates
- Loot generation system
- Hostile creatures (2-3 types)
- Environmental hazards

#### 5.3 Expedition Integration
```
Files to modify:
- /code/modules/resurgence_clan/production/*
```
- Rare materials only from expeditions
- Blueprint discovery system
- Expedition materials feeding production
- Quick deployment/return mechanics

#### 5.4 Limb Upgrade System
```
Files to create:
- /code/modules/resurgence_clan/upgrades/limb_upgrades.dm
- /code/modules/resurgence_clan/upgrades/upgrade_chamber.dm
```
- Craftable limb replacements
- Limb effects on village activities
- Upgrade chamber machine
- Visual limb differences

### Testing Checklist
- [ ] Scanner finds sites after appropriate delay
- [ ] 3-4 players can form expedition team
- [ ] Sites generate with appropriate loot
- [ ] Combat works with charge abilities
- [ ] Materials integrate with production chains
- [ ] Expeditions take 10-15 minutes maximum
- [ ] Village continues functioning during expeditions
- [ ] Limb upgrades provide meaningful benefits

### Deliverable
**Expeditions Online**: Quick expeditions provide materials to jumpstart production.

---

## Phase 6: Village Life & All Roles
**Duration**: 3 weeks
**Goal**: Implement all specialist roles and village activities

### Implementation Tasks

#### 6.1 All Specialist Roles
```
Files to create:
- /code/modules/resurgence_clan/jobs/master_craftsman.dm
- /code/modules/resurgence_clan/jobs/agricultural_overseer.dm
- /code/modules/resurgence_clan/jobs/power_engineer.dm
- /code/modules/resurgence_clan/jobs/infrastructure_specialist.dm
- /code/modules/resurgence_clan/jobs/thread_keeper.dm
```
- Unique abilities for each role
- Role-specific tools and access
- Specialized UI elements
- Role progression systems

#### 6.2 Village Infrastructure
```
Files to create:
- /code/modules/resurgence_clan/buildings/personal_quarters.dm
- /code/modules/resurgence_clan/buildings/theater.dm
- /code/modules/resurgence_clan/buildings/library.dm
- /code/modules/resurgence_clan/buildings/recreation_center.dm
```
- Personal room customization
- Theater performance system
- Library research mechanics
- Recreation minigames

#### 6.3 Advanced Production
```
Files to create:
- /code/modules/resurgence_clan/production/experimental_lab.dm
- /code/modules/resurgence_clan/production/advanced_manufacturing.dm
- /code/modules/resurgence_clan/crafting/recipes_advanced.dm
```
- Complex multi-step recipes
- Experimental crafting with failure chances
- Quality tiers for crafted items
- Innovation system for new recipes

#### 6.4 Skill Progression
```
Files to create:
- /code/modules/resurgence_clan/skills/skill_controller.dm
- /code/modules/resurgence_clan/skills/skill_types.dm
```
- Production skill improvements
- Social skill development
- Leadership skill unlocks
- Skill-based crafting bonuses

### Testing Checklist
- [ ] All roles have unique gameplay
- [ ] Personal quarters can be customized
- [ ] Theater performances affect morale
- [ ] Library research unlocks improvements
- [ ] Advanced crafting creates superior items
- [ ] Skills improve through use
- [ ] Village feels alive with 20+ players
- [ ] No role feels useless or overpowered

### Deliverable
**Full Village Simulation**: All roles and village systems functioning together.

---

## Phase 7: Village Map & Full Integration
**Duration**: 3 weeks
**Goal**: Create the complete village map with all systems integrated

### Implementation Tasks

#### 7.1 Complete Village Map
```
Files to create:
- /maps/resurgence_village/resurgence_village.dmm
- /maps/resurgence_village/areas.dm
- /_maps/resurgence_village.json
```
- Central plaza (75x75 minimum)
- Production facilities placement:
  - Scrap processing area
  - Manufacturing zone
  - Energy generation district
  - Food production sector
- Social areas:
  - Central chapel
  - Theater
  - Library
  - Recreation center
  - Memory archive
- Infrastructure:
  - Personal quarters area
  - Storage facilities
  - Defensive walls
  - Workshop complexes
- Expedition zones:
  - Scanner station
  - Deployment area
  - Return processing

#### 7.2 Map Integration
```
Files to modify:
- All production machine files
- All social activity files
```
- Place all machines in appropriate locations
- Set up production chains spatially
- Configure spawn points for all roles
- Establish restricted areas
- Create logical workflow paths

#### 7.3 Environmental Details
```
Files to create:
- /code/modules/resurgence_clan/map/environmental_objects.dm
```
- Decorative elements
- Lore items and logs
- Environmental storytelling
- Atmospheric effects
- Lighting setup

#### 7.4 Map Systems
```
Files to create:
- /code/modules/resurgence_clan/map/power_grid.dm
- /code/modules/resurgence_clan/map/ventilation.dm
```
- Village-wide power distribution
- Ventilation and atmosphere
- Area-specific mechanics
- Emergency systems

### Testing Checklist
- [ ] All areas accessible and functional
- [ ] Production chains work with map layout
- [ ] Social spaces support activities
- [ ] Spawn points work correctly
- [ ] Map performs well with 20+ players
- [ ] Atmosphere and lighting correct
- [ ] All systems integrated properly

### Deliverable
**Complete Village**: Fully realized map with all systems integrated and working together.

---

## Phase 8: Events, Crises & Victory Conditions
**Duration**: 2 weeks
**Goal**: Add dynamic events and win conditions

### Implementation Tasks

#### 8.1 Crisis Events
```
Files to create:
- /code/modules/resurgence_clan/events/event_controller.dm
- /code/modules/resurgence_clan/events/production_crises.dm
- /code/modules/resurgence_clan/events/social_crises.dm
- /code/modules/resurgence_clan/events/infrastructure_crises.dm
```
- Production breakdown events
- Social conflict events
- Infrastructure emergencies
- Event frequency and scaling

#### 8.2 External Encounters
```
Files to create:
- /code/modules/resurgence_clan/events/trader_encounters.dm
- /code/modules/resurgence_clan/events/refugee_events.dm
- /code/modules/resurgence_clan/events/tinkerer_messages.dm
```
- Trader arrival system
- Refugee integration decisions
- Tinkerer interference events
- Diplomatic encounters

#### 8.3 Victory Conditions
```
Files to create:
- /code/modules/resurgence_clan/victory/victory_controller.dm
- /code/modules/resurgence_clan/victory/victory_types.dm
```
- Survival victory (time-based)
- Prosperity victory (resource-based)
- Faith victory (morale-based)
- Victory announcement and stats

#### 8.4 Monument System
```
Files to create:
- /code/modules/resurgence_clan/buildings/monument.dm
- /code/modules/resurgence_clan/buildings/monument_stages.dm
```
- Collaborative monument construction
- Stage-based progression
- Village-wide bonuses per stage
- Final monument completion effects

### Testing Checklist
- [ ] Events trigger at appropriate intervals
- [ ] Crises require collaborative solutions
- [ ] External encounters create meaningful choices
- [ ] Victory conditions are achievable but challenging
- [ ] Monument provides long-term goal
- [ ] Events scale with village progress
- [ ] Multiple paths to victory exist

### Deliverable
**Dynamic Gameplay**: Events and victory conditions create narrative arc within the village.

---

## Phase 9: Polish, Balance & Optimization
**Duration**: 3 weeks
**Goal**: Final polish, balancing, and performance optimization

### Implementation Tasks

#### 9.1 Visual Polish
```
Files to modify:
- /icons/mob/resurgence_machines.dmi
- /icons/obj/resurgence_structures.dmi
- /sound/resurgence_clan/
```
- Unique sprites for all machines
- Structure animations
- Sound effects for production
- Atmospheric music
- Visual effects for abilities

#### 9.2 Balance Pass
- Resource generation rates
- Faith drain rates
- Thread change rates
- Production times
- Expedition rewards
- Crisis difficulty
- Ability cooldowns
- Victory condition requirements

#### 9.3 Performance Optimization
- Thread calculation optimization
- Production chain efficiency
- UI responsiveness
- Network traffic reduction
- Memory usage optimization
- Database query optimization

#### 9.4 Quality of Life
```
Files to create:
- /code/modules/resurgence_clan/helpers/
- /code/modules/resurgence_clan/admin/
```
- Admin tools for testing
- Automated helper functions
- Tutorial system for new players
- Quick reference guides
- Hotkey optimizations
- UI improvements based on testing

### Testing Checklist
- [ ] 30+ players can play without lag
- [ ] All systems feel balanced
- [ ] Visual/audio adds to immersion
- [ ] New players can learn quickly
- [ ] Admin tools work properly
- [ ] No memory leaks over 3-hour sessions
- [ ] Edge cases handled gracefully

### Deliverable
**Release Candidate**: Polished, balanced gamemode ready for live servers.

---

## Testing Strategy

### Phase Testing
Each phase should undergo:
1. **Developer Testing**: Core functionality works
2. **Small Group Testing**: 5-10 players for basic mechanics
3. **Stress Testing**: 20-30 players for performance
4. **Balance Testing**: Full sessions for gameplay flow

### Integration Testing
After Phase 4, conduct full integration tests:
- All systems working together
- No conflicts between features
- Performance under full load
- Save/load functionality

### Community Testing
Phases 6-9 should include:
- Public test server deployment
- Community feedback collection
- Balance adjustments based on data
- Bug report tracking

---

## Technical Considerations

### Database Schema
```sql
CREATE TABLE resurgence_threads (
    id INTEGER PRIMARY KEY,
    player1_ckey TEXT,
    player2_ckey TEXT,
    strength INTEGER,
    last_updated TIMESTAMP
);

CREATE TABLE resurgence_skills (
    ckey TEXT PRIMARY KEY,
    production_skill INTEGER,
    social_skill INTEGER,
    leadership_skill INTEGER
);
```

### Performance Targets
- Thread calculations: <50ms per tick
- Production updates: <100ms per operation
- UI refresh rate: 10 FPS minimum
- Network traffic: <10KB/s per player average

### Subsystem Priority
```
SSresurgence_threads: PRIORITY_HIGH (process every tick)
SSresurgence_production: PRIORITY_NORMAL (process every 2 seconds)
SSresurgence_faith: PRIORITY_LOW (process every 10 seconds)
SSresurgence_events: PRIORITY_LOW (process every 30 seconds)
```

---

## Risk Mitigation

### Technical Risks
- **Thread system performance**: Pre-calculate and cache when possible
- **Network congestion**: Batch updates, use deltas
- **Database bottlenecks**: Use in-memory caching
- **UI complexity**: Progressive disclosure, role-specific views

### Design Risks
- **Player engagement**: Constant activity streams, no downtime
- **Learning curve**: Tutorial, mentorship system
- **Grief potential**: Thread system discourages antisocial behavior
- **Balance issues**: Extensive playtesting, easy config adjustments

---

## Resource Requirements

### Development Team
- **Core Developer** (1): Systems and mechanics
- **UI Developer** (1): TGUI interfaces
- **Map Designer** (1): Village and expedition sites
- **Balance Designer** (1): Testing and tuning

### Assets Needed
- Machine sprites (20+ variations)
- Structure sprites (30+ buildings/machines)
- UI mockups and designs
- Sound effects (50+ samples)
- Music tracks (3-5 ambient)

---

## Success Metrics

### Phase Metrics
- Phase completion on schedule
- Testing checklist completion
- Bug count below threshold
- Performance targets met

### Gameplay Metrics
- Average session length >90 minutes
- Player retention >80% per round
- Victory achievement rate 30-40%
- Positive feedback >75%

### Technical Metrics
- Server stability >99% uptime
- Client FPS >30 average
- Memory usage <2GB
- Load time <2 minutes

---

## Conclusion

This revised implementation plan provides a more logical progression where all systems are developed and tested before the time-intensive map creation phase. The map in Phase 7 can then be perfectly tailored to accommodate all the systems developed in Phases 1-6, and the events in Phase 8 can be designed specifically for the completed village layout.

The key advantage is that development isn't blocked by map creation, and all systems can be tested on existing maps throughout development, ensuring they work properly before integration into the final village.